extends Node

@onready var bgLayer: TileMapLayer = get_parent().get_node("BackgroundLayer")
@onready var activeLayer: TileMapLayer = get_parent().get_node("ActiveLayer")
@onready var plants: Node2D = get_parent().get_node("Plants")
@onready var hud: Control = get_parent().get_node("HUD")
@onready var inventoryUI: HBoxContainer = get_parent().get_node("HUD").get_node("InventoryUI")
@onready var cursor: Sprite2D = get_parent().get_node("Cursor")

@onready var infoText: Label = get_parent().get_node("InfoText")

var inventory := InventoryContainer.new([])
var inventory_slots_amount = 10
const INVENTORY_SLOT_ITEMS = [
	"sunflower.tscn",
	"tomato.tscn",
	"potato.tscn",
	"carrot.tscn",
	"corn.tscn",
	
	"white_pine.tscn",
	"cactus.tscn",
	"tropical_tree.tscn",
	"bamboo.tscn",
	
	"sakura.tscn",
]
const BUTTON_TYPES = {
	"NotClicked": preload("res://art/ui/inventory_slot.png"),
	"Clicked": preload("res://art/ui/inventory_slot_click.png")
}

const TEXT_OFFSET := Vector2(12, 12)

var selected_slot : int = -1
var selected : Node
var selector : Node

const TILE_DATA := {
	Vector2i(-1, -1): {
		Name = "Nothing",
		Placeable = true
	},
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

var SHADER_TEX = preload("res://shaders/outline.gdshader")
var mouse_down: bool = false

var hover_target: Plant = null
var hover_is_redirect := false
var hover_time := 0.0
const REDIRECT_DELAY := 0.2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	infoText.visible = false
	for index in range(inventory_slots_amount):
		var ui = inventoryUI.get_node(str(0))
		if !(index == 0):
			ui = ui.duplicate()
			ui.name = str(index)
			var icon = ui.get_node("Icon")
			var mat = icon.material
			icon.material = mat.duplicate()
			inventoryUI.add_child(ui)
			
		var inv_button: InventoryButton = InventoryButton.new()
		inv_button.name = str(index)
		inv_button.set_button(ui, seed_selected)
		inv_button.seed = load("res://plants/" + INVENTORY_SLOT_ITEMS[index]).instantiate()
		inv_button.amount = 2
		inventory.slots.append(inv_button)
	
func seed_selected(seed: Plant, slotId: int):
	if !seed:
		if selected:
			selected.queue_free()
			selected = null
			selected_slot = -1
		return
	selected_slot = slotId
	selected = seed.duplicate()
	selected.process_mode = Node.PROCESS_MODE_DISABLED
	selected.frame = 0
	get_parent().add_child(selected)
	get_parent().move_child(selected, -3)
	
func pos_to_tile_pos(pos: Vector2):
	var mouse_pos_global = get_viewport().get_mouse_position()
	var mouse_pos_local = bgLayer.to_local(mouse_pos_global)
	var tile_pos = bgLayer.local_to_map(mouse_pos_local)
	return tile_pos
	
func can_place_at(tile_pos: Vector2):
	var mouse_pos := (tile_pos * 16) + Vector2(8, 8)
	
	var w2D = get_parent().get_world_2d()
	var space = w2D.direct_space_state
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true 
	query.collide_with_bodies = false
		
	if space.intersect_point(query, 1):
		return false
	
	var coords := activeLayer.get_cell_atlas_coords(tile_pos)
	var tile_info = TILE_DATA[coords]
	if tile_info:
		return tile_info.Placeable
		
	return false
	
func _process(delta: float) -> void:
	for slot in inventory.slots:
		slot.button.texture_normal = BUTTON_TYPES.Clicked if selected_slot == int(slot.button.name) else BUTTON_TYPES.NotClicked
		
	var mouse := get_viewport().get_mouse_position()
	var pos := mouse + TEXT_OFFSET
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var hits = get_parent().get_world_2d().direct_space_state.intersect_point(query)
	var plant_hit: Plant
	var candidate: Plant = null
	var candidate_is_redirect := false
	
	for h in hits:
		if h.collider.name == "InfoBox":
			var parent = h.collider.get_parent()
			if "plant_redirect" in parent:
				candidate = parent.plant_redirect
				candidate_is_redirect = true
			elif parent is Plant:
				candidate = parent._plant_original
				candidate_is_redirect = false
			break

	if candidate != hover_target or candidate_is_redirect != hover_is_redirect:
		hover_target = candidate
		hover_is_redirect = candidate_is_redirect
		hover_time = 0.0
	else:
		hover_time += delta

	var show := false
	if hover_target:
		show = hover_time >= REDIRECT_DELAY 
	
	infoText.visible = show
	if show:
		if hover_is_redirect:
			infoText.text = hover_target.name \
							+ "\n" \
							+ hover_target.item_description
		else:
			infoText.text = hover_target.name \
							+ "\nActive" \
							+ "\n" \
							+ hover_target.item_description
		infoText.reset_size()
		var label_size := infoText.size 
		var vp_size := get_viewport().get_visible_rect().size
		if pos.x + label_size.x > vp_size.x:
			pos.x = mouse.x - TEXT_OFFSET.x - label_size.x
		if pos.y + label_size.y > vp_size.y:
			pos.y = mouse.y - TEXT_OFFSET.y - label_size.y
		infoText.global_position = pos

	var tile_pos = pos_to_tile_pos(mouse)
	if selected: 
		selected.position = tile_pos * 16
		cursor.position = tile_pos * 16
		
		if mouse_down:
			if selected and can_place_at(tile_pos):
				var pre_clone_selected = selected.duplicate()
				selected.reparent(plants)
				
				var SHADER_MATERIAL = ShaderMaterial.new()
				SHADER_MATERIAL.shader = SHADER_TEX
				SHADER_MATERIAL.resource_local_to_scene = true
				selected.material = SHADER_MATERIAL
				
				var area2D = Area2D.new()
				var colshape2D = CollisionShape2D.new()
				var rectshape = RectangleShape2D.new()
				colshape2D.position = Vector2(8, 8)
				rectshape.size = Vector2(16, 16)
				
				area2D.name = "InfoBox"
				area2D.add_child(colshape2D)
				colshape2D.shape = rectshape
				
				selected.add_child(area2D)
				
				var can_replant = false
				var slot = inventory.slots.get(selected_slot)
				if slot and slot.seed and slot.amount > 0:
					can_replant = true
					slot.amount -= 1
					
					selected._plant_original = slot.seed
				
				selected.process_mode = Node.PROCESS_MODE_INHERIT
				selected = null
				
				if slot.amount > 0:
					selected = pre_clone_selected.duplicate()
					selected.process_mode = Node.PROCESS_MODE_DISABLED
					selected.frame = 0
					get_parent().add_child(selected)
					get_parent().move_child(selected, -3)
	else:
		cursor.position = Vector2(-32, -32) 
				
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_down = event.pressed
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if selected:
			selected.queue_free()
			selected = null
			selected_slot = -1
		return
