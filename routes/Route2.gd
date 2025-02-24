extends CenterContainer

func _on_goto_pressed() -> void:
	Router.goto("/route-2")

func _on_goto_a_pressed() -> void:
	Router.goto("/route-2/a")

func _on_goto_a_b_pressed() -> void:
	Router.goto("/route-2/a/b")

func _on_goto_a_b_c_pressed() -> void:
	Router.goto("/route-2/a/b/c")

func _on_route_a_resized() -> void:
	%Route_A.pivot_offset = %Route_A.size / 2.0

func _on_route_b_resized() -> void:
	%Route_B.pivot_offset = %Route_B.size / 2.0

func _on_route_c_resized() -> void:
	%Route_C.pivot_offset = %Route_C.size / 2.0
