extends Node3D

func _enter_path(route_params: Dictionary) -> void:
	var offset := -float(route_params.offset)
	await Motion \
		.spring(%CameraPivot, "position:z") \
		.preset("gentle") \
		.to(offset) \
		.wait()

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	%Label.text = "%.1f" % -%CameraPivot.position.z
