@icon("PackageRoute3D.png")
class_name PackageRoute3D extends Route3D

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

signal _enter_barrier

var _auto_free: int = AUTO_FREE_NODE_AND_PACKAGE
var _package_path: String
var _package_node: Node
var _package: PackedScene
var _pre_enter_task: Task
var _pre_enter_entries: int
var _enter_entries: int

#
# NOTE:
# 短期間の内に呼び出しグループを跨いだパステストが複数回発生すると
# _pre_enter_path で発生する遅延により _enter_path、_exit_path の
# 呼び出し順序が破綻してしまうことがあります:
#
#                                      この _pre_enter_path による await 期間が原因となり
#                 |~~~~~~~~~~~~~~| <== 後続する _enter_path がずれ込む。
#                 :              :     通常の Route では発生しません。
#
# IGroup #1: C----*--------------*----- - - ->
#                 |              |
#                 |              +----[_enter_path]
#                 |
#                 +-------------------[_pre_enter_path]
#
# IGroup #2: C----*----*--------------- - - ->
#                 |    |
#                 |    +--------------[_post_exit_path]
#                 |
#                 +-------------------[_exit_path]
#
#                                   1) _pre_entre_path
#                                   2) _exit_path
#                                   3) _post_exit_path
#                                   4) _enter_path
#
# ここでは呼び出しグループが異なるため呼び出しグループのみでは
# 順序整合性を担保できません。破綻した呼び出しを検知した場合に
# バリア用シグナルを待機し正しい順序となるよう _exit_path を
# オフセットすることで対処します:
#
#                 |~~~~~~~~>| <======= バリアによるオフセット。
#                 :         :
#
# IGroup #1: C----*----*---<B>--------- - - ->
#                 |    |    :
#                 |    +----/---------[_enter_path]
#                 |         :
#                 +---------/---------[_pre_enter_path]
#                           :
# IGroup #2: C--------------*----*----- - - ->
#                           |    |
#                           |    +----[_post_exit_path]
#                           |
#                           +---------[_exit_path]
#
#                                   1) _pre_entre_path
#                                   2) _enter_path
#                                   3) _exit_path
#                                   4) _post_exit_path
#

func _pre_enter_path_core(
	route_params: Dictionary,
	group_etag: int) -> void:

	var start: int
	var delta: int

	#
	# パッケージ読み込み
	#

	if _package == null:
		assert(_package_node == null)

		start = Time.get_ticks_usec()

		var package: PackedScene = await Task \
			.load(_package_path, &"PackedScene") \
			.wait()
		if package == null:
			printerr("Failed to load the package: ", _package_path)
			return
		_package = package

		delta = Time.get_ticks_usec() - start
		if get_navigation_verbose():
			print("\tPackage load [", group_etag, "]: ", _package_path, ", ", delta / 1000.0, "msec")

	#
	# パッケージ追加
	#

	if _package_node == null:
		assert(_package != null)

		start = Time.get_ticks_usec()

		_package_node = _package.instantiate()
		if flags & FLAG_AUTO_VISIBLE_CHILDREN != 0:
			_package_node.visible = false
		save_group(group_etag)
		add_child(_package_node)
		restore_group()

		delta = Time.get_ticks_usec() - start
		if get_navigation_verbose():
			print("\tPackage tree [", group_etag, "]: ", _package_path, ", ", delta / 1000.0, "msec")

func _pre_enter_path(
	route_params: Dictionary,
	group_etag: int) -> void:

	if _pre_enter_entries == 0:
		_pre_enter_task = Task \
			.from_method(_pre_enter_path_core.bind(route_params, group_etag))

	_pre_enter_entries += 1

	assert(_pre_enter_task != null)
	await _pre_enter_task.wait()

func _enter_path(route_params: Dictionary) -> void:
	assert(_pre_enter_task != null)
	await _pre_enter_task.wait()

	var barrier := _enter_entries < 0
	_enter_entries += 1

	await super(route_params)

	if barrier:
		_enter_barrier.emit()

func _exit_path() -> void:
	assert(_pre_enter_task != null)
	await _pre_enter_task.wait()

	_enter_entries -= 1

	if _enter_entries < 0:
		await _enter_barrier

	await super()

func _post_exit_path(group_etag: int) -> void:
	assert(_pre_enter_task != null)
	await _pre_enter_task.wait()

	_pre_enter_entries -= 1

	if _pre_enter_entries == 0:
		match _auto_free:
			AUTO_FREE_NODE, \
			AUTO_FREE_NODE_AND_PACKAGE:
				save_group(group_etag)
				remove_child(_package_node)
				restore_group()

				_package_node.queue_free()
				_package_node = null

		match _auto_free:
			AUTO_FREE_NODE_AND_PACKAGE:
				_package = null

		_pre_enter_task = null

func _to_string() -> String:
	return "<PackageRoute3D#%s>" % _route_segment
