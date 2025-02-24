class_name TweenMotionRouteTransition extends MotionRouteTransitionBase

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

## アニメーションのトランジション関数。
@export_enum(
	"Linear",
	"Sine",
	"Quint",
	"Quart",
	"Quad",
	"Expo",
	"Elastic",
	"Cubic",
	"Circ",
	"Bounce",
	"Back") var trans: int = XDUT_TweenMotionTransition.DEFAULT_TRANS_TYPE

## アニメーションのイージング関数。
@export_enum(
	"In",
	"Out",
	"In and Out",
	"Out and In") var ease: int = XDUT_TweenMotionTransition.DEFAULT_EASE_TYPE

## アニメーションの期間。
@export_range(0.0, 10.0, 0.1, "or_greater") var duration := XDUT_TweenMotionTransition.DEFAULT_DURATION

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func start(
	node: Node,
	node_property_key: String,
	from: Variant,
	to: Variant,
	delay: float,
	process: int) -> void:

	if 0.0 < delay:
		node.set_indexed(node_property_key, from)
	await Motion \
		.tween(node, node_property_key) \
		.set_duration(duration) \
		.set_ease(ease) \
		.set_trans(trans) \
		.delay(delay) \
		.set_process(process) \
		.from(from) \
		.to(to) \
		.wait()
