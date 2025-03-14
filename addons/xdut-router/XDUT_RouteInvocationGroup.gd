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

func append_pre_enter_path(call: Callable) -> void:
	_pre_enter_path_calls.push_back(call)

func append_enter_path(call: Callable) -> void:
	_enter_path_calls.push_back(call)

func append_exit_path(call: Callable) -> void:
	_exit_path_calls.push_back(call)

func append_post_exit_path(call: Callable) -> void:
	_post_exit_path_calls.push_back(call)

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
