class_name Router

#-------------------------------------------------------------------------------
#	CONSTANTS
#-------------------------------------------------------------------------------

enum {
	## 排他遷移させます。[br]
	## [br]
	## ここでの排他遷移とは、[code]_exit_path[/code] と [code]_pre_enter_path[/code] を同時に開始する遷移です。[br]
	## [code]_enter_path[/code] は前述の 2 呼び出しが終わると開始されます。
	FLAG_EXCLUSIVE = 0x01,
}

#-------------------------------------------------------------------------------
#	SIGNALS
#-------------------------------------------------------------------------------

## ナビゲーションを開始すると呼び出されます。
static var navigate: Signal:
	get:
		var canonical := _get_canonical()
		if canonical == null:
			printerr("XDUT Router is not activated.")
			return Signal()

		return canonical.navigate

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

## 現在のパスを取得します。
static var current_path: String:
	get:
		var canonical := _get_canonical()
		if canonical == null:
			printerr("XDUT Router is not activated.")
			return "?"

		return canonical.get_current_path()

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

## 指定したノードが属するルートを取得します。
static func get_route(route: Node) -> String:
	var canonical := _get_canonical()
	if canonical == null:
		printerr("XDUT Router is not activated.")
		return "?"

	return "/" + "/".join(XDUT_RouteHelper.get_route_segments(route))

## ルート (Route) ノードを登録します。
static func register(
	route: Node,
	route_segment: String,
	flags := 0) -> Awaitable:

	var canonical := _get_canonical()
	if canonical == null:
		printerr("XDUT Router is not activated.")
		return Task.canceled()

	return canonical.register(route, route_segment, flags)

## ルート (Route) ノードの登録を解除します。
static func unregister(
	route: Node,
	flags := 0) -> Awaitable:

	var canonical := _get_canonical()
	if canonical == null:
		printerr("XDUT Router is not activated.")
		return Task.canceled()

	return canonical.unregister(route, flags)

## 指定したパスへ移動します。[br]
## [br]
## 直前のパスはメモリに保持され [method back] により復帰することができます。
static func goto(
	path: String,
	flags := 0) -> Awaitable:

	var canonical := _get_canonical()
	if canonical == null:
		printerr("XDUT Router is not activated.")
		return Task.canceled()

	return canonical.goto(path, flags)

## 指定したパスへ置換します。[br]
## [br]
## 直前のパスはメモリから破棄されます。
static func replace(
	path: String,
	flags := 0) -> Awaitable:

	var canonical := _get_canonical()
	if canonical == null:
		printerr("XDUT Router is not activated.")
		return Task.canceled()

	return canonical.replace(path, flags)

## 現在のパスを再読み込みします。
static func reload(flags := 0) -> Awaitable:
	var canonical := _get_canonical()
	if canonical == null:
		printerr("XDUT Router is not activated.")
		return Task.canceled()

	return canonical.reload(flags)

## 一つ前のパスへ復帰できるかどうかを返します。
static func can_back() -> bool:
	var canonical := _get_canonical()
	if canonical == null:
		printerr("XDUT Router is not activated.")
		return false

	return canonical.can_back()

## 一つ前のパスへ復帰します。
static func back(flags := 0) -> Awaitable:
	var canonical := _get_canonical()
	if canonical == null:
		printerr("XDUT Router is not activated.")
		return Task.canceled()

	return canonical.back(flags)

#-------------------------------------------------------------------------------

static var _canonical: Node

static func _get_canonical() -> Node:
	if not is_instance_valid(_canonical):
		_canonical = Engine \
			.get_main_loop() \
			.root \
			.get_node("/root/XDUT_RouterCanonical")
	return _canonical
