class_name Rotator extends Block

@export var direction = 1 # 1 is clockwise, -1 is counter clockwise

var last_rotated = null # Rotates each block only once

func is_blocking() -> bool:
	return false

func tick():
	var r = GridManager.get_resource(position)
	if r and last_rotated != r:
		r.do_rotate(direction)
		last_rotated = r
