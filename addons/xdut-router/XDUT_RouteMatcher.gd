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

var path_segment: String:
	get:
		return _path_segment

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func add_route(
	route_segments: PackedStringArray,
	route_node: Node,
	route_event_batch: XDUT_RouteEventBatch,
	path_segments: PackedStringArray,
	depth := 0) -> bool:

	assert(0 <= depth)

	if depth < route_segments.size():
		var route_segment := route_segments[depth]
		if _route_segment == route_segment:
			if depth == route_segments.size() - 1:
				var route_wrapper := XDUT_RouteWrapper.new(self, route_node)
				route_wrapper.mark_node()
				if _is_inside_path:
					route_wrapper.enter(route_event_batch, route_params, false)
				_route_wrappers.push_back(route_wrapper)

			else:
				var matched := false
				for matcher: XDUT_RouteMatcher in get_children():
					if matcher.add_route(
						route_segments,
						route_node,
						route_event_batch,
						path_segments,
						depth + 1):

						matched = true
						break

				if not matched:
					var matcher := new(
						route_segments,
						path_segments,
						depth + 1)
					add_child(matcher)
					matcher.add_route(
						route_segments,
						route_node,
						route_event_batch,
						path_segments,
						depth + 1)

			_route_added += 1
			return true

	return false

func remove_route(
	route_segments: PackedStringArray,
	route_node: Node,
	route_event_batch: XDUT_RouteEventBatch,
	depth := 0) -> bool:

	assert(0 <= depth)

	if depth < route_segments.size():
		var route_segment := route_segments[depth]
		if _route_segment == route_segment:
			if depth == route_segments.size() - 1:
				for route_wrapper_index: int in range(_route_wrappers.size() - 1, -1, -1):
					var route_wrapper := _route_wrappers[route_wrapper_index]
					if route_wrapper.route_node == route_node:
						if _is_inside_path:
							route_wrapper.exit(route_event_batch)
						_route_wrappers.remove_at(route_wrapper_index)
						_route_added -= 1
						route_wrapper.unmark_node()
						break

			else:
				for matcher: XDUT_RouteMatcher in get_children():
					if matcher.remove_route(
						route_segments,
						route_node,
						route_event_batch,
						depth + 1):

						_route_added -= 1
						break

			if _route_added == 0:
				get_parent().remove_child(self)
				queue_free()
			return true

	return false

func test_path_for_exit(route_event_batch: XDUT_RouteEventBatch) -> void:
	if _is_inside_path:
		_is_inside_path = false
		_route_params.clear()
		_path_segment = ""

		for index: int in range(get_child_count() - 1, -1, -1):
			var matcher: XDUT_RouteMatcher = get_child(index)
			matcher.test_path_for_exit(route_event_batch)

		for route_wrapper_index: int in range(_route_wrappers.size() - 1, -1, -1):
			var route_wrapper := _route_wrappers[route_wrapper_index]
			route_wrapper.exit(route_event_batch)

func test_path(
	route_event_batch: XDUT_RouteEventBatch,
	path_segments: PackedStringArray,
	depth := 0) -> void:

	assert(not path_segments.is_empty())
	assert(0 <= depth)

	if depth < path_segments.size():
		var segment_match := _compiled_route_segment.search(path_segments[depth])
		if segment_match != null:
			var is_reentry := _is_inside_path
			_is_inside_path = true
			_path_segment = path_segments[depth]

			if _set_or_update_route_params(segment_match, is_reentry):
				for route_wrapper: XDUT_RouteWrapper in _route_wrappers:
					route_wrapper.enter(
						route_event_batch,
						_route_params,
						is_reentry)

			for matcher: XDUT_RouteMatcher in get_children():
				matcher.test_path(
					route_event_batch,
					path_segments,
					depth + 1)
			return

	test_path_for_exit(route_event_batch)

#-------------------------------------------------------------------------------

static var _canonical: Node

var _is_inside_path: bool
var _compiled_route_segment: RegEx
var _route_segment: String
var _route_params: Dictionary
var _route_wrappers: Array[XDUT_RouteWrapper]
var _route_added: int
var _path_segment: String

static func _get_canonical() -> Node:
	if not is_instance_valid(_canonical):
		_canonical = Engine \
			.get_main_loop() \
			.root \
			.get_node("/root/XDUT_RouterCanonical")
	return _canonical

func _set_or_update_route_params(
	segment_match: RegExMatch,
	is_reentry: bool) -> bool:

	assert(segment_match != null)

	#
	# NOTE:
	# ルートセグメントの一致よりルートパラメタを設定もしくは更新します。
	# 設定もしくは更新された場合は true を返します。
	#

	var parent := get_parent()
	var new_route_params: Dictionary = \
		parent.route_params.duplicate() \
		if parent is XDUT_RouteMatcher else \
		{}
	for key: String in segment_match.names:
		new_route_params[key] = segment_match.get_string(key)

	var route_params_changed := true
	if is_reentry:
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
	route_segments: PackedStringArray,
	path_segments: PackedStringArray,
	depth := 0) -> void:

	var route_segment := route_segments[depth]
	var compiled_route_segment: RegEx = XDUT_RouteHelper.parse_route_segment(route_segment)
	assert(compiled_route_segment != null)

	_compiled_route_segment = compiled_route_segment
	_route_segment = route_segment

	if depth < path_segments.size():
		var segment_match := compiled_route_segment.search(path_segments[depth])
		if segment_match != null:
			_set_or_update_route_params(segment_match, false)
			_is_inside_path = true
			_path_segment = path_segments[depth]

	name = route_segment
