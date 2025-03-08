extends Node

#-------------------------------------------------------------------------------
#	SIGNALS
#-------------------------------------------------------------------------------

signal navigate

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func cleanup_group(group_etag: int) -> void:
	assert(group_etag in _group_map)
	assert(not group_etag in _group_etag_stack)

	_group_map.erase(group_etag)

func save_group(group_etag: int) -> void:
	_group_etag_stack.push_back(group_etag)

func restore_group() -> void:
	assert(not _group_etag_stack.is_empty())

	_group_etag_stack.pop_back()

func get_navigation_verbose() -> bool:
	return _navigation_verbose

func get_current_path() -> String:
	return XDUT_RouteHelper.to_path(_get_current_navigation().path_segments)

func register(
	route: Node,
	route_segment: String,
	flags := 0) -> Awaitable:

	var temporary := not _group_etag_stack.is_empty()

	XDUT_RouteHelper.set_route(route, route_segment)
	var route_segments := XDUT_RouteHelper.get_route_segments(route)
	var navigation := _get_current_navigation()
	var path := XDUT_RouteHelper.to_path(navigation.path_segments)

	var group := _get_group() if temporary else _create_group()
	_add_route(navigation.path_segments, route_segments, route, group)
	return null if temporary else _create_completion(path, group, false)

func unregister(
	route: Node,
	flags := 0) -> Awaitable:

	if not XDUT_RouteHelper.is_route(route):
		printerr("'", route, "' is not valid route.")
		return Task.canceled()

	var temporary := not _group_etag_stack.is_empty()

	var route_segments := XDUT_RouteHelper.get_route_segments(route)
	var navigation := _get_current_navigation()
	var path := XDUT_RouteHelper.to_path(navigation.path_segments)
	
	var group := _get_group() if temporary else _create_group()
	_remove_route(route_segments, route, group)
	return null if temporary else _create_completion(path, group, false)

func goto(
	path: String,
	flags := 0) -> Awaitable:

	var last_navigation := _get_current_navigation()
	var next_navigation_path_segments := XDUT_RouteHelper.parse_path(path, last_navigation.path_segments)
	if next_navigation_path_segments == null:
		printerr("'path' is invalid: ", path)
	if next_navigation_path_segments == last_navigation.path_segments:
		return Task.completed(path)

	var next_navigation := {
		"path_segments": next_navigation_path_segments,
		"exclusive": flags & _FLAG_EXCLUSIVE != 0,
	}
	_navigation_stack.push_back(next_navigation)
	return _test_path_and_create_completion(next_navigation, "goto")

func replace(
	path: String,
	flags := 0) -> Awaitable:

	if _navigation_stack.is_empty():
		printerr("Navigation stack is empty.")
		return Task.canceled()

	var last_navigation := _get_current_navigation()
	var next_navigation_path_segments := XDUT_RouteHelper.parse_path(path, last_navigation.path_segments)
	if next_navigation_path_segments == null:
		printerr("'path' is invalid: ", path)
	if next_navigation_path_segments == last_navigation.path_segments:
		return Task.completed(path)

	var next_navigation := {
		"path_segments": next_navigation_path_segments,
		"exclusive": last_navigation.exclusive or flags & _FLAG_EXCLUSIVE != 0,
	}
	_navigation_stack[_navigation_stack.size() - 1] = next_navigation
	return _test_path_and_create_completion(next_navigation, "replace")

func reload(flags := 0) -> Awaitable:
	if _navigation_stack.is_empty():
		return Task.canceled()

	var next_navigation := _get_current_navigation()
	next_navigation.exclusive = next_navigation.exclusive or flags & _FLAG_EXCLUSIVE != 0
	return _test_path_and_create_completion(next_navigation, "reload")

func can_back() -> bool:
	return 1 < _navigation_stack.size()

func back(flags := 0) -> Awaitable:
	if not can_back():
		printerr("Navigation stack is empty.")
		return Task.canceled()

	var next_navigation := _get_current_navigation()
	_navigation_stack.pop_back()
	next_navigation.path_segments = _get_current_navigation().path_segments
	next_navigation.exclusive = next_navigation.exclusive or flags & _FLAG_EXCLUSIVE != 0
	return _test_path_and_create_completion(next_navigation, "back")

#-------------------------------------------------------------------------------

enum {
	_FLAG_EXCLUSIVE = 0x01,
}

var _navigation_verbose: bool
var _navigation_stack: Array[Dictionary] = [
	{
		"path_segments": PackedStringArray(),
		"exclusive": false,
	},
]
var _next_group_etag := 0
var _group_etag_stack: Array[int] = []
var _group_map := {}

func _get_current_navigation() -> Dictionary:
	assert(not _navigation_stack.is_empty())
	return _navigation_stack.back()

func _create_completion(
	path: String,
	group: XDUT_RouteInvocationGroup,
	exclusive: bool) -> Awaitable:

	return \
		XDUT_ExclusiveRouteCompletion.new(self, path, group) \
		if exclusive else \
		XDUT_SimultaneousRouteCompletion.new(self, path, group)

func _create_group() -> XDUT_RouteInvocationGroup:
	var group_etag := _next_group_etag
	_next_group_etag += 1
	var group := XDUT_RouteInvocationGroup.new(group_etag)
	_group_map[group_etag] = group
	return group

func _get_group() -> XDUT_RouteInvocationGroup:
	assert(not _group_etag_stack.is_empty())
	return _group_map[_group_etag_stack.back()]

func _add_route(
	path_segments: PackedStringArray,
	route_segments: PackedStringArray,
	route: Node,
	group: XDUT_RouteInvocationGroup) -> void:

	assert(not route_segments.is_empty())
	assert(route != null)

	for matcher: XDUT_RouteMatcher in get_children():
		if matcher.add_route(
			path_segments,
			route_segments,
			route,
			group):

			return

	var matcher := XDUT_RouteMatcher.new(
		path_segments,
		route_segments)
	add_child(matcher)
	matcher.add_route(
		path_segments,
		route_segments,
		route,
		group)

func _remove_route(
	route_segments: PackedStringArray,
	route: Node,
	group: XDUT_RouteInvocationGroup) -> void:

	assert(not route_segments.is_empty())
	assert(route != null)

	for matcher: XDUT_RouteMatcher in get_children():
		if matcher.remove_route(
			route_segments,
			route,
			group):

			break

func _test_path(
	path_segments: PackedStringArray,
	group: XDUT_RouteInvocationGroup) -> void:

	if path_segments.is_empty():
		for matcher: XDUT_RouteMatcher in get_children():
			matcher.test_path_for_exit(group)
	else:
		for matcher: XDUT_RouteMatcher in get_children():
			matcher.test_path(path_segments, group)

func _test_path_and_create_completion(
	navigation: Dictionary,
	navigation_type: String) -> Awaitable:

	var path := XDUT_RouteHelper.to_path(navigation.path_segments)
	if get_navigation_verbose():
		print("Route changing: ", path, " (", navigation_type, ")")

	var group := _create_group()
	_test_path(navigation.path_segments, group)
	var completion := _create_completion(path, group, navigation.exclusive)
	navigate.emit()
	return completion

func _enter_tree() -> void:
	_navigation_verbose = ProjectSettings.get_setting("xdut/router/navigation/verbose", true)
