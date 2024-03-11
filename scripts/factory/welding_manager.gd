extends Node

var welder_line = preload("res://scenes/blocks/fx/welder_line.tscn")

var welder_groups = []  # List to store group IDs for each welder
var welder_to_group = {}  # Dictionary to map welders to group IDs
var welder_map = {}  # Dictionary to hold welder positions (grid based)

signal welder_group_updated(group: Array)
signal welder_group_removed(group: Array)

var factory

func _ready():
	factory = $"/root/Factory"

# Resets all the data structures
func reset():
	welder_map = {}
	welder_groups = []
	welder_to_group = {}

# Checks if a welder is connected to any welder in a group
func are_welders_connected(welder: Welder, group: Array):
	for group_welder in group:
		var neighbors = find_neighbors(welder)
		if group_welder in neighbors:
			return true
	return false

# Removes a group and its associated line
func remove_group(group: Array):
	welder_groups.erase(group)
	welder_group_removed.emit(group)


# Updates a group by removing and recreating its line
func update_group(group: Array):
	welder_group_updated.emit(group)

# Finds the neighbors of a block
func find_neighbors(block: Block):
	var neighbors = []
	var bPos = GridManager.normalize_pos(block.target_point())
	var left = welder_map.get(bPos - Vector2(1,0))
	var right = welder_map.get(bPos + Vector2(1,0))
	var top = welder_map.get(bPos - Vector2(0,1))
	var bottom = welder_map.get(bPos + Vector2(0,1))
	for n in [left, right, top, bottom]:
		if n:
			neighbors.append(n)
	return neighbors

# Finds the groups adjacent to a building of a certain type
func find_adjacent_groups(building: Block, type: Script):
	var groups = []
	var neighbors = find_neighbors(building)
	for b in neighbors:
		if !b:
			continue
		if b.get_script() == type:
			if !groups.has(welder_to_group[b]):
				groups.append(welder_to_group[b])
	return groups

# Removes a welder and updates the groups
func remove_welder(welder: Welder):
	var group = welder_to_group.get(welder)
	if !group:
		return
	remove_group(group)
	welder_map.erase(GridManager.normalize_pos(welder.target_point()))
	welder_to_group.erase(welder)
	var new_groups = []
	for group_welder in group:
		if !group_welder:
			return
		var placed = false
		for new_group in new_groups:
			if are_welders_connected(group_welder, new_group):
				new_group.append(group_welder)
				welder_to_group[group_welder] = new_group
				placed = true
				break
		if not placed:
			var new_group = [group_welder]
			new_groups.append(new_group)
			welder_to_group[group_welder] = new_group

	welder_groups += new_groups
	for new_group in new_groups:
		update_group(new_group)

# Adds a welder and updates the groups
func add_welder(building: Block):
	var adjacent_groups = find_adjacent_groups(building, Welder)
	welder_map[GridManager.normalize_pos(building.target_point())] = building
	
	if adjacent_groups.size() > 1:
		# Merge the different groups
		var new_group = [building]
		for g in adjacent_groups:
			new_group += g
			welder_groups.erase(g)
		for b in new_group:
			welder_to_group[b] = new_group
		welder_groups.append(new_group)
		update_group(new_group)
	elif adjacent_groups.size() == 1:
		var group = adjacent_groups.front()
		group.append(building)
		welder_to_group[building] = group
		update_group(group)
	else:
		# Create a new group for the building
		var new_group = [building]
		welder_groups.append(new_group)
		welder_to_group[building] = new_group
		update_group(new_group)

# Checks for connected assemblies inside groups and merges them
func tick_welders():
	for g in welder_groups:
		var assemblies_to_merge = []
		for w: Welder in g:
			var a = w.get_resource()
			if a:
				if !assemblies_to_merge.has(a):
					assemblies_to_merge.append(a)
				# check if assembly has neighbors in this welder group that is not part of it's assembly
				for r in a.get_resources():
					var neighbors = GridManager.find_neighbors_resources(r.global_position)
					for n in neighbors:
						var target_welder = welder_map.get(GridManager.normalize_pos(n.global_position))
						if target_welder and n != a and welder_to_group.get(target_welder) == g:
							if !assemblies_to_merge.has(n):
								assemblies_to_merge.append(n)
		if assemblies_to_merge.size() > 1:
			merge_assemblies(assemblies_to_merge)

# Merges assemblies in a group
func merge_assemblies(group):
	var first: Assembly = group[0]
	for i in range(1,group.size()):
		var assembly: Assembly = group[i]
		assembly.remove_pos()
		var nodes = assembly.get_children()
		for n in nodes:
			if n is ResourceBlock:
				n.reparent(first)
		assembly.queue_free()
	first.remove_pos()
	first.add_pos()
	first.update_polygons()
