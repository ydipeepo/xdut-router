class_name MotionRouteValueBase extends Resource

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

## アニメーションを開始するまでの遅延。
@export_range(0.0, 60.0, 0.1, "or_greater", "suffix:s") var delay := 0.0

## アニメーションを処理するフレームタイプ。
@export_enum("Default", "Physics") var process: int = XDUT_MotionTimer.PROCESS_DEFAULT

## パスに一致したとき初期値を継承するかどうか。
@export var inherit_value_before_enter: bool = false

## パスから外れたとき初期値を継承するかどうか。
@export var inherit_value_before_exit: bool = true

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func get_value_before_enter() -> Variant:
	#
	# 継承先で実装します。
	#

	assert(false)
	return null

func get_value() -> Variant:
	#
	# 継承先で実装します。
	#

	assert(false)
	return null

func get_value_after_exit() -> Variant:
	#
	# 継承先で実装します。
	#

	assert(false)
	return null
