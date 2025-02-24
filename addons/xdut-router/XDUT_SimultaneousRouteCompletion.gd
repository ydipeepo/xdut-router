class_name XDUT_SimultaneousRouteCompletion extends TaskBase

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func cleanup() -> void:
	if is_instance_valid(_router_canonical):
		_router_canonical.cleanup_group(_group.etag)
	_router_canonical = null

	super()

	unreference()

#-------------------------------------------------------------------------------

var _router_canonical: Node
var _path: String
var _group: XDUT_RouteInvocationGroup

func _init(
	router_canonical: Node,
	path: String,
	group: XDUT_RouteInvocationGroup) -> void:

	reference()

	_router_canonical = router_canonical
	_path = path
	_group = group
	_perform()

func _perform() -> void:
	#
	# EXIT, ENTER 同時
	#
	# +-<-----+ PRE_ENTER
	# |
	# +-<-+---+ EXIT
	# |   |
	# |   +---+ ENTER
	# |
	# +-<-----+ POST_EXIT
	# |
	# X < RELEASE
	# |
	# :
	#

	var calls: Array[Callable] = []

	#
	# PRE_ENTER
	#

	_group.get_pre_enter_calls(calls)
	while not calls.is_empty():
		await Task.wait_all(calls); calls.clear()
		_group.get_pre_enter_calls(calls)

	#
	# EXIT, ENTER
	#

	_group.get_exit_calls(calls)
	_group.get_enter_calls(calls)
	if not calls.is_empty():
		await Task.wait_all(calls); calls.clear()

	#
	# POST_EXIT
	#

	_group.get_post_exit_calls(calls)
	while not calls.is_empty():
		await Task.wait_all(calls); calls.clear()
		_group.get_post_exit_calls(calls)

	#
	# 通知
	#

	release_complete(_path)
