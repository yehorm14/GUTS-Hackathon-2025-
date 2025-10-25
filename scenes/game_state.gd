extends Node

@onready var map: TileMapLayer = get_parent().get_node("Map")
@onready var plants: Node2D = get_parent().get_node("Plants")
@onready var ui: Control = get_parent().get_node("UI")

var a := preload("res://plants/carrot.tscn")
var b : Node
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	b = a.instantiate()
	plants.add_child(b)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_pos_global = get_viewport().get_mouse_position()
	var mouse_pos_local = map.to_local(mouse_pos_global)
	var tile_pos = map.local_to_map(mouse_pos_local)
	b.position = tile_pos * 16
	print("hi", tile_pos * 16)
	
