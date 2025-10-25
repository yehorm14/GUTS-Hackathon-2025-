extends Plant
class_name ProducerPlant

signal plant_finished_growing(frame_ended: int)

var regen:int = 0
var harvest:int = 0
@export var grow_duration:int = 15

var _time_until_next_growth:float = 1.0
var _active_grow_time:float = 0.0

func on_start_grow():
	_time_until_next_growth = grow_duration
	_active_grow_time = 0.0

#aura points
func _process(delta: float) -> void:
	super(delta)
	
	if frame >= plant_stages - 1:
		return

	_active_grow_time += delta
	_time_until_next_growth = max(_time_until_next_growth - delta, 0.0)
	
	if _time_until_next_growth == 0.0:
		frame = min(frame + 1, plant_stages - 1)
		if frame < plant_stages - 1:
			_time_until_next_growth = grow_duration
			_active_grow_time = 0.0
		else:
			plant_finished_growing.emit(frame)
