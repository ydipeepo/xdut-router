class_name XDUT_RouteInvocationGroup

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

var group_etag: int:
	get:
		return _group_etag

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func append_pre_enter_and_enter_path(
	route_wrapper: XDUT_RouteWrapper,
	route_params: Dictionary) -> void:

	route_wrapper.bundle_pre_enter_path(route_params, _group_etag, _pre_enter_path_calls)
	route_wrapper.bundle_enter_path(route_params, _enter_path_calls)

func append_pre_enter_and_enter_path_array(
	route_wrappers: Array[XDUT_RouteWrapper],
	route_params: Dictionary) -> void:

	for route_wrapper: XDUT_RouteWrapper in route_wrappers:
		append_pre_enter_and_enter_path(route_wrapper, route_params)

func append_exit_and_post_exit_path(route_wrapper: XDUT_RouteWrapper) -> void:
	route_wrapper.bundle_exit_path(_exit_path_calls)
	route_wrapper.bundle_post_exit_path(_group_etag, _post_exit_path_calls)

func append_exit_and_post_exit_path_array(route_wrappers: Array[XDUT_RouteWrapper]) -> void:
	for route_wrapper_index: int in range(route_wrappers.size() - 1, -1, -1):
		var route_wrapper := route_wrappers[route_wrapper_index]
		append_exit_and_post_exit_path(route_wrapper)

func bundle_pre_enter_path(calls: Array[Callable]) -> void:
	calls.append_array(_pre_enter_path_calls); _pre_enter_path_calls.clear()

func bundle_enter_path(calls: Array[Callable]) -> void:
	calls.append_array(_enter_path_calls); _enter_path_calls.clear()

func bundle_exit_path(calls: Array[Callable]) -> void:
	calls.append_array(_exit_path_calls); _exit_path_calls.clear()

func bundle_post_exit_path(calls: Array[Callable]) -> void:
	calls.append_array(_post_exit_path_calls); _post_exit_path_calls.clear()

#-------------------------------------------------------------------------------

var _group_etag: int
var _pre_enter_path_calls: Array[Callable]
var _enter_path_calls: Array[Callable]
var _exit_path_calls: Array[Callable]
var _post_exit_path_calls: Array[Callable]

func _init(group_etag: int) -> void:
	_group_etag = group_etag
