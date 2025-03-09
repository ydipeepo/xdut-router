class_name XDUT_RouteHelper

#-------------------------------------------------------------------------------
#	CONSTANTS
#-------------------------------------------------------------------------------

const ROUTE_SEGMENT_META_KEY := &"__XDUT_ROUTE_SEGMENT"

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

static func to_path(path_segments: PackedStringArray) -> String:
	var path := "/"
	if not path_segments.is_empty():
		path += "/".join(path_segments)
	return path

static func is_route_node(node: Node) -> bool:
	return \
		node != null and \
		node.has_meta(ROUTE_SEGMENT_META_KEY)

static func get_route_node(node: Node) -> Node:
	while node != null:
		if is_route_node(node):
			return node
		node = node.get_parent()
	return null

static func get_route_segments(node: Node) -> PackedStringArray:
	var route_segments: Array[String] = []
	while node != null:
		if is_route_node(node):
			route_segments.push_back(node.get_meta(ROUTE_SEGMENT_META_KEY))
		node = node.get_parent()
	route_segments.reverse()
	return route_segments

static func get_route(node: Node) -> String:
	return "/" + "/".join(get_route_segments(node))

static func set_route(
	node: Node,
	route_segment: String) -> void:

	node.set_meta(ROUTE_SEGMENT_META_KEY, route_segment)

static func parse_path(
	path: String,
	path_segments: PackedStringArray) -> Variant:

	if path.is_empty():
		return null

	var p := path.find("/")
	var q := 0
	var path_segment := path.substr(q, -1 if p == -1 else p - q)

	match path_segment:
		"":
			path_segments = PackedStringArray()
		".":
			path_segments = path_segments.duplicate()
		"..":
			path_segments = path_segments.duplicate()
			if path_segments.is_empty():
				return null
			path_segments.resize(path_segments.size() - 1)
		_:
			return null

	while p != -1:
		q = p + 1
		p = path.find("/", q)
		path_segment = path.substr(q, -1 if p == -1 else p - q)

		match path_segment:
			"..":
				if path_segments.is_empty():
					return null
				path_segments.resize(path_segments.size() - 1)
			_:
				if not _is_valid_path_segment(path_segment):
					return null
				path_segments.push_back(path_segment)

	return path_segments

static func parse_route_segment(route_segment: String) -> RegEx:
	if route_segment.is_empty():
		printerr("Invalid route segment: Empty route segment")
		return null

	var labels: Array[String] = []
	var pattern := "^"

	var state := 0
	var p := 0
	var q := 0
	while p < route_segment.length():
		var c := route_segment[p]
		match c:
			&":":
				#
				# ラベル開始
				#
				
				if state != 0:
					printerr("Invalid route segment: Bad label or label expression pair '", route_segment, "' (", state, ")")
					return null

				q = p + 1
				state = 1

			&"(":
				#
				# ラベル式開始
				#
				
				if state != 1:
					printerr("Invalid route segment: Bad label or label expression pair '", route_segment, "' (", state, ")")
					return null

				var label := route_segment.substr(q, p - q)
				if label.is_empty():
					printerr("Invalid route segment: Empty label '", route_segment, "'")
					return null
				if not _is_valid_route_segment_label(label):
					printerr("Invalid route segment: Bad label char '", route_segment, "'")
					return null
				if labels.has(label):
					printerr("Invalid route segment: Duplicated label '", route_segment, "'")
					return null
				labels.push_back(label)
				pattern += "(?<" + label + ">"

				q = p + 1
				state = 2

			&")":
				#
				# ラベル式終了
				#
				
				if state != 2:
					printerr("Invalid route segment: Bad label or label expression pair '", route_segment, "' (", state, ")")
					return null

				var label_expr := route_segment.substr(q, p - q)
				if label_expr.is_empty():
					printerr("Invalid route segment: Empty label expression '", route_segment, "'")
					return null
				if not _is_valid_route_segment_label_expr(label_expr):
					printerr("Invalid route segment: Bad label expression char '", route_segment, "'")
					return null
				pattern += label_expr + ")"

				q = p + 1
				state = 3

			&"-":
				if state == 2:
					printerr("Invalid route segment: Bad label or label expression pair '", route_segment, "' (", state, ")")
					return null

				if state == 1:
					var label := route_segment.substr(q, p - q)
					if label.is_empty():
						printerr("Invalid route segment: Empty label '", route_segment, "'")
						return null
					if not _is_valid_route_segment_label(label):
						printerr("Invalid route segment: Bad label char '", route_segment, "'")
						return null
					pattern += "(?<" + label + ">\\w+)"
					labels.push_back(label)

				q = p + 1
				state = 0

		if state == 0:
			if not _is_valid_route_segment(c):
				printerr("Invalid route segment: Bad segment char '", route_segment, "'")
				return null
			pattern += c

		p += 1

	if state == 2:
		printerr("Invalid route segment: Bad label or label expression pair '", route_segment, "' (", state, ")")
		return null

	if state == 1:
		var label := route_segment.substr(q, p - q)
		if label.is_empty():
			printerr("Invalid route segment: Empty label '", route_segment, "'")
			return null
		if not _is_valid_route_segment_label(label):
			printerr("Invalid route segment: Bad label char '", route_segment, "'")
			return null
		if labels.has(label):
			printerr("Invalid route segment: Duplicated label '", route_segment, "'")
			return null
		pattern += "(?<" + label + ">\\w+)"
		labels.push_back(label)

	pattern += "$"

	var re := RegEx.new()
	if re.compile(pattern) != OK:
		printerr("Invalid route segment: Compilation failed '", route_segment, "'")
		return null

	return re

static func extract_pre_enter_call(
	route: Node,
	route_params: Dictionary,
	etag: int,
	calls: Array[Callable]) -> void:

	if route.has_method(_PRE_ENTER_PATH_METHOD_NAME):
		match route.get_method_argument_count(_PRE_ENTER_PATH_METHOD_NAME):
			0: calls.push_back(route._pre_enter_path)
			1: calls.push_back(route._pre_enter_path.bind(route_params))
			2: calls.push_back(route._pre_enter_path.bind(route_params, etag))
			_: printerr("Invalid method '", _PRE_ENTER_PATH_METHOD_NAME, "' signature at: ", route)

static func extract_enter_call(
	route: Node,
	route_params: Dictionary,
	calls: Array[Callable]) -> void:

	if route.has_method(_ENTER_PATH_METHOD_NAME):
		match route.get_method_argument_count(_ENTER_PATH_METHOD_NAME):
			0: calls.push_back(route._enter_path)
			1: calls.push_back(route._enter_path.bind(route_params))
			_: printerr("Invalid method '", _ENTER_PATH_METHOD_NAME, "' signature at: ", route)

static func extract_exit_call(
	route: Node,
	calls: Array[Callable]) -> void:

	if route.has_method(_EXIT_PATH_METHOD_NAME):
		match route.get_method_argument_count(_EXIT_PATH_METHOD_NAME):
			0: calls.push_back(route._exit_path)
			_: printerr("Invalid method '", _EXIT_PATH_METHOD_NAME, "' signature at: ", route)

static func extract_post_exit_call(
	route: Node,
	etag: int,
	calls: Array[Callable]) -> void:

	if route.has_method(_POST_EXIT_PATH_METHOD_NAME):
		match route.get_method_argument_count(_POST_EXIT_PATH_METHOD_NAME):
			0: calls.push_back(route._post_exit_path)
			1: calls.push_back(route._post_exit_path.bind(etag))
			_: printerr("Invalid method '", _POST_EXIT_PATH_METHOD_NAME, "' signature at: ", route)

static func wait_animate_and_child_enter_calls(
	route: Node,
	route_params: Dictionary,
	notify_children: bool) -> void:

	var calls: Array[Callable] = []

	if "animations" in route:
		for animation: RouteAnimationBase in route.animations:
			if animation != null:
				calls.push_back(animation.animate_enter.bind(route))

	if notify_children:
		for child_node: Node in route.get_children():
			_extract_child_enter_calls(child_node, route_params, calls)

	await Task.wait_all(calls)

static func wait_animate_and_child_exit_calls(
	route: Node,
	notify_children: bool) -> void:

	var calls: Array[Callable] = []

	if notify_children:
		for child_index: int in range(route.get_child_count() - 1, -1, -1):
			var child_node := route.get_child(child_index)
			_extract_child_exit_calls(child_node, calls)

	if "animations" in route:
		for animation: RouteAnimationBase in route.animations:
			if animation != null:
				calls.push_back(animation.animate_exit.bind(route))

	await Task.wait_all(calls)

#-------------------------------------------------------------------------------

const _PRE_ENTER_PATH_METHOD_NAME := &"_pre_enter_path"
const _ENTER_PATH_METHOD_NAME := &"_enter_path"
const _EXIT_PATH_METHOD_NAME := &"_exit_path"
const _POST_EXIT_PATH_METHOD_NAME := &"_post_exit_path"

const _VALID_PATH_SEGMENT_CHARS: PackedStringArray = [
	"-",
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
	"_",
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
]
const _VALID_ROUTE_SEGMENT_CHARS: PackedStringArray = [
	"-",
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
	"_",
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
]
const _VALID_ROUTE_SEGMENT_LABEL_CHARS: PackedStringArray = [
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
	"_",
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
]

static func _is_valid_path_segment(s: String) -> bool:
	if s.is_empty():
		return false
	for c: String in s:
		if not _VALID_PATH_SEGMENT_CHARS.has(c):
			return false
	return true

static func _is_valid_route_segment(s: String) -> bool:
	if s.is_empty():
		return false
	for c: String in s:
		if not _VALID_ROUTE_SEGMENT_CHARS.has(c):
			return false
	return true

static func _is_valid_route_segment_label(s: String) -> bool:
	if s.is_empty():
		return false
	for c: String in s:
		if not _VALID_ROUTE_SEGMENT_LABEL_CHARS.has(c):
			return false
	return true

static func _is_valid_route_segment_label_expr(s: String) -> bool:
	return not s.is_empty()

static func _extract_child_enter_calls(
	node: Node,
	route_params: Dictionary,
	calls: Array[Callable]) -> void:

	if not is_route_node(node):
		extract_enter_call(node, route_params, calls)
		for child_node: Node in node.get_children():
			_extract_child_enter_calls(child_node, route_params, calls)

static func _extract_child_exit_calls(
	node: Node,
	calls: Array[Callable]) -> void:

	if not is_route_node(node):
		for child_index: int in range(node.get_child_count() - 1, -1, -1):
			var child_node := node.get_child(child_index)
			_extract_child_exit_calls(child_node, calls)
		extract_exit_call(node, calls)
