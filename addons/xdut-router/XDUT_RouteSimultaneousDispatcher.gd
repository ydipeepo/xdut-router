class_name XDUT_RouteSimultaneousDispatcher extends TaskBase

#
# NOTE:
# _exit_path, _enter_path を平行して処理します。
#
# +-<-----+ _pre_enter_path
# |
# +-<-+---+ _exit_path
# |   |
# |   +---+ _enter_path
# |
# +-<-----+ _post_exit_path
# |
# X < release
# |
# :
#

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func cleanup() -> void:
	if is_instance_valid(_router_canonical):
		_router_canonical.cleanup_event_batch(_route_event_batch.etag)
	_router_canonical = null

	super()

	unreference()

#-------------------------------------------------------------------------------

var _router_canonical: Node
var _path: String
var _route_event_batch: XDUT_RouteEventBatch

func _init(
	router_canonical: Node,
	route_event_batch: XDUT_RouteEventBatch,
	path: String) -> void:

	reference()

	_router_canonical = router_canonical
	_route_event_batch = route_event_batch
	_path = path
	_perform()

func _perform() -> void:
	var calls := []

	_route_event_batch.bundle_pre_enter_path(calls)
	while not calls.is_empty():
		await Task.wait_all(calls); calls.clear()
		_route_event_batch.bundle_pre_enter_path(calls)

	_route_event_batch.bundle_exit_path(calls)
	_route_event_batch.bundle_enter_path(calls)
	if not calls.is_empty():
		await Task.wait_all(calls); calls.clear()

	_route_event_batch.bundle_post_exit_path(calls)
	while not calls.is_empty():
		await Task.wait_all(calls); calls.clear()
		_route_event_batch.bundle_post_exit_path(calls)

	release_complete(_path)
