extends Plant
class_name ProducerPlant

signal plant_finished_growing(frame_ended: int)

var regen:int = 0
var harvest:int = 0
@export var grow_duration:int = 15
var _grow_thread: Thread

func on_start_grow():
	_grow_thread = Thread.new()
	_grow_thread.start(_grow)
	
func _grow():
	while true:
		await get_tree().create_timer(grow_duration).timeout
		frame = min(frame + 1, plant_stages - 1)
		if frame == plant_stages - 1:
			break
			
	plant_finished_growing.emit()
	
func _exit_tree():
	if _grow_thread:
		_grow_thread.wait_to_finish()


#aura points
func _process(delta: float) -> void:
	pass
