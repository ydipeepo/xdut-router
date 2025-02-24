@icon("Route3D.png")
class_name Route3D extends Node3D

#-------------------------------------------------------------------------------
#	CONSTANTS
#-------------------------------------------------------------------------------

enum {
	## ルート子ノードに通知を行います。
	FLAG_NOTIFY_CHILDREN = 0x01,
	
	## ルート子ノードの可視設定を自動で行います。
	FLAG_AUTO_VISIBLE_CHILDREN = 0x02,
	
	## ルートの可視設定を自動で行います。
	FLAG_AUTO_VISIBLE_SELF = 0x04,
}

#-------------------------------------------------------------------------------
#	SIGNALS
#-------------------------------------------------------------------------------

## ルートへの進入が始まると呼び出されます。
signal entering_path

## ルートへの進入が完了すると呼び出されます。
signal entered_path

## ルートから退出が始まると呼び出されます。
signal exiting_path

## ルートから退出が完了すると呼び出されます。
signal exited_path

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

## ルートフラグ。
@export_flags(
	"Notify Children",
	"Auto Visible Children",
	"Auto Visible Self") var flags: int = FLAG_AUTO_VISIBLE_SELF:

	get:
		return _flags

	set(value):
		if is_inside_tree():
			printerr("Route '", name, " property 'flags' cannot be changed while entered the tree.")
			return

		_flags = value

## アニメーションリスト。
@export var animations: Array[RouteAnimationBase]:
	get:
		return _animations

	set(value):
		if is_inside_tree():
			printerr("Route '", name, "' property 'animations' cannot be changed while entered the tree.")
			return

		_animations = value

## ルートセグメント。[br]
## [br]
## コロン [code]:[/code] 以降はパターンとして扱われルートパラメタキーとして抽出されます。[br]
## パラメタキー名に続けて、かっこ [code]([/code]、[code])[/code] で囲うことにより[br]
## 正規表現による制約を課すことができます。[code]-[/code] により複数のパターンを組み合わせることもできます。[br]
## [br]
## 例えば根のルートである場合、[br]
## [b]例)[/b] ルートセグメント [code]abc[/code] は、パス [code]/abc[/code] にマッチします。[br]
## [b]例)[/b] ルートセグメント [code]abc-:arg[/code] は、パス [code]/abc-abc[/code]、[code]/abc-123[/code] などにマッチし、[code]abc[/code] や [code]123[/code] がルートパラメタキー [code]arg[/code] として抽出されます。[br]
## [b]例)[/b] ルートセグメント [code]abc-:arg(\d+)[/code] は、パス [code]/abc-1[/code]、[code]/abc-123[/code] などにマッチし、[code]1[/code] や [code]123[/code] がルートパラメタキー [code]arg[/code] として抽出されます。[br]
@export var route_segment: String:
	get:
		return _route_segment

	set(value):
		if is_inside_tree():
			printerr("Route '", name, "' property 'route_segment' cannot be accessed while entered the tree.")
			return

		if XDUT_RouteHelper.parse_route_segment(value) == null:
			printerr("Invalid 'route_segment' format: ", value)
			return
		_route_segment = value

## ルート。[br]
## [br]
## ツリーに追加されている場合のみアクセスできます。
var route: String:
	get:
		if not is_inside_tree():
			printerr("Route '", name, "' property 'route' can be accessed while entered the tree.")
			return ""

		if _route == null:
			_route = XDUT_RouteHelper.get_route(self)
		return _route

## ルートパラメタ。[br]
## [br]
## 祖先ルートの全てのパラメタと結合されます。
var route_params: Dictionary:
	get:
		#if not is_inside_path():
		#	printerr("Route '", name, "' property 'route_params' can be accessed while entered the path.")
		#	return {}

		return _route_params

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

## このルートがパスに一致しているかを返します。
func is_inside_path() -> bool:
	return \
		_state == _STATE_ENTERING or \
		_state == _STATE_ENTERED

func get_navigation_verbose() -> bool:
	if is_instance_valid(_canonical):
		return _canonical.get_navigation_verbose()
	return true

func save_group(group_etag: int) -> void:
	#
	# 内部用です。ネストされた呼び出しを集約するために継承先で使います。
	#

	if is_instance_valid(_canonical):
		_canonical.save_group(group_etag)

func restore_group() -> void:
	#
	# 内部用です。ネストされた呼び出しを集約するために継承先で使います。
	#

	if is_instance_valid(_canonical):
		_canonical.restore_group()

#-------------------------------------------------------------------------------

enum {
	_STATE_ENTERING,
	_STATE_ENTERED,
	_STATE_EXITING,
	_STATE_EXITED,
}

var _canonical: Node
var _flags: int = FLAG_AUTO_VISIBLE_SELF
var _animations: Array[RouteAnimationBase]
var _route_segment: String
var _route: Variant
var _route_params: Dictionary
var _state: int = _STATE_EXITED
var _state_cancel: Cancel

func _enter_tree() -> void:
	if _route_segment.is_empty():
		printerr("Invalid route '", name, "' segment.")
		return

	_canonical = Engine \
		.get_main_loop() \
		.root \
		.get_node("/root/XDUT_RouterCanonical")
	if not is_instance_valid(_canonical):
		printerr("XDUT Router is not activated.")
		return

	if _flags & FLAG_AUTO_VISIBLE_SELF != 0:
		visible = false
	if _flags & FLAG_AUTO_VISIBLE_CHILDREN != 0:
		for child_node: Node in get_children():
			child_node.visible = false
	_canonical.register(self, _route_segment)

func _exit_tree() -> void:
	if not is_instance_valid(_canonical):
		printerr("XDUT Router is not activated.")
		return

	if _state_cancel != null:
		_state_cancel.request()
		_state_cancel = null

	_canonical.unregister(self)
	_canonical = null

func _enter_path_core(
	cancel: Cancel,
	route_params: Dictionary) -> void:

	_route_params = route_params

	if _state == _STATE_EXITED:
		_animations.make_read_only()

		if _flags & FLAG_AUTO_VISIBLE_SELF != 0:
			visible = true
		if _flags & FLAG_AUTO_VISIBLE_CHILDREN != 0:
			for child_node: Node in get_children():
				child_node.visible = true

		entering_path.emit()

	_state = _STATE_ENTERING

	await XDUT_RouteHelper.wait_animate_and_child_enter_calls(
		self,
		route_params,
		_flags & FLAG_NOTIFY_CHILDREN != 0)

	if cancel.is_requested:
		return

	if _state == _STATE_ENTERING:
		entered_path.emit()

	_state = _STATE_ENTERED

func _enter_path(route_params: Dictionary) -> void:
	if _state_cancel != null:
		_state_cancel.request()
		_state_cancel = null
	_state_cancel = Cancel.create()

	await Task \
		.from_method(
			_enter_path_core.bind(route_params),
			_state_cancel) \
		.wait()

func _exit_path_core(cancel: Cancel) -> void:
	if _state == _STATE_ENTERED:
		exiting_path.emit()

	_state = _STATE_EXITING

	await XDUT_RouteHelper.wait_animate_and_child_exit_calls(
		self,
		flags & FLAG_NOTIFY_CHILDREN != 0)

	if cancel.is_requested:
		return

	_route_params.clear()
	_route = ""

	if _state == _STATE_EXITING:
		exited_path.emit()

		if _flags & FLAG_AUTO_VISIBLE_CHILDREN != 0:
			for child_index: int in range(get_child_count() - 1, -1, -1):
				var child_node: Node = get_child(child_index)
				child_node.visible = false
		if _flags & FLAG_AUTO_VISIBLE_SELF != 0:
			visible = false

		var animations := _animations
		_animations = []
		_animations.assign(animations)

	_state = _STATE_EXITED

func _exit_path() -> void:
	if _state_cancel != null:
		_state_cancel.request()
		_state_cancel = null
	_state_cancel = Cancel.create()

	await Task \
		.from_method(
			_exit_path_core,
			_state_cancel) \
		.wait()

func _to_string() -> String:
	return "<Route3D#%s>" % _route_segment
