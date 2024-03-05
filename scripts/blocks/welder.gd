class_name Welder extends Block

@onready var welding_point = $WeldingPoint

func is_blocking() -> bool:
	return true

func reset():
	pass

func get_resource():
	return GridManager.get_resource(target_point())

func target_point():
	return welding_point.global_position

func tick():
	pass
