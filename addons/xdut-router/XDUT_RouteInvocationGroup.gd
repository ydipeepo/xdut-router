class_name XDUT_RouteInvocationGroup

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

var etag: int:
	get:
		return _etag

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func collect_enter_call(
	route: Node,
	route_params: Dictionary) -> void:

	XDUT_RouteHelper.extract_pre_enter_call(route, route_params, _etag, _pre_enter_calls)
	XDUT_RouteHelper.extract_enter_call(route, route_params, _enter_calls)

func collect_enter_call_array(
	route_array: Array[Node],
	route_params: Dictionary) -> void:
		
	for route: Node in route_array:
		collect_enter_call(route, route_params)

func collect_exit_call(route: Node) -> void:
	XDUT_RouteHelper.extract_exit_call(route, _exit_calls)
	XDUT_RouteHelper.extract_post_exit_call(route, _etag, _post_exit_calls)

func collect_exit_call_array(route_array: Array[Node]) -> void:
	for route_index: int in range(route_array.size() - 1, -1, -1):
		var route := route_array[route_index]
		collect_exit_call(route)

func get_pre_enter_calls(calls: Array[Callable]) -> void:
	calls.append_array(_pre_enter_calls); _pre_enter_calls.clear()

func get_enter_calls(calls: Array[Callable]) -> void:
	calls.append_array(_enter_calls); _enter_calls.clear()

func get_exit_calls(calls: Array[Callable]) -> void:
	calls.append_array(_exit_calls); _exit_calls.clear()

func get_post_exit_calls(calls: Array[Callable]) -> void:
	calls.append_array(_post_exit_calls); _post_exit_calls.clear()

#-------------------------------------------------------------------------------

var _etag: int
var _pre_enter_calls: Array[Callable]
var _enter_calls: Array[Callable]
var _exit_calls: Array[Callable]
var _post_exit_calls: Array[Callable]

func _init(etag: int) -> void:
	_etag = etag
