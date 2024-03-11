class_name Rotator extends Block

@export var direction = 1 # 1 is clockwise, -1 is counter clockwise

@onready var rotator = $Rotator

var last_rotated = null # Rotates each block only once

func is_blocking() -> bool:
	return false

func tick():
	var r:Assembly = GridManager.get_resource(global_position)
	if r and last_rotated != r:
		rotator.rotation = 0
		var parent = r.get_parent()
		r.reparent(rotator)
		await r.do_rotate(direction, rotator)
		r.reparent(parent)
		last_rotated = r
