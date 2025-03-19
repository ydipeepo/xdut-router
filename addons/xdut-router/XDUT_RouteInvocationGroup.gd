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

func append_pre_enter_path(init: Variant) -> void:
	_pre_enter_path_calls.push_back(init)

func append_enter_path(init: Variant) -> void:
	_enter_path_calls.push_back(init)

func append_exit_path(init: Variant) -> void:
	_exit_path_calls.push_back(init)

func append_post_exit_path(init: Variant) -> void:
	_post_exit_path_calls.push_back(init)

func bundle_pre_enter_path(calls: Array) -> void:
	calls.append_array(_pre_enter_path_calls); _pre_enter_path_calls.clear()

func bundle_enter_path(calls: Array) -> void:
	calls.append_array(_enter_path_calls); _enter_path_calls.clear()

func bundle_exit_path(calls: Array) -> void:
	calls.append_array(_exit_path_calls); _exit_path_calls.clear()

func bundle_post_exit_path(calls: Array) -> void:
	calls.append_array(_post_exit_path_calls); _post_exit_path_calls.clear()

#-------------------------------------------------------------------------------

var _group_etag: int
var _pre_enter_path_calls: Array
var _enter_path_calls: Array
var _exit_path_calls: Array
var _post_exit_path_calls: Array

func _init(group_etag: int) -> void:
	_group_etag = group_etag
