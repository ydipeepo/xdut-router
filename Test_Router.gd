extends MarginContainer

func _ready() -> void:
	Router.navigate.connect(_on_navigate)

func _on_navigate() -> void:
	%Back.disabled = not Router.can_back()
	%Goto_Route1.disabled = Router.current_path.begins_with("/route-1")

func _on_back_pressed() -> void:
	Router.back()

func _on_goto_route_1_pressed() -> void:
	Router.goto("/route-1", null, Router.FLAG_EXCLUSIVE)

func _on_goto_route_2_pressed() -> void:
	Router.goto("/route-2", null, Router.FLAG_EXCLUSIVE)

func _on_goto_package_route_pressed() -> void:
	Router.goto("/package-route", null, Router.FLAG_EXCLUSIVE)

func _on_goto_pattern_match_pressed() -> void:
	Router.goto("/pattern-match", null, Router.FLAG_EXCLUSIVE)

func _on_goto_timing_pressed() -> void:
	Router.goto("/timing", null, Router.FLAG_EXCLUSIVE)

func _on_goto_child_notification_pressed() -> void:
	Router.goto("/child-notification", null, Router.FLAG_EXCLUSIVE)

func _on_goto_view_pressed() -> void:
	Router.goto("/view", null, Router.FLAG_EXCLUSIVE)
