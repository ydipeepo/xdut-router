class_name Vector2MotionRouteValue extends MotionRouteValueBase

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

## パスに一致した場合の初期位置。
@export var value_before_enter: Vector2

## パスに一致した場合の最終位置、パスから外れた場合の初期位置。
@export var value: Vector2

## パスから外れた場合の最終位置。
@export var value_after_exit: Vector2

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func get_value_before_enter() -> Variant:
	return value_before_enter

func get_value() -> Variant:
	return value

func get_value_after_exit() -> Variant:
	return value_after_exit
