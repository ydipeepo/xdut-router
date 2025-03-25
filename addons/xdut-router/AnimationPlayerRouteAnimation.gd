class_name AnimationPlayerRouteAnimation extends RouteAnimationBase

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

## [Route] を基準とした [AnimationPlayer] ノードへのパス。
@export var player_path: String = "."

## パスに一致したとき開始するアニメーション名。
@export var enter_animation_name: String

## パスから外れたとき開始するアニメーション名。
@export var exit_animation_name: String

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func animate_enter(
	route_node: Node,
	route_cancel: Cancel) -> void:

	if route_node.has_node(player_path):
		if not enter_animation_name.is_empty() and not route_cancel.is_requested:
			var node: AnimationPlayer = route_node.get_node(player_path)
			var task := Task.from_conditional_signal(
				node.animation_finished,
				[enter_animation_name],
				route_cancel)
			node.play(enter_animation_name)
			await task.wait()
	else:
		printerr("\tTarget animation player path for transition not found: '%s'" % player_path)

func animate_exit(
	route_node: Node,
	route_cancel: Cancel) -> void:

	if route_node.has_node(player_path):
		if not exit_animation_name.is_empty() and not route_cancel.is_requested:
			var node: AnimationPlayer = route_node.get_node(player_path)
			var task := Task.from_conditional_signal(
				node.animation_finished,
				[exit_animation_name])
			node.play(exit_animation_name)
			await task.wait()
	else:
		printerr("\tTarget animation player path for transition not found: '%s'" % player_path)
