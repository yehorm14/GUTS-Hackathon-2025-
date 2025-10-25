extends AnimatedSprite2D
class_name Plant

@export var grow_duration:int = 15

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	while true:
		await get_tree().create_timer(grow_duration).timeout
		frame = min(frame + 1, 2)
		print(frame)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
