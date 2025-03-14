class_name XDUT_RouteWrapper

#
# NOTE:
# ルートノードは遷移がオーバーラップした場合
# 適切にライフサイクルイベントを処理できません。
# このクラスはルートノードをラップし、
# ライフサイクルイベントの順序とタイミングの調整を行います。
#

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

var route_node: Node:
	get:
		return _route_node

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func bundle_pre_enter_and_enter_path(
	group: XDUT_RouteInvocationGroup,
	route_params: Dictionary) -> void:

	var route_cancel := Cancel.create()
	var group_etag := group.group_etag

	match _transition:
		_TRANSITION_PRE_ENTER:
			group.append_pre_enter_path(_pre_enter_path.bind(_transition_pre_enter_task, route_params, group_etag))
			group.append_enter_path(_enter_path.bind(_transition_enter_task, route_cancel, route_params, group_etag))
			_transition_pre_enter_task = Task.from_conditional_signal(_transition_completed, [_TRANSITION_PRE_ENTER, group_etag])
			_transition_enter_task = Task.from_conditional_signal(_transition_completed, [_TRANSITION_ENTER, group_etag])

		_TRANSITION_ENTER:
			group.append_enter_path(_enter_path.bind(_transition_enter_task, route_cancel, route_params, group_etag))
			_transition_enter_task = Task.from_conditional_signal(_transition_completed, [_TRANSITION_ENTER, group_etag])

		_TRANSITION_EXIT:
			group.append_enter_path(_enter_path.bind(_transition_exit_task, route_cancel, route_params, group_etag))
			_transition_enter_task = Task.from_conditional_signal(_transition_completed, [_TRANSITION_ENTER, group_etag])

		_TRANSITION_POST_EXIT:
			group.append_pre_enter_path(_pre_enter_path.bind(_transition_post_exit_task, route_params, group_etag))
			group.append_enter_path(_enter_path.bind(Task.completed(), route_cancel, route_params, group_etag))
			_transition_pre_enter_task = Task.from_conditional_signal(_transition_completed, [_TRANSITION_PRE_ENTER, group_etag])
			_transition_enter_task = Task.from_conditional_signal(_transition_completed, [_TRANSITION_ENTER, group_etag])

	if _transition_cancel != null:
		_transition_cancel.request()
	_transition_cancel = route_cancel

func bundle_exit_and_post_exit_path(group: XDUT_RouteInvocationGroup) -> void:
	var route_cancel := Cancel.create()
	var group_etag := group.group_etag

	match _transition:
		_TRANSITION_PRE_ENTER:
			group.append_post_exit_path(_post_exit_path.bind(_transition_pre_enter_task, group_etag))
			_transition_post_exit_task = Task.from_conditional_signal(_transition_completed, [_TRANSITION_POST_EXIT, group_etag])

		_TRANSITION_ENTER:
			group.append_exit_path(_exit_path.bind(_transition_enter_task, route_cancel, group_etag))
			group.append_post_exit_path(_post_exit_path.bind(Task.completed(), group_etag))
			_transition_exit_task = Task.from_conditional_signal(_transition_completed, [_TRANSITION_EXIT, group_etag])
			_transition_post_exit_task = Task.from_conditional_signal(_transition_completed, [_TRANSITION_POST_EXIT, group_etag])

		_TRANSITION_EXIT:
			group.append_exit_path(_exit_path.bind(_transition_exit_task, route_cancel, group_etag))
			group.append_post_exit_path(_post_exit_path.bind(_transition_post_exit_task, group_etag))
			_transition_exit_task = Task.from_conditional_signal(_transition_completed, [_TRANSITION_EXIT, group_etag])
			_transition_post_exit_task = Task.from_conditional_signal(_transition_completed, [_TRANSITION_POST_EXIT, group_etag])

		_TRANSITION_POST_EXIT:
			group.append_post_exit_path(_post_exit_path.bind(_transition_post_exit_task, group_etag))
			_transition_post_exit_task = Task.from_conditional_signal(_transition_completed, [_TRANSITION_POST_EXIT, group_etag])
	
	if _transition_cancel != null:
		_transition_cancel.request()
	_transition_cancel = route_cancel

#-------------------------------------------------------------------------------

signal _transition_completed(transition: int, group_etag: int)

enum {
	_TRANSITION_PRE_ENTER,
	_TRANSITION_ENTER,
	_TRANSITION_EXIT,
	_TRANSITION_POST_EXIT,
}

var _route_node: Node
var _transition: int = _TRANSITION_POST_EXIT
var _transition_cancel: Cancel
var _transition_pre_enter_task := Task.completed()
var _transition_enter_task := Task.completed()
var _transition_exit_task := Task.completed()
var _transition_post_exit_task := Task.completed()

func _pre_enter_path(
	transition_before_task: Task,
	route_params: Dictionary,
	group_etag: int) -> void:

	await transition_before_task.wait()
	var transition_before := _transition
	_transition = _TRANSITION_PRE_ENTER

	match transition_before:
		_TRANSITION_PRE_ENTER:
			pass
		_TRANSITION_POST_EXIT:
			if XDUT_RouteHelper.has_pre_enter_path(_route_node):
				var pre_enter_path := XDUT_RouteHelper.get_pre_enter_path(
					_route_node,
					route_params,
					group_etag)
				await pre_enter_path.call()
		_:
			assert(false)

	_transition_completed.emit(_TRANSITION_PRE_ENTER, group_etag)

func _enter_path(
	transition_before_task: Task,
	route_cancel: Cancel,
	route_params: Dictionary,
	group_etag: int) -> void:

	await transition_before_task.wait()
	var transition_before := _transition
	if not route_cancel.is_requested:
		_transition = _TRANSITION_ENTER

		match transition_before:
			_TRANSITION_PRE_ENTER, \
			_TRANSITION_ENTER, \
			_TRANSITION_EXIT, \
			_TRANSITION_POST_EXIT:
				if XDUT_RouteHelper.has_enter_path(_route_node):
					var enter_path := XDUT_RouteHelper.get_enter_path(
						_route_node,
						route_params,
						route_cancel)
					await enter_path.call()
			_:
				assert(false)

	_transition_completed.emit(_TRANSITION_ENTER, group_etag)

func _exit_path(
	transition_before_task: Task,
	route_cancel: Cancel,
	group_etag: int) -> void:

	await transition_before_task.wait()
	var transition_before := _transition
	if not route_cancel.is_requested:
		_transition = _TRANSITION_EXIT

		match transition_before:
			_TRANSITION_ENTER, \
			_TRANSITION_EXIT:
				if XDUT_RouteHelper.has_exit_path(_route_node):
					var exit_path := XDUT_RouteHelper.get_exit_path(
						_route_node,
						route_cancel)
					await exit_path.call()
			_:
				assert(false)

	_transition_completed.emit(_TRANSITION_EXIT, group_etag)

func _post_exit_path(
	transition_before_task: Task,
	group_etag: int) -> void:

	await transition_before_task.wait()
	var transition_before := _transition
	_transition = _TRANSITION_POST_EXIT

	match transition_before:
		_TRANSITION_PRE_ENTER, \
		_TRANSITION_ENTER:
			if XDUT_RouteHelper.has_post_exit_path(_route_node):
				var post_exit_path := XDUT_RouteHelper.get_post_exit_path(
					_route_node,
					group_etag)
				await post_exit_path.call()
		_TRANSITION_EXIT, \
		_TRANSITION_POST_EXIT:
			pass
		_:
			assert(false)

	_transition_completed.emit(_TRANSITION_POST_EXIT, group_etag)

func _init(route_node: Node) -> void:
	assert(route_node != null)

	_route_node = route_node
