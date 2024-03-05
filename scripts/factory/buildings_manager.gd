extends Node2D

@onready var conveyor_block = preload("res://scenes/blocks/conveyor.tscn")
@onready var rotator_block = preload("res://scenes/blocks/rotator.tscn")
@onready var welder_block = preload("res://scenes/blocks/welder.tscn")

enum BuildingType {CONVEYOR, SCULPTOR, PAINTER, WELDER, ROTATOR, NONE}

var mapper = {
	BuildingType.CONVEYOR: func (): return conveyor_block.instantiate(),
	BuildingType.ROTATOR: func (): return rotator_block.instantiate(),
	BuildingType.WELDER: func (): return welder_block.instantiate(),
}

func reset():
	GridManager.reset_buildings()
	WeldingManager.reset()

func spawn_building(p:Vector2, r:float, type: BuildingType):
	var buildling = mapper[type].call()
	buildling.position = GridManager.center_from_viewport(p)
	buildling.rotation = r
	GridManager.add_block(buildling)
	$"/root/Factory".add_child(buildling)
	if buildling is Welder:
		WeldingManager.add_welder(buildling)
	return buildling

func remove_building(p:Vector2):
	var block = GridManager.get_building(p)
	if block != null and not block is Dispenser:
		if block is Welder:
			WeldingManager.remove_welder(block)
		block.queue_free()
		GridManager.remove_buildling(p)
	return block

func spawn_shadow(type: BuildingType):
	var el = mapper[type].call()
	el.modulate = Color(1,1,1,0.5)
	return el
