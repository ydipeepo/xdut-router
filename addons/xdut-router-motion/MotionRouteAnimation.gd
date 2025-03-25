class_name MotionRouteAnimation extends RouteAnimationBase

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

## [Route] を基準としたターゲットノードへのパス。
@export var node_path: String = "."

## ターゲットノードの遷移させるプロパティ名。
@export var node_property_key: String

## 遷移の初期値、最終値。
@export var value: MotionRouteValueBase

## パスに一致したときの遷移。
@export var enter_transition: MotionRouteTransitionBase

## パスから外れたときの遷移。
@export var exit_transition: MotionRouteTransitionBase

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func animate_enter(
	route_node: Node,
	route_cancel: Cancel) -> void:

	if value == null:
		printerr("\t'value' is null.")
		return

	if not route_node.has_node(node_path):
		printerr("\tTarget node path for transition is not found: '", node_path, "'")
		return

	if not route_cancel.is_requested:
		var node := route_node.get_node(node_path)
		if enter_transition == null:
			if not node_property_key in node:
				printerr("\tTarget node property for transition not found: '", node_property_key, "' on '", node_path, "'")
				return
			node.set_indexed(node_property_key, value.get_value())
		else:
			await enter_transition.start(
				node,
				node_property_key,
				null if value.inherit_value_before_enter else value.get_value_before_enter(),
				value.get_value(),
				value.delay,
				value.process,
				route_cancel)

func animate_exit(
	route_node: Node,
	route_cancel: Cancel) -> void:

	if value == null:
		printerr("\t'value' is null.")
		return

	if not route_node.has_node(node_path):
		printerr("\tTarget node path for transition is not found: '", node_path, "'")
		return

	if not route_cancel.is_requested:
		var node := route_node.get_node(node_path)
		if exit_transition == null:
			if not node_property_key in node:
				printerr("\tTarget node property for transition not found: '", node_property_key, "' on '", node_path, "'")
				return
			node.set_indexed(node_property_key, value.get_value())
		else:
			await exit_transition.start(
				node,
				node_property_key,
				null if value.inherit_value_before_exit else value.get_value(),
				value.get_value_after_exit(),
				value.delay,
				value.process,
				route_cancel)
