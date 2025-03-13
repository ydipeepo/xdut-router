class_name XDUT_RouteMatcher extends Node

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

var is_inside_path: bool:
	get:
		return _is_inside_path

var route_params: Dictionary:
	get:
		return _route_params

var route_segment: String:
	get:
		return _route_segment

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func add_route(
	path_segments: PackedStringArray,
	route_segments: PackedStringArray,
	route_node: Node,
	group: XDUT_RouteInvocationGroup,
	depth := 0) -> bool:

	assert(0 <= depth)

	if depth < route_segments.size():
		var route_segment := route_segments[depth]
		if _route_segment == route_segment:
			if depth == route_segments.size() - 1:
				var route_wrapper := XDUT_RouteWrapper.new(route_node)
				if _is_inside_path:
					group.append_pre_enter_and_enter_path(route_wrapper, route_params)
				_route_wrapper_array.push_back(route_wrapper)

			else:
				var matched := false
				for matcher: XDUT_RouteMatcher in get_children():
					if matcher.add_route(
						path_segments,
						route_segments,
						route_node,
						group,
						depth + 1):

						matched = true
						break

				if not matched:
					var matcher := new(
						path_segments,
						route_segments,
						depth + 1)
					add_child(matcher)
					matcher.add_route(
						path_segments,
						route_segments,
						route_node,
						group,
						depth + 1)

			_route_added += 1
			return true

	return false

func remove_route(
	route_segments: PackedStringArray,
	route_node: Node,
	group: XDUT_RouteInvocationGroup,
	depth := 0) -> bool:

	assert(0 <= depth)

	if depth < route_segments.size():
		var route_segment := route_segments[depth]
		if _route_segment == route_segment:
			if depth == route_segments.size() - 1:
				for route_wrapper_index: int in range(_route_wrapper_array.size() - 1, -1, -1):
					var route_wrapper := _route_wrapper_array[route_wrapper_index]
					if route_wrapper.route_node == route_node:
						if _is_inside_path:
							group.append_exit_and_post_exit_path(route_wrapper)
						_route_wrapper_array.remove_at(route_wrapper_index)
						_route_added -= 1
						break

			else:
				for matcher: XDUT_RouteMatcher in get_children():
					if matcher.remove_route(
						route_segments,
						route_node,
						group,
						depth + 1):

						_route_added -= 1
						break

			if _route_added == 0:
				get_parent().remove_child(self)
				queue_free()
			return true

	return false

func test_path_for_exit(group: XDUT_RouteInvocationGroup) -> void:
	if _is_inside_path:
		_is_inside_path = false
		route_params.clear()

		for index: int in range(get_child_count() - 1, -1, -1):
			var matcher: XDUT_RouteMatcher = get_child(index)
			matcher.test_path_for_exit(group)

		group.append_exit_and_post_exit_path_array(_route_wrapper_array)

func test_path(
	path_segments: PackedStringArray,
	group: XDUT_RouteInvocationGroup,
	depth := 0) -> void:

	assert(not path_segments.is_empty())
	assert(0 <= depth)

	if depth < path_segments.size():
		var segment_match := _compiled_route_segment.search(path_segments[depth])
		if segment_match != null:
			if _set_or_update_route_params(segment_match):
				group.append_pre_enter_and_enter_path_array(_route_wrapper_array, route_params)

			_is_inside_path = true

			for matcher: XDUT_RouteMatcher in get_children():
				matcher.test_path(
					path_segments,
					group,
					depth + 1)
			return

	test_path_for_exit(group)

#-------------------------------------------------------------------------------

static var _canonical: Node

var _is_inside_path: bool
var _compiled_route_segment: RegEx
var _route_segment: String
var _route_params: Dictionary
var _route_wrapper_array: Array[XDUT_RouteWrapper]
var _route_added: int

static func _get_canonical() -> Node:
	if not is_instance_valid(_canonical):
		_canonical = Engine \
			.get_main_loop() \
			.root \
			.get_node("/root/XDUT_RouterCanonical")
	return _canonical

func _get_parent_route_params() -> Dictionary:
	var parent := get_parent()
	return \
		parent.route_params.duplicate() \
		if parent is XDUT_RouteMatcher else \
		{}

func _set_or_update_route_params(segment_match: RegExMatch) -> bool:
	assert(segment_match != null)

	#
	# NOTE:
	# ルートセグメントの一致よりルートパラメタを設定もしくは更新します。
	# 設定もしくは更新された場合は true を返します。
	#

	var new_route_params := _get_parent_route_params()
	for key: String in segment_match.names:
		new_route_params[key] = segment_match.get_string(key)

	var route_params_changed := true
	if _is_inside_path:
		var new_route_params_keys := new_route_params.keys()
		if _route_params.has_all(new_route_params_keys) and new_route_params.has_all(_route_params.keys()):
			route_params_changed = false
			for key: String in new_route_params_keys:
				if _route_params[key] != new_route_params[key]:
					route_params_changed = true
					break

	if route_params_changed:
		_route_params = new_route_params
		return true

	return false

func _init(
	path_segments: PackedStringArray,
	route_segments: PackedStringArray,
	depth := 0) -> void:

	var route_segment := route_segments[depth]
	var compiled_route_segment: RegEx = XDUT_RouteHelper.parse_route_segment(route_segment)
	assert(compiled_route_segment != null)

	_compiled_route_segment = compiled_route_segment
	_route_segment = route_segment

	if depth < path_segments.size():
		var segment_match := compiled_route_segment.search(path_segments[depth])
		if segment_match != null:
			_set_or_update_route_params(segment_match)
			_is_inside_path = true

	name = route_segment
