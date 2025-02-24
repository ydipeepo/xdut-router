extends CenterContainer

func _on_goto_pressed() -> void:
	Router.goto("/pattern-match")

func _on_goto_measure_0_pressed() -> void:
	Router.goto("/pattern-match/measure-0")

func _on_goto_measure_32_pressed() -> void:
	Router.goto("/pattern-match/measure-32")

func _on_goto_measure_64_pressed() -> void:
	Router.goto("/pattern-match/measure-64")
