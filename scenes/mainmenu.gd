extends Control

@onready var buttons = $Play

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for button: Button in buttons.get_children():
		button.pressed.connect(func(): go_to_scene(button.name))

func go_to_scene(name: String):
	get_tree().change_scene_to_file("res://scenes/" + name + ".tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
