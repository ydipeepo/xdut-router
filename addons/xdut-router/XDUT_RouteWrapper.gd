class_name XDUT_RouteWrapper

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

var route_node: Node:
	get:
		return _route_node

var route_matcher: XDUT_RouteMatcher:
	get:
		return _route_matcher

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func enter(
	route_event_batch: XDUT_RouteEventBatch,
	route_params: Dictionary,
	is_reentry: bool) -> void:

	assert(
		_route_transaction is XDUT_RouteEnterEventTransaction and is_reentry or
		_route_transaction is XDUT_RouteExitEventTransaction or
		_route_transaction is XDUT_RouteEmptyTransaction)

	_route_transaction.abort()
	_route_transaction = XDUT_RouteEnterEventTransaction.new(
		_route_transaction,
		route_event_batch,
		_route_node,
		route_params,
		is_reentry)

func exit(route_event_batch: XDUT_RouteEventBatch) -> void:
	assert(_route_transaction is XDUT_RouteEnterEventTransaction)

	_route_transaction.abort()
	_route_transaction = XDUT_RouteExitEventTransaction.new(
		_route_transaction,
		route_event_batch,
		_route_node)

func mark_node() -> void:
	XDUT_RouteHelper.set_route_wrapper(_route_node, self)

func unmark_node() -> void:
	XDUT_RouteHelper.remove_route_wrapper(_route_node)

#-------------------------------------------------------------------------------

var _route_matcher: XDUT_RouteMatcher
var _route_node: Node
var _route_transaction: XDUT_RouteTransaction = XDUT_RouteEmptyTransaction.new()

func _init(
	route_matcher: XDUT_RouteMatcher,
	route_node: Node) -> void:

	assert(route_node != null)
	assert(route_matcher != null)

	_route_matcher = route_matcher
	_route_node = route_node
