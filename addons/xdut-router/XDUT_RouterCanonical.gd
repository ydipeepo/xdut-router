extends Node

#-------------------------------------------------------------------------------
#	SIGNALS
#-------------------------------------------------------------------------------

signal navigate

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func get_navigation_verbose() -> bool:
	return _navigation_verbose

func get_current_path() -> String:
	var navigation := _get_current_navigation()
	return XDUT_RouteHelper.join_path_segments(navigation.path_segments)

func save_event_batch(route_event_batch_etag: int) -> void:
	assert(_route_event_batch_map.has(route_event_batch_etag))

	_route_event_batch_etag_stack.push_back(route_event_batch_etag)

func restore_event_batch() -> void:
	assert(not _route_event_batch_etag_stack.is_empty())

	_route_event_batch_etag_stack.pop_back()

func cleanup_event_batch(route_event_batch_etag: int) -> void:
	assert(
		_route_event_batch_map.has(route_event_batch_etag) and
		not _route_event_batch_etag_stack.has(route_event_batch_etag))

	_route_event_batch_map.erase(route_event_batch_etag)

func register(
	route_node: Node,
	route_segment: String,
	flags := 0) -> Awaitable:

	assert(not XDUT_RouteHelper.has_route_wrapper(route_node))
	assert(route_node.is_inside_tree())

	var temporary := not _route_event_batch_etag_stack.is_empty()

	var route_segments: PackedStringArray
	var affiliated_route_node := XDUT_RouteHelper.find_affiliated_route_node(route_node)
	if affiliated_route_node != null:
		route_segments = XDUT_RouteHelper.resolve_route_segments(affiliated_route_node)
	route_segments.push_back(route_segment)

	var navigation := _get_current_navigation()
	var route_event_batch := \
		_get_event_batch() \
		if temporary else \
		_create_event_batch()

	_add_route_node(
		route_segments,
		route_node,
		route_event_batch,
		navigation.path_segments)

	var dispatcher: Awaitable = null
	if not temporary:
		var path := XDUT_RouteHelper.join_path_segments(navigation.path_segments)
		dispatcher = _create_dispatcher(route_event_batch, path, false)
	return dispatcher

func unregister(
	route_node: Node,
	flags := 0) -> Awaitable:

	assert(XDUT_RouteHelper.has_route_wrapper(route_node))

	var temporary := not _route_event_batch_etag_stack.is_empty()

	var navigation := _get_current_navigation()
	var route_segments := XDUT_RouteHelper.resolve_route_segments(route_node)
	var route_event_batch := \
		_get_event_batch() \
		if temporary else \
		_create_event_batch()

	_remove_route_node(
		route_segments,
		route_node,
		route_event_batch)

	var dispatcher: Awaitable = null
	if not temporary:
		var path := XDUT_RouteHelper.join_path_segments(navigation.path_segments)
		dispatcher = _create_dispatcher(route_event_batch, path, false)
	return dispatcher

func goto(
	path: String,
	base_node: Node,
	flags: int) -> Awaitable:

	var last_navigation := _get_current_navigation()

	var path_segments: PackedStringArray
	if base_node != null:
		var route_node := XDUT_RouteHelper.find_affiliated_route_node(base_node)
		var resolved_path_segments := XDUT_RouteHelper.resolve_path_segments(route_node)
		if resolved_path_segments == null:
			printerr("'path' is invalid: ", path)
			return Task.canceled()
		path_segments = resolved_path_segments
	else:
		path_segments = last_navigation.path_segments

	var next_navigation_path_segments := XDUT_RouteHelper.parse_path(
		path,
		path_segments)
	if next_navigation_path_segments == null:
		printerr("'path' is invalid: ", path)
		return Task.canceled()
	if next_navigation_path_segments == last_navigation.path_segments:
		return Task.completed(path)

	var next_navigation := {
		"path_segments": next_navigation_path_segments,
		"exclusive": flags & _FLAG_EXCLUSIVE != 0,
	}
	_navigation_stack.push_back(next_navigation)
	return _test_path_and_create_dispatcher(next_navigation, "goto")

func replace(
	path: String,
	base_node: Node,
	flags: int) -> Awaitable:

	if _navigation_stack.is_empty():
		printerr("Navigation stack is empty.")
		return Task.canceled()

	var last_navigation := _get_current_navigation()

	var path_segments: PackedStringArray
	if base_node != null:
		var route_node := XDUT_RouteHelper.find_affiliated_route_node(base_node)
		var resolved_path_segments := XDUT_RouteHelper.resolve_path_segments(route_node)
		if path_segments == null:
			printerr("'path' is invalid: ", path)
			return Task.canceled()
		path_segments = resolved_path_segments
	else:
		path_segments = last_navigation.path_segments

	var next_navigation_path_segments := XDUT_RouteHelper.parse_path(
		path,
		path_segments)
	if next_navigation_path_segments == null:
		printerr("'path' is invalid: ", path)
		return Task.canceled()
	if next_navigation_path_segments == last_navigation.path_segments:
		return Task.completed(path)

	var next_navigation := {
		"path_segments": next_navigation_path_segments,
		"exclusive": last_navigation.exclusive or flags & _FLAG_EXCLUSIVE != 0,
	}
	_navigation_stack[_navigation_stack.size() - 1] = next_navigation
	return _test_path_and_create_dispatcher(next_navigation, "replace")

func reload(flags: int) -> Awaitable:
	if _navigation_stack.is_empty():
		return Task.canceled()

	var next_navigation := _get_current_navigation()
	next_navigation.exclusive = next_navigation.exclusive or flags & _FLAG_EXCLUSIVE != 0
	return _test_path_and_create_dispatcher(next_navigation, "reload")

func can_back() -> bool:
	return 1 < _navigation_stack.size()

func back(flags: int) -> Awaitable:
	if not can_back():
		printerr("Navigation stack is empty.")
		return Task.canceled()

	var next_navigation := _get_current_navigation()
	_navigation_stack.pop_back()
	next_navigation.path_segments = _get_current_navigation().path_segments
	next_navigation.exclusive = next_navigation.exclusive or flags & _FLAG_EXCLUSIVE != 0
	return _test_path_and_create_dispatcher(next_navigation, "back")

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

var _route_event_batch_map: Dictionary[int, XDUT_RouteEventBatch] = {}
var _route_event_batch_etag_stack: Array[int] = []
var _route_event_batch_etag := 0

func _get_current_navigation() -> Dictionary:
	assert(not _navigation_stack.is_empty())
	return _navigation_stack.back()

func _create_dispatcher(
	route_event_batch: XDUT_RouteEventBatch,
	path: String,
	exclusive: bool) -> Awaitable:

	return \
		XDUT_RouteExclusiveDispatcher.new(self, route_event_batch, path) \
		if exclusive else \
		XDUT_RouteSimultaneousDispatcher.new(self, route_event_batch, path)

func _create_event_batch() -> XDUT_RouteEventBatch:
	var etag := _route_event_batch_etag
	_route_event_batch_etag += 1

	var route_event_batch := XDUT_RouteEventBatch.new(etag)
	_route_event_batch_map[etag] = route_event_batch
	return route_event_batch

func _get_event_batch() -> XDUT_RouteEventBatch:
	assert(not _route_event_batch_etag_stack.is_empty())
	return _route_event_batch_map[_route_event_batch_etag_stack.back()]

func _add_route_node(
	route_segments: PackedStringArray,
	route_node: Node,
	route_event_batch: XDUT_RouteEventBatch,
	path_segments: PackedStringArray) -> void:

	assert(not route_segments.is_empty())
	assert(route_node != null)

	for route_matcher: XDUT_RouteMatcher in get_children():
		if route_matcher.add_route(
			route_segments,
			route_node,
			route_event_batch,
			path_segments):

			return

	var route_matcher := XDUT_RouteMatcher.new(
		route_segments,
		path_segments)
	add_child(route_matcher)
	route_matcher.add_route(
		route_segments,
		route_node,
		route_event_batch,
		path_segments)

func _remove_route_node(
	route_segments: PackedStringArray,
	route_node: Node,
	route_event_batch: XDUT_RouteEventBatch) -> void:

	assert(not route_segments.is_empty())
	assert(route_node != null)

	for route_matcher: XDUT_RouteMatcher in get_children():
		if route_matcher.remove_route(
			route_segments,
			route_node,
			route_event_batch):

			break

func _test_path(
	route_event_batch: XDUT_RouteEventBatch,
	path_segments: PackedStringArray) -> void:

	if path_segments.is_empty():
		for route_matcher: XDUT_RouteMatcher in get_children():
			route_matcher.test_path_for_exit(route_event_batch)
	else:
		for route_matcher: XDUT_RouteMatcher in get_children():
			route_matcher.test_path(route_event_batch, path_segments)

func _test_path_and_create_dispatcher(
	navigation: Dictionary,
	navigation_type: String) -> Awaitable:

	var path := XDUT_RouteHelper.join_path_segments(navigation.path_segments)
	if get_navigation_verbose():
		print("Route changing: ", path, " (", navigation_type, ")")

	var route_event_batch := _create_event_batch()
	_test_path(route_event_batch, navigation.path_segments)
	var dispatcher := _create_dispatcher(
		route_event_batch,
		path,
		navigation.exclusive)
	navigate.emit()
	return dispatcher

func _enter_tree() -> void:
	_navigation_verbose = ProjectSettings.get_setting("xdut/router/navigation/verbose", true)
