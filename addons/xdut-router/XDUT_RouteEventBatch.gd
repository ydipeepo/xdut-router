class_name XDUT_RouteEventBatch

#
# NOTE:
# ナビゲーション毎の一連のイベントをバッファします。(_enter_path, _exit_path など)
# トランザクションにより追加されるイベント呼び出しをディスパッチャに中継する役割を持ちます。
#
# 例えばパッケージルートがネストされている場合、リソースローダーによる遅延 (await する箇所) を含むため、
# ロード + ツリー操作 -> ロード (未知のルート) + ツリー操作 -> ... といった様に
# ナビゲーションによるイベント呼び出しはフレームを跨いで断続的に発生します。
# これは実行時にナビゲーションが完了するまでどのようなトランザクションが発行されるか確認する手段が無いことを意味します。
# このクラスはそれら呼び出しを特定のディスパッチャに確実に中継します。
#

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

#
# NOTE:
# ETag はナビゲーション毎に発行されるバッチを特定するためのタグです。
# 平行して処理されているナビゲーションとバッチを関連付けるために使われます。
#

var etag: int:
	get:
		return _etag

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

#
# NOTE:
# ディスパッチャが視覚的な (アニメーションなどの) 整合性を保ったまま他のルートと協調して遷移を行えるよう、
# ナビゲーションイベントは 4 段階に分かれています。
# これらは以下のルールの下正しく呼び出されるよう保証されます:
#
# トランザクション (とルートラッパー) により、ルート毎に
# 1: _pre_enter_path
# 2: _enter_path
# 3: _exit_path
# 4: _post_exit_path の順で
# 呼び出すことが保証されます。
#
# ディスパッチャにより、ナビゲーションによる
# A: 一連の _pre_enter_path が完了後、一連の _enter_path を、
# B: 一連の _exit_path が完了後、一連の _post_exit_path を
# 呼び出し、バッチを処理し切ることが保証されます。(A と B はナビゲーション内で平行することがあります)
#

func append_pre_enter_path(init: Variant) -> void:
	_pre_enter_path_calls.push_back(init)

func append_enter_path(init: Variant) -> void:
	_enter_path_calls.push_back(init)

func append_exit_path(init: Variant) -> void:
	_exit_path_calls.push_back(init)

func append_post_exit_path(init: Variant) -> void:
	_post_exit_path_calls.push_back(init)

func bundle_pre_enter_path(calls: Array) -> void:
	calls.append_array(_pre_enter_path_calls); _pre_enter_path_calls.clear()

func bundle_enter_path(calls: Array) -> void:
	calls.append_array(_enter_path_calls); _enter_path_calls.clear()

func bundle_exit_path(calls: Array) -> void:
	calls.append_array(_exit_path_calls); _exit_path_calls.clear()

func bundle_post_exit_path(calls: Array) -> void:
	calls.append_array(_post_exit_path_calls); _post_exit_path_calls.clear()

#-------------------------------------------------------------------------------

var _etag: int
var _pre_enter_path_calls: Array
var _enter_path_calls: Array
var _exit_path_calls: Array
var _post_exit_path_calls: Array

func _init(etag: int) -> void:
	_etag = etag
