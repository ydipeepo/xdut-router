class_name XDUT_RouteTransitionQueue

#-------------------------------------------------------------------------------
#	PROPERTIES
#-------------------------------------------------------------------------------

var route_node: Node:
	get:
		return _route_node

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

func enqueue_enter_transition(
	route_invocation_group: XDUT_RouteInvocationGroup,
	route_params: Dictionary,
	force: bool) -> void:

	_last_route_transition.cancel()
	_last_route_transition = XDUT_RouteEnterTransition.new(
		_last_route_transition,
		_route_node,
		route_params,
		route_invocation_group,
		force)

func enqueue_exit_transition(route_invocation_group: XDUT_RouteInvocationGroup) -> void:
	_last_route_transition.cancel()
	_last_route_transition = XDUT_RouteExitTransition.new(
		_last_route_transition,
		_route_node,
		route_invocation_group)

#-------------------------------------------------------------------------------

var _route_node: Node
var _last_route_transition: XDUT_RouteTransition = XDUT_RouteEmptyTransition.new()

func _init(route_node: Node) -> void:
	assert(route_node != null)

	_route_node = route_node
