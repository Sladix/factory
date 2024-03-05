class_name Block extends Node2D

# Called when the node enters the scene tree for the first time.
func tick():
	pass

func is_blocking() -> bool:
	return true

func target_point():
	return global_position

func reset():
	pass
