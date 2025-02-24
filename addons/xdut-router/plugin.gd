@tool
extends EditorPlugin

#-------------------------------------------------------------------------------

static func _add_setting(
	key: String,
	default_value: Variant,
	property_hint: int,
	property_hint_string) -> void:

	if not ProjectSettings.has_setting(key):
		var property_info := {
			"name": key,
			"type": typeof(default_value),
			"hint": property_hint,
			"hint_string": property_hint_string,
		}

		ProjectSettings.set_setting(key, default_value)
		ProjectSettings.add_property_info(property_info)
		ProjectSettings.set_initial_value(key, default_value)
		ProjectSettings.set_as_basic(key, true)

static func _remove_setting(key: String) -> void:
	ProjectSettings.clear(key)

func _print(message: String, plugin_name: Variant = null) -> void:
	if OS.has_feature("editor"):
		if plugin_name == null:
			plugin_name = _get_plugin_name()
		print_rich("🧩 [u]", plugin_name, "[/u]: ", message)

func _get_plugin_name() -> String:
	return "XDUT Router"

func _enter_tree() -> void:
	_add_setting("xdut/router/navigation/verbose", true, PROPERTY_HINT_NONE, null)

	add_autoload_singleton("XDUT_RouterCanonical", "XDUT_RouterCanonical.gd")
	add_custom_type("Route", "Node", preload("Route.gd"), preload("Route.png"))
	add_custom_type("Route2D", "Node2D", preload("Route2D.gd"), preload("Route2D.png"))
	add_custom_type("Route3D", "Node3D", preload("Route3D.gd"), preload("Route3D.png"))
	add_custom_type("RouteControl", "Control", preload("RouteControl.gd"), preload("RouteControl.png"))
	add_custom_type("PackageRoute", "Node", preload("PackageRoute.gd"), preload("PackageRoute.png"))
	add_custom_type("PackageRoute2D", "Node2D", preload("PackageRoute2D.gd"), preload("PackageRoute2D.png"))
	add_custom_type("PackageRoute3D", "Node3D", preload("PackageRoute3D.gd"), preload("PackageRoute3D.png"))
	add_custom_type("PackageRouteControl", "Control", preload("PackageRouteControl.gd"), preload("PackageRouteControl.png"))

	_print("Activated.")

func _exit_tree() -> void:
	remove_custom_type("PackageRouteControl")
	remove_custom_type("PackageRoute3D")
	remove_custom_type("PackageRoute2D")
	remove_custom_type("PackageRoute")
	remove_custom_type("RouteControl")
	remove_custom_type("Route3D")
	remove_custom_type("Route2D")
	remove_custom_type("Route")
	remove_autoload_singleton("XDUT_RouterCanonical")

	_remove_setting("xdut/router/navigation/verbose")
