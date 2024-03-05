class_name Dispenser extends Block

signal spawn_resource(dispenser: Dispenser)

@export var spawn_every = 5
var current_tick = 0;

func tick():
	current_tick += 1
	if current_tick == spawn_every:
		spawn_resource.emit(self)
		current_tick = 0

func reset():
	current_tick = 4
