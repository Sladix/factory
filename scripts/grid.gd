class_name Grid extends Node

var resource_data = {}
var building_data = {}
var cell_size = 64

func reset_buildings():
	building_data = {}

func reset_resources():
	resource_data = {}

func add_block(b):
	if b is Assembly:
		for r in b.get_resources():
			add_resource(b, r.global_position)
	else:
		add_building(b, b.position)

func add_building(b:Block, p:Vector2):
	building_data[normalize_pos(p)] = b

func add_resource(b:Assembly, p:Vector2):
	resource_data[normalize_pos(p)] = b

func get_resource(p:Vector2):
	return resource_data.get(normalize_pos(p))

func get_building(p:Vector2):
	return building_data.get(normalize_pos(p))
	
func get_building_from_grid_pos(p:Vector2):
	return building_data.get(p)

func get_resource_from_grid_pos(p:Vector2):
	return resource_data.get(p)

func center_from_viewport(p:Vector2):
	return (normalize_pos(p) * cell_size) + Vector2(cell_size/2, cell_size/2)

func find_neighbors_resources(p:Vector2):
	var bPos = normalize_pos(p)
	var left = bPos - Vector2(1,0)
	var right = bPos + Vector2(1,0)
	var top = bPos - Vector2(0,1)
	var bottom = bPos - Vector2(0,1)
	var neighbors = []
	for n in [left, right, top, bottom]:
		if get_resource_from_grid_pos(n):
			neighbors.append(get_resource_from_grid_pos(n))
	return neighbors

func get_block(p:Vector2):
	var resource = get_resource(p)
	if resource:
		return resource
	var building = get_building(p)
	if building:
		return building
	return null

func remove_resource(p:Vector2):
	resource_data.erase(normalize_pos(p))

func remove_buildling(p:Vector2):
	building_data.erase(normalize_pos(p))

func normalize_pos(p:Vector2):
	return floor(p / cell_size)
