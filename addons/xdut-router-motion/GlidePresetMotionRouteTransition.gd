class_name GlidePresetMotionRouteTransition extends MotionRouteTransitionBase

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

## プリセット名。
@export var preset_name: String

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
		.preset(preset_name) \
		.delay(delay) \
		.set_process(process) \
		.from(from) \
		.to(to) \
		.wait()
