class_name XDUT_RouteEnterEventTransaction extends XDUT_RouteTransaction

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func get_state() -> int:
	var state_array := await _state_task.wait()
	return state_array[0]

func abort() -> void:
	_abort.request()

#-------------------------------------------------------------------------------

signal _set_state(state: int)

var _route_transaction: XDUT_RouteTransaction
var _route_event_batch: XDUT_RouteEventBatch
var _route_node: Node
var _route_params: Dictionary
var _is_reentry: bool
var _abort := Cancel.create()
var _state_task: Task

func _init(
	route_transaction: XDUT_RouteTransaction,
	route_event_batch: XDUT_RouteEventBatch,
	route_node: Node,
	route_params: Dictionary,
	is_reentry: bool) -> void:

	_route_transaction = route_transaction
	_route_event_batch = route_event_batch
	_route_node = route_node
	_route_params = route_params
	_is_reentry = is_reentry
	_state_task = Task.from_signal(_set_state, 1)

	route_event_batch.append_pre_enter_path([self, _call_pre_enter_path.get_method()])
	route_event_batch.append_enter_path([self, _call_enter_path.get_method()])

func _call_pre_enter_path() -> void:
	var state := await _route_transaction.get_state()
	
	if _abort.is_requested:
		_set_state.emit(STATE_PRE_ENTERING)
		return

	match state:
		#STATE_EXITING, \
		#STATE_EXITED, \
		#STATE_POST_EXITING, \
		STATE_POST_EXITED:
			if is_instance_valid(_route_node) and XDUT_RouteHelper.has_pre_enter_path(_route_node):
				await XDUT_RouteHelper.call_pre_enter_path(
					_route_node,
					_route_params,
					_route_event_batch.etag)

	if _abort.is_requested:
		_set_state.emit(STATE_PRE_ENTERED)
		return

func _call_enter_path() -> void:
	var state := await _route_transaction.get_state()

	if _abort.is_requested:
		_set_state.emit(STATE_ENTERING)
		return

	match [state, _is_reentry]:
		# セグメントパターンマッチによる再進入
		[STATE_ENTERING, true], \
		[STATE_ENTERED, true], \
		# 他
		[STATE_EXITING, _], \
		[STATE_EXITED, _], \
		[STATE_POST_EXITING, _], \
		[STATE_POST_EXITED, _]:
			if is_instance_valid(_route_node) and XDUT_RouteHelper.has_enter_path(_route_node):
				await XDUT_RouteHelper.call_enter_path(
					_route_node,
					_route_params,
					_abort)

	_set_state.emit(STATE_ENTERED)
