class_name XDUT_RouteExitEventTransaction extends XDUT_RouteTransaction

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
var _abort := Cancel.create()
var _state_task: Task

func _init(
	route_transaction: XDUT_RouteTransaction,
	route_event_batch: XDUT_RouteEventBatch,
	route_node: Node) -> void:

	_route_transaction = route_transaction
	_route_event_batch = route_event_batch
	_route_node = route_node
	_state_task = Task.from_signal(_set_state, 1)

	route_event_batch.append_exit_path([self, _call_exit_path.get_method()])
	route_event_batch.append_post_exit_path([self, _call_post_exit_path.get_method()])

func _call_exit_path() -> void:
	var state := await _route_transaction.get_state()

	if _abort.is_requested:
		_set_state.emit(STATE_EXITING)
		return

	match state:
		#STATE_PRE_ENTERING, \
		#STATE_PRE_ENTERED, \
		STATE_ENTERING, \
		STATE_ENTERED:
			if is_instance_valid(_route_node) and XDUT_RouteHelper.has_exit_path(_route_node):
				await XDUT_RouteHelper.call_exit_path(
					_route_node,
					_abort)

	if _abort.is_requested:
		_set_state.emit(STATE_EXITED)
		return

func _call_post_exit_path() -> void:
	var state := await _route_transaction.get_state()

	if _abort.is_requested:
		_set_state.emit(STATE_POST_EXITING)
		return

	match state:
		#STATE_PRE_ENTER, \
		STATE_PRE_ENTERED, \
		STATE_ENTERING, \
		STATE_ENTERED:
			if is_instance_valid(_route_node) and XDUT_RouteHelper.has_post_exit_path(_route_node):
				await XDUT_RouteHelper.call_post_exit_path(
					_route_node,
					_route_event_batch.etag)

	_set_state.emit(STATE_POST_EXITED)
