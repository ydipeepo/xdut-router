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

func bundle_pre_enter_path(
	route_params: Dictionary,
	group_etag: int,
	calls: Array[Callable]) -> void:

	if _outer_required:
		calls.push_back(_pre_enter_path.bind(route_params, group_etag))

func bundle_enter_path(
	route_params: Dictionary,
	calls: Array[Callable]) -> void:

	if _outer_required:
		calls.push_back(_enter_path.bind(route_params))
	else:
		calls.push_back(_enter_path_without_outer.bind(route_params))

func bundle_exit_path(calls: Array[Callable]) -> void:
	if _outer_required:
		calls.push_back(_exit_path)
	else:
		calls.push_back(_exit_path_without_outer)

func bundle_post_exit_path(
	group_etag: int,
	calls: Array[Callable]) -> void:

	if _outer_required:
		calls.push_back(_post_exit_path.bind(group_etag))

#-------------------------------------------------------------------------------

signal _inner_exit_path_release

var _route_node: Node
var _inner_entrants: int
var _inner_cancel: Cancel
var _outer_entrants: int
var _outer_pre_enter_task: Task
var _outer_post_exit_task: Task
var _outer_required: bool

func _pre_enter_path(
	route_params: Dictionary,
	group_etag: int) -> void:

	var outer_entrants := _outer_entrants
	_outer_entrants += 1

	if outer_entrants < 0:
		return

	if _outer_post_exit_task != null:
		await _outer_post_exit_task.wait()
	_outer_post_exit_task = null

	if outer_entrants == 0:
		var pre_enter_path := XDUT_RouteHelper.get_pre_enter_path(
			_route_node,
			route_params,
			group_etag)
		if pre_enter_path.is_valid():
			_outer_pre_enter_task = Task.from_method(pre_enter_path)
	if _outer_pre_enter_task != null:
		await _outer_pre_enter_task.wait()
	_outer_pre_enter_task = null

func _enter_path_without_outer(route_params: Dictionary) -> void:
	var inner_entrants := _inner_entrants
	_inner_entrants += 1

	var route_cancel := Cancel.create()
	if _inner_cancel != null:
		_inner_cancel.request()
		_inner_cancel = null
	_inner_cancel = route_cancel

	var enter_path := XDUT_RouteHelper.get_enter_path(_route_node, route_params, route_cancel)
	if enter_path.is_valid():
		await enter_path.call()

	if inner_entrants < 0:
		_inner_exit_path_release.emit()

func _enter_path(route_params: Dictionary) -> void:
	if _outer_entrants <= 0:
		return

	if _outer_pre_enter_task != null:
		await _outer_pre_enter_task.wait()
	_outer_pre_enter_task = null

	await _enter_path_without_outer(route_params)

func _exit_path_without_outer() -> void:
	_inner_entrants -= 1
	var inner_entrants := _inner_entrants

	var inner_exit_path_release_task: Task
	if inner_entrants < 0:
		inner_exit_path_release_task = Task.from_signal(_inner_exit_path_release)

	var route_cancel := Cancel.create()
	if _inner_cancel != null:
		_inner_cancel.request()
		_inner_cancel = null
	_inner_cancel = route_cancel

	if inner_entrants < 0:
		await inner_exit_path_release_task.wait()

	var exit_path := XDUT_RouteHelper.get_exit_path(_route_node, route_cancel)
	if exit_path.is_valid():
		await exit_path.call()

func _exit_path() -> void:
	if _outer_entrants <= 0:
		return

	if _outer_pre_enter_task != null:
		await _outer_pre_enter_task.wait()
	_outer_pre_enter_task = null

	await _exit_path_without_outer()

func _post_exit_path(group_etag: int) -> void:
	_outer_entrants -= 1
	var outer_entrants := _outer_entrants

	if outer_entrants < 0:
		return

	if _outer_pre_enter_task != null:
		await _outer_pre_enter_task.wait()
	_outer_pre_enter_task = null

	if outer_entrants == 0:
		var post_exit_path := XDUT_RouteHelper.get_post_exit_path(_route_node, group_etag)
		if post_exit_path.is_valid():
			_outer_post_exit_task = Task.from_method(post_exit_path)
	if _outer_post_exit_task != null:
		await _outer_post_exit_task.wait()
	_outer_post_exit_task = null

func _init(route_node: Node) -> void:
	assert(route_node != null)

	_route_node = route_node
	_outer_required = \
		XDUT_RouteHelper.has_pre_enter_path(_route_node) or \
		XDUT_RouteHelper.has_post_exit_path(_route_node)
