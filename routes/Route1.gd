extends CenterContainer

func _ready() -> void:
	Router.replace("/route-1/flip")

func _on_goto_flip_pressed() -> void:
	Router.goto("/route-1/flop")

func _on_goto_flop_pressed() -> void:
	Router.goto("/route-1/flip")
