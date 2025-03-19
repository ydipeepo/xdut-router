@icon("PackageRoute.png")
class_name PackageRoute extends Route

#-------------------------------------------------------------------------------
#	CONSTANTS
#-------------------------------------------------------------------------------

enum {
	## ノードとパッケージを自動解放します。
	AUTO_FREE_NODE_AND_PACKAGE,
	
	## ノードを自動解放します。
	AUTO_FREE_NODE,
	
	## 自動解放は無効です。
	AUTO_FREE_DISABLED,
}

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

## パスから不一致となったとき、ノード及びパッケージを自動で解放するかどうか。
@export_enum(
	"Free Node and Package",
	"Free Node",
	"Disabled") var auto_free: int:

	get:
		return _auto_free

	set(value):
		if is_inside_tree():
			printerr("Route '", name, " property 'auto_free' cannot be changed while entered the tree.")
			return

		_auto_free = value

## パッケージパス。
@export_file("*.tscn") var package_path: String:
	get:
		return _package_path

	set(value):
		if is_inside_tree():
			printerr("Route '", name, " property 'package_path' cannot be changed while entered the tree.")
			return

		_package_path = value

#-------------------------------------------------------------------------------

var _auto_free: int = AUTO_FREE_NODE_AND_PACKAGE
var _package_path: String
var _package_node: Node
var _package: PackedScene

func _pre_enter_path(
	route_params: Dictionary,
	group_etag: int) -> void:

	var start: int
	var delta: int

	if _package == null:
		assert(_package_node == null)

		start = Time.get_ticks_usec()

		var package: PackedScene = await Task \
			.load(_package_path, &"PackedScene", ResourceLoader.CACHE_MODE_REPLACE) \
			.wait()
		if package == null:
			printerr("Failed to load the package: ", _package_path)
			return
		_package = package

		delta = Time.get_ticks_usec() - start
		
		if get_navigation_verbose():
			print("\tPackage load [", group_etag, "]: ", _package_path, ", ", delta / 1000.0, "msec")

	if _package_node == null:
		assert(_package != null)

		start = Time.get_ticks_usec()

		var package_node := _package.instantiate()
		if flags & FLAG_AUTO_VISIBLE_CHILDREN != 0:
			package_node.visible = false
		_package_node = package_node
		save_group(group_etag)
		add_child(_package_node)
		restore_group()

		delta = Time.get_ticks_usec() - start
		
		if get_navigation_verbose():
			print("\tPackage tree [", group_etag, "]: ", _package_path, ", ", delta / 1000.0, "msec")

func _post_exit_path(group_etag: int) -> void:
	match _auto_free:
		AUTO_FREE_NODE, \
		AUTO_FREE_NODE_AND_PACKAGE:
			if _package_node != null:
				save_group(group_etag)
				remove_child(_package_node)
				restore_group()
				_package_node.queue_free()
			_package_node = null

	match _auto_free:
		AUTO_FREE_NODE_AND_PACKAGE:
			_package = null

func _to_string() -> String:
	return "<PackageRoute#%s>" % _route_segment
