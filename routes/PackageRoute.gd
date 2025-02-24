extends CenterContainer

func _on_goto_pressed() -> void:
	Router.goto("/package-route")

func _on_goto_auto_free_node_and_package_pressed() -> void:
	Router.goto("/package-route/auto-free-node-and-package")

func _on_goto_auto_free_node_pressed() -> void:
	Router.goto("/package-route/auto-free-node")

func _on_goto_auto_free_disabled_pressed() -> void:
	Router.goto("/package-route/auto-free-disabled")
