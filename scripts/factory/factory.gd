class_name Factory extends Node

var assemblies :Array[Assembly] = []
var blocks = [] # holds all the buildings
var resources = []
enum FactoryState {EDITING, RUNNING, PAUSED}

var current_state:
	set(value):
		if value == FactoryState.RUNNING:
			$UI.disable_build()
		elif value == FactoryState.EDITING:
			$UI.enable_build()
		current_state = value

var time_since_last_tick: float = 0
var on_error = false

const resource_group = "RESOURCES"
const building_group = "BUILDINGS"

@export var assembly_block: PackedScene
@onready var ui: UI = $UI


func _ready():
	ui.place_building.connect(spawn_building)
	ui.reset.connect(reset)
	ui.restart.connect(restart)
	ui.play.connect(play)
	ui.remove_building.connect(remove_building)
	register_existing_blocks()
	setEditingState()

func reset():
	delete_group(building_group)
	BuildingsManager.reset()
	reset_resources()
	setEditingState()

func play():
	reset_resources()
	match current_state:
		FactoryState.RUNNING:
			setEditingState()
		FactoryState.PAUSED:
			setEditingState()
		FactoryState.EDITING:
			start()

func delete_group(group: String):
	for e in get_tree().get_nodes_in_group(group):
		e.queue_free()

func reset_resources():
	delete_group(resource_group)
	GridManager.reset_resources()
	resources = []

func restart():
	reset_resources()
	start()

func start():
	register_existing_blocks()
	for b in blocks:
		b.reset()
	
	setRunningState()

func tick():
	WeldingManager.tick_welders()
	for b in blocks:
		b.tick()

func bootstrap():
	for b in blocks:
		b.init()

func register_existing_blocks():
	blocks = []
	for b in get_children():
		if b is Block and !b.is_queued_for_deletion():
			register_block(b)

func register_block(b:Block):
	if b is Dispenser and !b.is_connected("spawn_resource", spawn_resource):
		b.position = GridManager.center_from_viewport(b.position) # Reposition because setting the pos in the editor kind of hard
		b.spawn_resource.connect(spawn_resource)
	blocks.push_front(b);
	GridManager.add_block(b)

func spawn_resource(dispenser: Dispenser):
	var assembly = assembly_block.instantiate()
	add_child(assembly)
	assembly.add_to_group(resource_group)
	assembly.position = dispenser.position
	assemblies.push_back(assembly)
	assembly.move_error.connect(_on_move_error)
	GridManager.add_block(assembly)
	assembly.move(Vector2.UP.rotated(dispenser.rotation))
	resources.push_back(assembly)

func spawn_building(p:Vector2, r:float, t: BuildingsManager.BuildingType):
	var b: Block = BuildingsManager.spawn_building(p, r, t)
	b.add_to_group(building_group)
	blocks.push_front(b)

func remove_building(p:Vector2):
	var b = BuildingsManager.remove_building(p)
	blocks.erase(b)

func _on_move_error(assembly: Assembly):
	if on_error:
		return
	print("Move error at", GridManager.normalize_pos(assembly.position))
	setPausedState()
	for r in resources:
		r.stop()
	on_error = true

func setEditingState():
	on_error = false
	current_state = FactoryState.EDITING

func setPausedState():
	current_state = FactoryState.PAUSED

func setRunningState():
	on_error = false
	current_state = FactoryState.RUNNING

func _physics_process(delta):
	if current_state != FactoryState.RUNNING:
		return
	time_since_last_tick += delta
	if time_since_last_tick >= Ticker.tick_duration:
		tick()
		time_since_last_tick = 0
