class_name SpringMotionRouteTransition extends MotionRouteTransitionBase

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

## アニメーションの剛性。
@export_range(XDUT_MotionTransition.EPSILON, 1000.0, 1.0, "or_greater") var stiffness := XDUT_SpringMotionTransition.DEFAULT_STIFFNESS

## アニメーションの減衰。
@export_range(0.0, 1000.0, 1.0, "or_greater") var damping := XDUT_SpringMotionTransition.DEFAULT_DAMPING

## アニメーションの質量。
@export_range(XDUT_MotionTransition.EPSILON, 1000.0, 1.0, "or_greater") var mass := XDUT_SpringMotionTransition.DEFAULT_MASS

## アニメーションを休止させる位置デルタ。
@export_range(XDUT_MotionTransition.EPSILON, 10.0, 0.1, "or_greater") var rest_delta := XDUT_SpringMotionTransition.DEFAULT_REST_DELTA

## アニメーションを休止させる速度。
@export_range(XDUT_MotionTransition.EPSILON, 10.0, 0.1, "or_greater", "units/s") var rest_speed := XDUT_SpringMotionTransition.DEFAULT_REST_SPEED

## アニメーションが過減衰とならないよう制限するかどうか。
@export var limit_overdamping := XDUT_SpringMotionTransition.DEFAULT_LIMIT_OVERDAMPING

## アニメーションがオーバーシュートしないよう制限するかどうか。
@export var limit_overshooting := XDUT_SpringMotionTransition.DEFAULT_LIMIT_OVERSHOOTING

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func start(
	node: Node,
	node_property_key: String,
	from: Variant,
	to: Variant,
	delay: float,
	process: int,
	route_cancel: Cancel) -> void:

	if 0.0 < delay:
		node.set_indexed(node_property_key, from)
	await Motion \
		.spring(node, node_property_key, route_cancel) \
		.set_stiffness(stiffness) \
		.set_damping(damping) \
		.set_mass(mass) \
		.set_rest_delta(rest_delta) \
		.set_rest_speed(rest_speed) \
		.limit_overdamping(limit_overdamping) \
		.limit_overshooting(limit_overshooting) \
		.delay(delay) \
		.set_process(process) \
		.from(from) \
		.to(to) \
		.wait()
