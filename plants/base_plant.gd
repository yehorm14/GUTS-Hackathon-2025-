extends AnimatedSprite2D
class_name Plant

signal plant_finished_growing(frame_ended: int)

@export var plant_stages:int = 3
@export var grow_duration:int = 15

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	while true:
		await get_tree().create_timer(grow_duration).timeout
		frame = min(frame + 1, plant_stages - 1)
		if frame == plant_stages - 1:
			break
		
	plant_finished_growing.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
