class_name UI extends CanvasLayer

var selected_building

signal place_building(position:Vector2, rotation:float, type: BuildingsManager.BuildingType)
signal remove_building(position:Vector2)
signal reset
signal restart
signal play

var current_building_type = BuildingsManager.BuildingType.NONE
var shadow_el
var shadow_rotation = 0
var can_build = false

func select_building(type: BuildingsManager.BuildingType):
	if !can_build:
		return
	unselect()
	current_building_type = type
	shadow_el = BuildingsManager.spawn_shadow(current_building_type)
	add_child(shadow_el)
	pass

func unselect():
	shadow_rotation = 0
	if shadow_el:
		shadow_el.queue_free()
		shadow_el = null
	current_building_type = BuildingsManager.BuildingType.NONE

func select_conveyor():
	select_building(BuildingsManager.BuildingType.CONVEYOR)

func select_rotator():
	select_building(BuildingsManager.BuildingType.ROTATOR)

func select_welder():
	select_building(BuildingsManager.BuildingType.WELDER)

func _on_reset():
	reset.emit()

func _on_restart():
	restart.emit()

func _on_play():
	play.emit()

func rotate_shadow():
	if !shadow_el:
		return
	shadow_rotation += PI/2
	create_tween().tween_property(shadow_el, "rotation", shadow_rotation, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _unhandled_input(event):
	if !can_build:
		return
	if current_building_type != BuildingsManager.BuildingType.NONE and event is InputEventMouseButton and event.get_button_index() == MOUSE_BUTTON_LEFT and event.is_released():
		if can_place_building(event.position):
			place_building.emit(event.position, shadow_rotation, current_building_type)
	
	if Input.is_action_just_released("Rotate"):
		rotate_shadow()
	
	if event is InputEventMouseButton and event.get_button_index() == MOUSE_BUTTON_RIGHT and event.is_released():
		if (current_building_type == BuildingsManager.BuildingType.NONE):
			remove_building.emit(event.position)
		else:
			unselect()

func _process(_delta):
	if shadow_el:
		# additional logic to change the color if we can't place the building
		shadow_el.position = GridManager.center_from_viewport(get_viewport().get_mouse_position())
		if !can_place_building(shadow_el.position):
			shadow_el.modulate = Color(1,0,0,0.5)
		else:
			shadow_el.modulate = Color(1,1,1,0.5)

func disable_build():
	unselect()
	# update the UI to a disabled state
	can_build = false

func enable_build():
	# update the UI to an enabled state
	can_build = true

func can_place_building(p:Vector2):
	return GridManager.get_building(p) == null
