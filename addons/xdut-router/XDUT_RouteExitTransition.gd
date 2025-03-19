class_name XDUT_RouteExitTransition extends XDUT_RouteTransition

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func get_state() -> int:
	var state_array := await _state_task.wait()
	return state_array[0]

func cancel() -> void:
	_cancel.request()

#-------------------------------------------------------------------------------

signal _set_state(state: int)

var _last_transition: XDUT_RouteTransition
var _route_node: Node
var _route_params: Dictionary
var _route_invocation_group_etag: int
var _cancel := Cancel.create()
var _state_task: Task

func _init(
	last_transition: XDUT_RouteTransition,
	route_node: Node,
	route_invocation_group: XDUT_RouteInvocationGroup) -> void:

	route_invocation_group.append_exit_path([self, _call_exit_path.get_method()])
	route_invocation_group.append_post_exit_path([self, _call_post_exit_path.get_method()])

	_route_node = route_node
	_route_invocation_group_etag = route_invocation_group.group_etag
	_last_transition = last_transition
	_state_task = Task.from_signal(_set_state, 1)

func _call_exit_path() -> void:
	var last_state := await _last_transition.get_state()

	if _cancel.is_requested:
		_set_state.emit(STATE_EXITING)
		return

	match last_state:
		#STATE_PRE_ENTERING, \
		#STATE_PRE_ENTERED, \
		STATE_ENTERING, \
		STATE_ENTERED:
			if is_instance_valid(_route_node) and XDUT_RouteHelper.has_exit_path(_route_node):
				var exit_path := XDUT_RouteHelper.get_exit_path(
					_route_node,
					_cancel)
				await exit_path.call()

	if _cancel.is_requested:
		_set_state.emit(STATE_EXITED)
		return

func _call_post_exit_path() -> void:
	var last_state := await _last_transition.get_state()

	if _cancel.is_requested:
		_set_state.emit(STATE_POST_EXITING)
		return

	match last_state:
		#STATE_PRE_ENTER, \
		STATE_PRE_ENTERED, \
		STATE_ENTERING, \
		STATE_ENTERED:
			if is_instance_valid(_route_node) and XDUT_RouteHelper.has_post_exit_path(_route_node):
				var post_exit_path := XDUT_RouteHelper.get_post_exit_path(
					_route_node,
					_route_invocation_group_etag)
				await post_exit_path.call()

	_set_state.emit(STATE_POST_EXITED)
