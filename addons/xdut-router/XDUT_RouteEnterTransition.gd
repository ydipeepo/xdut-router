class_name XDUT_RouteEnterTransition extends XDUT_RouteTransition

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

var _last_route_transition: XDUT_RouteTransition
var _route_node: Node
var _route_params: Dictionary
var _route_invocation_group_etag: int
var _force: bool
var _cancel := Cancel.create()
var _state_task: Task

func _init(
	last_route_transition: XDUT_RouteTransition,
	route_node: Node,
	route_params: Dictionary,
	route_invocation_group: XDUT_RouteInvocationGroup,
	force: bool) -> void:

	route_invocation_group.append_pre_enter_path([self, _call_pre_enter_path.get_method()])
	route_invocation_group.append_enter_path([self, _call_enter_path.get_method()])

	_route_node = route_node
	_route_params = route_params
	_route_invocation_group_etag = route_invocation_group.group_etag
	_force = force
	_last_route_transition = last_route_transition
	_state_task = Task.from_signal(_set_state, 1)

func _call_pre_enter_path() -> void:
	var last_state := await _last_route_transition.get_state()
	
	if _cancel.is_requested:
		_set_state.emit(STATE_PRE_ENTERING)
		return

	match last_state:
		#STATE_EXITING, \
		#STATE_EXITED, \
		#STATE_POST_EXITING, \
		STATE_POST_EXITED:
			if is_instance_valid(_route_node) and XDUT_RouteHelper.has_pre_enter_path(_route_node):
				var pre_enter_path := XDUT_RouteHelper.get_pre_enter_path(
					_route_node,
					_route_params,
					_route_invocation_group_etag)
				await pre_enter_path.call()

	if _cancel.is_requested:
		_set_state.emit(STATE_PRE_ENTERED)
		return

func _call_enter_path() -> void:
	var last_state := await _last_route_transition.get_state()

	if _cancel.is_requested:
		_set_state.emit(STATE_ENTERING)
		return

	match [last_state, _force]:
		# パターンマッチによる再進入
		[STATE_ENTERING, true], \
		[STATE_ENTERED, true], \
		# 他
		#[STATE_EXITING, _], \
		[STATE_EXITED, _], \
		[STATE_POST_EXITING, _], \
		[STATE_POST_EXITED, _]:
			if is_instance_valid(_route_node) and XDUT_RouteHelper.has_enter_path(_route_node):
				var enter_path := XDUT_RouteHelper.get_enter_path(
					_route_node,
					_route_params,
					_cancel)
				await enter_path.call()

	_set_state.emit(STATE_ENTERED)
