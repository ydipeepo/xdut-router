@tool
extends EditorPlugin

#-------------------------------------------------------------------------------

func _print(message: String, plugin_name: Variant = null) -> void:
	if OS.has_feature("editor"):
		if plugin_name == null:
			plugin_name = _get_plugin_name()
		print_rich("🧩 [u]", plugin_name, "[/u]: ", message)

func _get_plugin_name() -> String:
	return "XDUT Router Motion"

func _enter_tree() -> void:
	_print("Activated.")
