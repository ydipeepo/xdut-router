class_name GlideMotionRouteTransition extends MotionRouteTransitionBase

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

## アニメーションの崩壊定数。
@export_range(XDUT_MotionTransition.EPSILON, 10.0, 0.1, "or_greater") var power := XDUT_GlideMotionTransition.DEFAULT_POWER

## アニメーションの時定数。
@export_range(0.0, 10.0, 0.1, "or_greater") var time_constant := XDUT_GlideMotionTransition.DEFAULT_TIME_CONSTANT

## アニメーションを休止させる位置デルタ。
@export_range(XDUT_MotionTransition.EPSILON, 10.0, 0.1, "or_greater") var rest_delta := XDUT_GlideMotionTransition.DEFAULT_REST_DELTA

## アニメーションで速度を重視するか位置を重視するか。
@export_enum("Velocity", "Position") var prefer: int = XDUT_GlideMotionTransition.DEFAULT_PREFER

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
		.glide(node, node_property_key) \
		.set_power(power) \
		.set_time_constant(time_constant) \
		.set_rest_delta(rest_delta) \
		.set_prefer(prefer) \
		.delay(delay) \
		.set_process(process) \
		.from(from) \
		.to(to) \
		.wait()
