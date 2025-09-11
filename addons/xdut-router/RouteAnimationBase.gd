@abstract
class_name RouteAnimationBase extends Resource

#-------------------------------------------------------------------------------
#	METHODS
#-------------------------------------------------------------------------------

@abstract
func animate_enter(route_node: Node, route_cancel: Cancel) -> void

@abstract
func animate_exit(route_node: Node, route_cancel: Cancel) -> void
