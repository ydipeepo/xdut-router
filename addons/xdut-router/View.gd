@icon("View.png")
class_name View extends Node

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

## オーナーを保ったままビューに追加するかどうか。
@export var keep_owner := true

## ルートに一致したとき、再度 _ready を呼び出すかどうか。
@export var call_ready := false

#-------------------------------------------------------------------------------

var _route_node: Node

func _enter_tree() -> void:
	_route_node = XDUT_RouteHelper.get_route_node(self)

	if _route_node == null:
		printerr("Parent route not found.")
		return

	if _route_node.has_signal(&"entering_path"):
		_route_node.entering_path.connect(_on_entering_path)
	if _route_node.has_signal(&"exited_path"):
		_route_node.exited_path.connect(_on_exited_path)

func _exit_tree() -> void:
	if _route_node == null:
		return

	if _route_node.has_signal(&"entering_path"):
		_route_node.entering_path.disconnect(_on_entering_path)
	if _route_node.has_signal(&"exited_path"):
		_route_node.exited_path.disconnect(_on_exited_path)

func _on_entering_path() -> void:
	for node: Node in _route_node.get_children():
		var node_owner := node.owner
		if node_owner == _route_node.owner:
			if call_ready:
				node.request_ready()
			node.reparent(self)
			if not keep_owner:
				node.owner = owner

func _on_exited_path() -> void:
	for node: Node in get_children():
		node.reparent(_route_node)
		if not keep_owner:
			node.owner = _route_node.owner

	_route_node = null
