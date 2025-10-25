extends AnimatedSprite2D
class_name Plant

@export var health:int = 50
@export var plant_stages:int = 3
@export var drink_timer:int = 5
@export_multiline var item_description : String
@export var water_usage = 0
@export var _plant_original: Plant

var _active_time: float = 0.0
var _time_until_next_water_drink: float = 0.0

var second_life_used:bool = false
var water:bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if process_mode == PROCESS_MODE_DISABLED:
		while true:
			await get_tree().process_frame
			if process_mode != PROCESS_MODE_DISABLED:
				break
	
	frame = 0
	on_start_grow()
	on_plant_ready()
	
	_time_until_next_water_drink = drink_timer
	
	set_process(true)

func on_start_grow():
	pass
	
func on_plant_ready():
	pass
	
func death():
	if second_life_used == true or frame == 0:
		queue_free()
	else:
		frame = frame - 1
		second_life_used = true

func _process(delta: float) -> void:
	_active_time += delta
	_time_until_next_water_drink = max(_time_until_next_water_drink - delta, 0.0)
	if _time_until_next_water_drink == 0.0:
		_on_drink_tick()
		_time_until_next_water_drink = drink_timer
		
func _on_drink_tick() -> void:
	if water:
		pass
	else:
		if second_life_used:
			death()
		else:
			death()
	
