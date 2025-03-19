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

static func has_pre_enter_path(route_node: Node) -> bool:
	if route_node.has_method(_PRE_ENTER_PATH_METHOD_NAME):
		match route_node.get_method_argument_count(_PRE_ENTER_PATH_METHOD_NAME):
			0, \
			1, \
			2: return true
	return false

static func has_enter_path(route_node: Node) -> bool:
	if route_node.has_method(_ENTER_PATH_METHOD_NAME):
		match route_node.get_method_argument_count(_ENTER_PATH_METHOD_NAME):
			0, \
			1, \
			2: return true
	return false

static func has_exit_path(route_node: Node) -> bool:
	if route_node.has_method(_EXIT_PATH_METHOD_NAME):
		match route_node.get_method_argument_count(_EXIT_PATH_METHOD_NAME):
			0, \
			1: return true
	return false

static func has_post_exit_path(route_node: Node) -> bool:
	if route_node.has_method(_POST_EXIT_PATH_METHOD_NAME):
		match route_node.get_method_argument_count(_POST_EXIT_PATH_METHOD_NAME):
			0, \
			1: return true
	return false

static func get_pre_enter_path(
	route_node: Node,
	route_params: Dictionary,
	group_etag: int) -> Callable:

	if route_node.has_method(_PRE_ENTER_PATH_METHOD_NAME):
		match route_node.get_method_argument_count(_PRE_ENTER_PATH_METHOD_NAME):
			0: return route_node._pre_enter_path
			1: return route_node._pre_enter_path.bind(route_params)
			2: return route_node._pre_enter_path.bind(route_params, group_etag)
		printerr("Invalid '", _PRE_ENTER_PATH_METHOD_NAME, "' method signature at: ", route_node)
	return Callable()

static func get_enter_path(
	route_node: Node,
	route_params: Dictionary,
	route_cancel: Cancel) -> Callable:

	if route_node.has_method(_ENTER_PATH_METHOD_NAME):
		match route_node.get_method_argument_count(_ENTER_PATH_METHOD_NAME):
			0: return route_node._enter_path
			1: return route_node._enter_path.bind(route_params)
			2: return route_node._enter_path.bind(route_params, route_cancel)
		printerr("Invalid '", _ENTER_PATH_METHOD_NAME, "' method signature at: ", route_node)
	return Callable()

static func get_exit_path(
	route_node: Node,
	route_cancel: Cancel) -> Callable:

	if route_node.has_method(_EXIT_PATH_METHOD_NAME):
		match route_node.get_method_argument_count(_EXIT_PATH_METHOD_NAME):
			0: return route_node._exit_path
			1: return route_node._exit_path.bind(route_cancel)
		printerr("Invalid '", _EXIT_PATH_METHOD_NAME, "' method signature at: ", route_node)
	return Callable()

static func get_post_exit_path(
	route_node: Node,
	group_etag: int) -> Callable:

	if route_node.has_method(_POST_EXIT_PATH_METHOD_NAME):
		match route_node.get_method_argument_count(_POST_EXIT_PATH_METHOD_NAME):
			0: return route_node._post_exit_path
			1: return route_node._post_exit_path.bind(group_etag)
		printerr("Invalid '", _POST_EXIT_PATH_METHOD_NAME, "' method signature at: ", route_node)
	return Callable()

static func get_pre_enter_path_init(
	route_node: Node,
	route_params: Dictionary,
	group_etag: int) -> Array:

	if route_node.has_method(_PRE_ENTER_PATH_METHOD_NAME):
		match route_node.get_method_argument_count(_PRE_ENTER_PATH_METHOD_NAME):
			0: return [route_node, _PRE_ENTER_PATH_METHOD_NAME]
			1: return [route_node, _PRE_ENTER_PATH_METHOD_NAME, [route_params]]
			2: return [route_node, _PRE_ENTER_PATH_METHOD_NAME, [route_params, group_etag]]
		printerr("Invalid '", _PRE_ENTER_PATH_METHOD_NAME, "' method signature at: ", route_node)
	return []

static func get_enter_path_init(
	route_node: Node,
	route_params: Dictionary,
	route_cancel: Cancel) -> Array:

	if route_node.has_method(_ENTER_PATH_METHOD_NAME):
		match route_node.get_method_argument_count(_ENTER_PATH_METHOD_NAME):
			0: return [route_node, _ENTER_PATH_METHOD_NAME]
			1: return [route_node, _ENTER_PATH_METHOD_NAME, [route_params]]
			2: return [route_node, _ENTER_PATH_METHOD_NAME, [route_params, route_cancel]]
		printerr("Invalid '", _ENTER_PATH_METHOD_NAME, "' method signature at: ", route_node)
	return []

static func get_exit_path_init(
	route_node: Node,
	route_cancel: Cancel) -> Array:

	if route_node.has_method(_EXIT_PATH_METHOD_NAME):
		match route_node.get_method_argument_count(_EXIT_PATH_METHOD_NAME):
			0: return [route_node, _EXIT_PATH_METHOD_NAME]
			1: return [route_node, _EXIT_PATH_METHOD_NAME, [route_cancel]]
		printerr("Invalid '", _EXIT_PATH_METHOD_NAME, "' method signature at: ", route_node)
	return []

static func get_post_exit_path_init(
	route_node: Node,
	group_etag: int) -> Array:

	if route_node.has_method(_POST_EXIT_PATH_METHOD_NAME):
		match route_node.get_method_argument_count(_POST_EXIT_PATH_METHOD_NAME):
			0: return [route_node, _POST_EXIT_PATH_METHOD_NAME]
			1: return [route_node, _POST_EXIT_PATH_METHOD_NAME, [group_etag]]
		printerr("Invalid '", _POST_EXIT_PATH_METHOD_NAME, "' method signature at: ", route_node)
	return []

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
