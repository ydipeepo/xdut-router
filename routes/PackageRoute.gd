extends CenterContainer

func _on_goto_pressed() -> void:
	Router.goto("./", self)

func _on_goto_auto_free_node_and_package_pressed() -> void:
	Router.goto("./auto-free-node-and-package", self)

func _on_goto_auto_free_node_pressed() -> void:
	Router.goto("./auto-free-node", self)

func _on_goto_auto_free_disabled_pressed() -> void:
	Router.goto("./auto-free-disabled", self)
