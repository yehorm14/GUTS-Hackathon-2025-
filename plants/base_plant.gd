extends AnimatedSprite2D
class_name Plant

signal plant_finished_growing(frame_ended: int)

@export var plant_stages:int = 3
@export var grow_duration:int = 15
var health:int = 50
var second_life_used:bool = false
var water:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	frame = 0
	on_plant_ready()
	
	while true:
		await get_tree().create_timer(grow_duration).timeout
		frame = min(frame + 1, plant_stages - 1)
		if frame == plant_stages - 1:
			break
		
	plant_finished_growing.emit()
	
func on_plant_ready():
	pass

func _process(delta: float) -> void:
	pass
