extends Node

@onready var map: TileMapLayer = get_parent().get_node("Map")
@onready var plants: Node2D = get_parent().get_node("Plants")
@onready var hud: Control = get_parent().get_node("HUD")
@onready var inventoryUI: HBoxContainer = get_parent().get_node("HUD").get_node("InventoryUI")
@onready var cursor: Sprite2D = get_parent().get_node("Cursor")

var inventory := InventoryContainer.new([])
var inventory_slots_amount = 8

var selected_slot : int
var selected : Node
var selector : Node

const TILE_DATA := {
	Vector2i(0, 0): {
		Name = "Grass",
		Placeable = true
	},
	Vector2i(1, 0): {
		Name = "Water",
		Placeable = false
	},
	Vector2i(2, 0): {
		Name = "Rock",
		Placeable = false
	},
}

var SHADER_MATERIAL = ShaderMaterial.new()
var SHADER_TEX = preload("res://shaders/outline.gdshader")

var mouse_down: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SHADER_MATERIAL.shader = SHADER_TEX
		
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
	inv_button.amount = 25
	
func seed_selected(seed: Plant, slot: int):
	if !seed:
		if selected:
			selected.queue_free()
		return
	selected_slot = slot
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
	
func can_place_at(tile_pos: Vector2):
	var mouse_pos := tile_pos * 16
	
	var w2D = get_parent().get_world_2d()
	var space = w2D.direct_space_state
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true 
		
	if space.intersect_point(query, 1):
		return false
	
	var coords := map.get_cell_atlas_coords(tile_pos)
	var tile_info = TILE_DATA[coords]
	if tile_info:
		return tile_info.Placeable
		
	return false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var tile_pos = pos_to_tile_pos(get_viewport().get_mouse_position())
	if !selected: 
		cursor.position = Vector2(-32, -32) 
		return
		
	selected.position = tile_pos * 16
	cursor.position = tile_pos * 16
	
	if mouse_down:
		if selected and can_place_at(tile_pos):
			var pre_clone_selected = selected.duplicate()
			
			selected.reparent(plants)
			
			selected.material = SHADER_MATERIAL
			
			var area2D = Area2D.new()
			var colshape2D = CollisionShape2D.new()
			var rectshape = RectangleShape2D.new()
			colshape2D.position = Vector2(8, 8)
			rectshape.size = Vector2(16, 16)
			
			area2D.add_child(colshape2D)
			colshape2D.shape = rectshape
			
			selected.add_child(area2D)
			
			var can_replant = false
			var slot = inventory.slots.get(selected_slot)
			if slot and slot.seed and slot.amount > 0:
				can_replant = true
				slot.amount -= 1
			
			selected.process_mode = Node.PROCESS_MODE_INHERIT
			selected = null
			
			if slot.amount > 0:
				selected = pre_clone_selected.duplicate()
				selected.process_mode = Node.PROCESS_MODE_DISABLED
				selected.frame = 0
				get_parent().add_child(selected)
				get_parent().move_child(selected, -3)
			else:
				slot.seed = null
			
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		mouse_down = event.pressed
