extends AnimatedSprite2D
class_name Plant

@export var grow_duration:int = 15
var accumulator:float = 0
var grown_debounce:bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	frame = 0 # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	accumulator += delta
	if (int((accumulator)) % grow_duration) == 0 and accumulator != 0:
		if grown_debounce == true and int(accumulator) % grow_duration == 1:
			grown_debounce = false
		frame = min(frame + 1,2)
		grown_debounce = true
		accumulator = 0
