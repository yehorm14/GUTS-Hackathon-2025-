extends Node

@onready var map: TileMapLayer = get_parent().get_node("Map")
@onready var plants: Node2D = get_parent().get_node("Plants")
@onready var hud: Control = get_parent().get_node("HUD")
@onready var inventoryUI: HBoxContainer = get_parent().get_node("HUD").get_node("InventoryUI")
@onready var cursor: Sprite2D = get_parent().get_node("Cursor")

var inventory := InventoryContainer.new([])

var inventory_slots_amount = 5

var selected : Node
var selector : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	for index in range(inventory_slots_amount):
		var ui = inventoryUI.get_node(str(0))
		if !(index == 0):
			ui = ui.duplicate()
			inventoryUI.add_child(ui)
		var inv_button: InventoryButton = InventoryButton.new()
		inv_button.name = str(index)
		inv_button.set_button(ui, seed_selected)
		inventory.slots.append(inv_button)
	
	var inv_button = inventory.slots.get(0)
	inv_button.seed = load("res://plants/sunflower.tscn").instantiate()
	inv_button.amount = 3
	
func seed_selected(seed: Plant):
	if !seed:
		if selected:
			selected.queue_free()
		return
	selected = seed.duplicate()
	selected.process_mode = Node.PROCESS_MODE_DISABLED
	selected.frame = 0
	get_parent().add_child(selected)
	get_parent().move_child(selected, -3)
	
func pos_to_tile_pos(pos: Vector2):
	var mouse_pos_global = get_viewport().get_mouse_position()
	var mouse_pos_local = map.to_local(mouse_pos_global)
	var tile_pos = map.local_to_map(mouse_pos_local)
	return tile_pos
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var tile_pos = pos_to_tile_pos(get_viewport().get_mouse_position())
	if !selected: 
		cursor.position = Vector2(-32, -32) 
		return
	selected.position = tile_pos * 16
	cursor.position = tile_pos * 16
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			print("Mouse Click/Unclick at: ", event.position)
			var tile_pos = pos_to_tile_pos(event.position)
			if selected:
				selected.reparent(plants)
				selected.process_mode = Node.PROCESS_MODE_INHERIT
				selected = null
				
			
