class_name Conveyor extends Block


func is_blocking() -> bool:
	return false

func tick():
	var r: Assembly = GridManager.get_resource(position)
	if r:
		r.move(Vector2.UP.rotated(rotation))
