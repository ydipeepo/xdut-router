extends CenterContainer

func _on_goto_pressed() -> void:
	Router.goto("./", self)

func _on_goto_measure_0_pressed() -> void:
	Router.goto("./measure-0", self)

func _on_goto_measure_32_pressed() -> void:
	Router.goto("./measure-32", self)

func _on_goto_measure_64_pressed() -> void:
	Router.goto("./measure-64", self)
