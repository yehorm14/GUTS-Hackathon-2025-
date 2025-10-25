extends Node

@onready var map: TileMapLayer = get_parent().get_node("Map")
@onready var plants: Node2D = get_parent().get_node("Plants")
@onready var hud: Control = get_parent().get_node("HUD")
@onready var inventoryUI: HBoxContainer = get_parent().get_node("HUD").get_node("InventoryUI")
@onready var cursor: Sprite2D = get_parent().get_node("Cursor")

var inventory := InventoryContainer.new(
	[
		InventoryButton.new(),
		InventoryButton.new(),
		InventoryButton.new(),
		InventoryButton.new(),
		InventoryButton.new(),
	]
)

var selected : Node
var selector : Node
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	for index in range(5):
		var inv_button: InventoryButton = inventory.slots.get(index)
		var ui = inventoryUI.get_node(str(index))
		inv_button.set_button(ui, seed_selected)
	
	var inv_button = inventory.slots.get(0)
	inv_button.seed = load("res://plants/sunflower.tscn").instantiate()
	inv_button.amount = 3
	
func seed_selected(seed: Plant):
	if !seed:
		if selected:
			selected.queue_free()
		return
	selected = seed.duplicate()
	selected.frame = 0
	plants.add_child(selected)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mouse_pos_global = get_viewport().get_mouse_position()
	var mouse_pos_local = map.to_local(mouse_pos_global)
	var tile_pos = map.local_to_map(mouse_pos_local)
	if !selected: return
	selected.position = tile_pos * 16
	cursor.position = tile_pos * 16
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print("Mouse Click/Unclick at: ", event.position)
