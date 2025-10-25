extends AnimatedSprite2D
class_name Plant

signal plant_finished_growing(frame_ended: int)

@export var plant_stages:int = 3
@export var grow_duration:int = 15
@export var drink_timer:int = 5
@export_multiline var item_description : String


var health:int = 50
var second_life_used:bool = false
var water:bool = true


var _grow_thread: Thread
var _water_thread: Thread

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if process_mode == PROCESS_MODE_DISABLED:
		while true:
			await get_tree().process_frame
			if process_mode != PROCESS_MODE_DISABLED:
				break
	
	frame = 0
	on_plant_ready()
	
	_grow_thread = Thread.new()
	_grow_thread.start(_grow)
	_water_thread = Thread.new()
	_water_thread.start(_drink)
		
func _grow():
	while true:
		await get_tree().create_timer(grow_duration).timeout
		frame = min(frame + 1, plant_stages - 1)
		if frame == plant_stages - 1:
			break
			
	plant_finished_growing.emit()
	
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
			
	
func _exit_tree():
	if _grow_thread:
		_grow_thread.wait_to_finish()
			
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
	
