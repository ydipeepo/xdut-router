extends CenterContainer

func _on_goto_pressed() -> void:
	%Enter.button_pressed = false
	%Exit.button_pressed = true

	Router.goto("/timing")

func _on_goto_open_pressed() -> void:
	%Enter.button_pressed = true
	%Exit.button_pressed = false
	
	Router.goto("/timing/open")

func _on_route_open_entering_path() -> void:
	%Entering.button_pressed = true
	%Entered.button_pressed = false
	%Exiting.button_pressed = false
	%Exited.button_pressed = false

func _on_route_open_entered_path() -> void:
	%Entering.button_pressed = false
	%Entered.button_pressed = true
	%Exiting.button_pressed = false
	%Exited.button_pressed = false

func _on_route_open_exiting_path() -> void:
	%Entering.button_pressed = false
	%Entered.button_pressed = false
	%Exiting.button_pressed = true
	%Exited.button_pressed = false

func _on_route_open_exited_path() -> void:
	%Entering.button_pressed = false
	%Entered.button_pressed = false
	%Exiting.button_pressed = false
	%Exited.button_pressed = true
