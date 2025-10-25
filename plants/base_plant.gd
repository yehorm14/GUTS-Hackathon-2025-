extends AnimatedSprite2D
class_name Plant

@export var plant_stages:int = 3
@export var drink_timer:int = 5
@export_multiline var item_description : String


var health:int = 50
var second_life_used:bool = false
var water:bool = true
var water_usage = 0

var _water_thread: Thread

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
	

	_water_thread = Thread.new()
	_water_thread.start(_drink)
		
	
func _drink():
	while true:
		await get_tree().create_timer(drink_timer).timeout
		if water: 		#need to add a check water function
			pass
		else:
			if second_life_used == true:
				death()
				break
			else:
				death()
			
	
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
	pass
	
