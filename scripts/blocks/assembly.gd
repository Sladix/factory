class_name Assembly extends Polygon2D

signal move_error(assembly:Assembly)

@onready var area = $Area2D

var is_moving = false
var tweens = []

func _ready():
	area.area_shape_entered.connect(_on_collision);
	update_polygons()

func get_resources():
	var blocks = []
	for r in get_children():
		if r is ResourceBlock:
			blocks.append(r)
	return blocks

func translate_polygon(r: ResourceBlock):
	var translated: PackedVector2Array = []
	for p in r.polygon:
		translated.append(p + r.position)
		# store the color somehow ?
	return translated

func update_polygons():
	var merged: PackedVector2Array = []
	for r in get_resources():
		var translated = translate_polygon(r)
		merged += translated
		
	polygon = Geometry2D.convex_hull(merged)
	var colors = {}
	for p in polygon:
		var target = null
		for r: ResourceBlock in get_resources():
			if Geometry2D.is_point_in_polygon(p, r.polygon):
				if colors.get(p):
					colors[p] = colors[p].lerp(r._color, 0.5)
				else:	
					colors[p] = r._color
	vertex_colors = PackedColorArray(colors.values())
	# Update the colors accoring to their place within the child resources
	

func move(direction: Vector2):
	if is_moving:
		return
	is_moving = true
	var _can_move = true
	for r in get_resources():
		if !can_move(r.global_position, direction):
			_can_move = false
			break
	if (_can_move):
		var next_block = get_next_assembly_to_move(direction)
		if next_block and next_block is Assembly and next_block != self:
			next_block.move(direction)
		
		remove_pos()
		var target = position + direction * GridManager.cell_size
		await make_tween("position", target)
		add_pos()
		
	else:
		dispatch_move_eror()
	is_moving = false

func remove_pos():
	for r in get_children():
		if r is ResourceBlock:
			GridManager.remove_resource(r.global_position)

func add_pos():
	GridManager.add_block(self)

# 1 = clockwise, -1 = counterClock
func do_rotate(direction: int):
	remove_pos()
	await make_tween("rotation", rotation + PI/2.0 * direction)
	add_pos()

func make_tween(property, value):
	var t = create_tween()
	tweens.push_back(t)
	t.tween_property(self, property, value, Ticker.tick_duration - 0.01)	
	await t.finished
	tweens.erase(t)
	

func _on_collision(_area_rid: RID, _area: Area2D, _area_shape_index: int, _local_shape_index: int):
	var parent = _area.get_parent()
	if not parent is Block:
		return
	
	if parent.is_blocking():
		dispatch_move_eror()

func dispatch_move_eror():
	move_error.emit(self)
	is_moving = false

func stop():
	for t in tweens:
		t.kill()

func can_move(_position:Vector2, direction: Vector2):
	var next_block = get_next_assembly(_position, direction)
	if next_block == self:
		return can_move(_position, direction+direction.normalized())
	return null == next_block or (next_block is Assembly and next_block.can_move(_position, direction)) or !next_block.is_blocking()

func get_next_assembly(_position:Vector2, direction:Vector2):
	return GridManager.get_resource(_position + direction * GridManager.cell_size)

func get_next_assembly_to_move(direction: Vector2):
	var next_assembly = null
	for r in get_resources():
		next_assembly = get_next_assembly(r.global_position, direction)
		if next_assembly is Assembly and next_assembly != self:
			break
	return next_assembly
