class_name XDUT_RouteTransaction

#
# NOTE:
# ナビゲーションにより発生するルート毎の必要操作を表します。
# ナビゲーションにより変化が発生するルートはそれぞれひとつのトランザクションを生成します。
#

#-------------------------------------------------------------------------------
#	CONSTANTS
#-------------------------------------------------------------------------------

#
# NOTE:
# ここでのステートとはトランザクションの最終状態を表します。
# get_state は、ステートが確定 (トランザクションが完了) するまで待機するよう実装します。
#

enum {
	STATE_PRE_ENTERING,
	STATE_PRE_ENTERED,
	STATE_ENTERING,
	STATE_ENTERED,
	STATE_EXITING,
	STATE_EXITED,
	STATE_POST_EXITING,
	STATE_POST_EXITED,
}

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func get_state() -> int:
	assert(false)
	return -1

func abort() -> void:
	pass
