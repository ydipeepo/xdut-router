class_name XDUT_RouteTransition

#-------------------------------------------------------------------------------
#	CONSTANTS
#-------------------------------------------------------------------------------
	
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

func cancel() -> void:
	pass
