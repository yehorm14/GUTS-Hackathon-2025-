extends Node

@onready var parent = get_parent()
@onready var bgLayer: TileMapLayer = parent.get_node("BackgroundLayer")
@onready var activeLayer: TileMapLayer = parent.get_node("ActiveLayer")
@onready var plants: Node2D = parent.get_node("Plants")
@onready var hud: Control = parent.get_node("HUD")
@onready var inventoryUI: HBoxContainer = parent.get_node("HUD").get_node("InventoryUI")
@onready var placeToStart: Label = parent.get_node("HUD").get_node("PlaceToStart")
@onready var youScored: Label = parent.get_node("HUD").get_node("YouScored")
@onready var mainMenuButton: Button = parent.get_node("HUD").get_node("MainMenuButton")
@onready var cursor: Sprite2D = parent.get_node("Cursor")

@onready var infoText: Label = parent.get_node("InfoText")
@onready var placeHint: Label = parent.get_node("PlaceHint")

@onready var gameLoop := parent.get_node("GameLoop")

var inventory := InventoryContainer.new([])
var inventory_slots_amount = 10
const INVENTORY_SLOT_ITEMS = [
	"sunflower.tscn",
	"tomato.tscn",
	"potato.tscn",
	"carrot.tscn",
	"corn.tscn",
	
	"white_pine.tscn",
	"tropical_tree.tscn",
	"bamboo.tscn",
	"cactus.tscn",
	
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

var stopped: bool = false

const TILE_DATA := {
	Vector2i(0, 0): {
		Name = "Grass",
		Placeable = true,
		Water = 30,
	},
	Vector2i(1, 0): {
		Name = "Water",
		Placeable = false,
		Water = 100,
	},
	Vector2i(2, 0): {
		Name = "Rock",
		Placeable = false,
		Water = 0,
	},
	Vector2i(0, 1): {
		Name = "Crater1",
		Placeable = false,
		Water = 20,
	},
	Vector2i(1, 1): {
		Name = "Crater2",
		Placeable = false,
		Water = 20,
	},
	Vector2i(0, 2): {
		Name = "Crater3",
		Placeable = false,
		Water = 20,
	},
	Vector2i(1, 2): {
		Name = "Crater4",
		Placeable = false,
		Water = 20,
	},
	Vector2i(3, 0): {
		Name = "Black",
		Placeable = false,
		Water = 0,
	},
}

var SHADER_TEX = preload("res://shaders/outline.gdshader")
var mouse_down: bool = false

var hover_target = null
var hover_is_redirect := false
var hover_time := 0.0
const REDIRECT_DELAY := 0.2
const _GRASS = Vector2i(0,0)
const _WATER = Vector2i(1,0)
const _CRATERS = {
	Vector2i(0,1): true,
	Vector2i(1,1): true,
	Vector2i(0,2): true,
	Vector2i(1,2): true,
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mainMenuButton.visible = false
	youScored.visible = false
	placeToStart.visible = true
	placeHint.visible = false
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
		inventory.slots.append(inv_button)
		
	inventory.slots[0].amount = 1
	
	var won = await gameLoop.game_over
	set_process(false)
	stopped = true
	
	if selected:
		selected.queue_free()
		selected = null
		selected_slot = -1
	
	placeHint.visible = false
	infoText.visible = false
	
	mainMenuButton.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
	)
	mainMenuButton.visible = true
	youScored.visible = true
	youScored.text = "YOU " + ("WON" if won else "LOST") + "!\nSCORE: " + str(gameLoop.score)
	
	
func _spawn_preview(seed: Plant) -> void:
	selected = seed.duplicate()
	selected.process_mode = Node.PROCESS_MODE_DISABLED
	selected.frame = 0
	get_parent().add_child(selected)
	get_parent().move_child(selected, -5)

func seed_selected(seed: Plant, slotId: int):
	if placeToStart:
		var tw := create_tween()
		tw.tween_property(placeToStart, "modulate:a", 0, 0.1).set_delay(1)
		tw.chain().tween_callback(func(): if placeToStart: placeToStart.queue_free())
		placeToStart = null
	
	if selected:
		selected.queue_free()
		selected = null
		selected_slot = -1
		
	if !seed:
		return
		
	if stopped:
		return
		
	selected_slot = slotId
	_spawn_preview(seed)
	
func pos_to_tile_pos(world_pos: Vector2, layer: TileMapLayer = bgLayer) -> Vector2i:
	var local = layer.to_local(world_pos)
	return layer.local_to_map(local)
	
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
	
	var coords1 := activeLayer.get_cell_atlas_coords(tile_pos)
	var tile_info = TILE_DATA[coords1] if TILE_DATA.has(coords1) else []
	if tile_info:
		return tile_info.Placeable
		
	var coords2 := bgLayer.get_cell_atlas_coords(tile_pos)
	var tile_info2 = TILE_DATA[coords2] if TILE_DATA.has(coords2) else []
	if tile_info2:
		return tile_info2.Placeable
		
	return false
	
# Shared by plants and the placement hint. The ActiveLayer tile (water, rock)
# overrides the BackgroundLayer tile (grass, craters) when both are present.
func scan_nearby_water(tile_pos: Vector2i, water_range: int) -> int:
	var count := 0
	for dy in range(-water_range, water_range + 1):
		for dx in range(-water_range, water_range + 1):
			var p := tile_pos + Vector2i(dx, dy)
			var coords := bgLayer.get_cell_atlas_coords(p)
			if activeLayer.get_cell_source_id(p) != -1:
				coords = activeLayer.get_cell_atlas_coords(p)
			var tile_info = TILE_DATA.get(coords)
			if tile_info:
				count += int(tile_info.Water)
	return count

func _heal_craters_tick():
	var vp = get_viewport().get_visible_rect().size
	var tw = int(vp.x / 16)
	var th = int(vp.y / 16)
	for i in range(12):
		var x = randi_range(0, tw - 1)
		var y = randi_range(0, th - 1)
		var t = Vector2i(x, y)
		if activeLayer.get_cell_atlas_coords(t) != _WATER:
			continue
		for n in [t, t + Vector2i(1,0), t + Vector2i(-1,0), t + Vector2i(0,1), t + Vector2i(0,-1)]:
			var atlas = bgLayer.get_cell_atlas_coords(n)
			if _CRATERS.has(atlas):
				bgLayer.set_cell(n, 0, _GRASS, 0)
				activeLayer.set_cell(n, 0, _WATER, 0)
	
func _process(delta: float) -> void:
	if stopped:
		if selected:
			selected.queue_free()
			selected = null
			selected_slot = -1
		return
	
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
	var candidate = null
	var candidate_is_redirect := false
	
	for h in hits:
		if h.collider.name == "InfoBox":
			var p = h.collider.get_parent()
			if "plant_redirect" in p:
				candidate = p
				candidate_is_redirect = true
			elif p is Plant:
				candidate = p
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
		var plant_original
		if "plant_redirect" in candidate:
			plant_original = candidate.plant_redirect
		elif candidate is Plant:
			plant_original = candidate._plant_original
			
		if hover_is_redirect:
			infoText.text = plant_original.name \
							+ "\n" \
							+ plant_original.item_description
		else:
			var is_producer = plant_original is ProducerPlant

			var lines: Array[String] = []
			lines.append(plant_original.name)
			
			var water_abundance = (float(hover_target.nearby_water_perc) / float(hover_target.water_usage))
			
			var water_status = ""
			if water_abundance <= 0.5:
				water_status = "Your plant will start to shrink"
			elif water_abundance < 1.0:
				water_status = "OK. But no Growth [Must be >100%]"
			elif water_abundance < 1.5:
				water_status = "Plant will Grow [Maxed at %s stage%s]" % [hover_target.plant_stages - 1, "" if hover_target.plant_stages - 1 <= 0 else "s"]
			else:
				water_status = "Plant will Grow [Maxed at %s stage%s]" % [hover_target.plant_stages - 1, "" if hover_target.plant_stages - 1 <= 0 else "s"]
			
			lines.append("Health: %d | Nearby Water: %0.0f%%\n%s" % [
				hover_target.health,
				water_abundance * 100,
				water_status
			])	
					
			lines.append("Growth Stage: (%d/%d)" % [hover_target.frame, hover_target.plant_stages - 1])
			lines.append("Drinks in: %0.1fs" % hover_target._time_until_next_water_drink)

			if is_producer:
				var p = hover_target as ProducerPlant
				if hover_target.frame < hover_target.plant_stages - 1:
					lines.append("Growth in: %0.1fs" % hover_target._time_until_next_growth)
				else:
					lines.append("Fully grown")

			infoText.text = "\n".join(lines)
		infoText.reset_size()
		var label_size := infoText.size 
		var vp_size := get_viewport().get_visible_rect().size
		var flipx = false
		
		if pos.x + label_size.x > vp_size.x:
			pos.x = mouse.x - TEXT_OFFSET.x - label_size.x
			flipx = true
			
		if flipx and pos.x < 0:
			pos.x = mouse.x + TEXT_OFFSET.x
			
		pos.x = clamp(pos.x, 0.0, vp_size.x - label_size.x)
		if pos.y + label_size.y > vp_size.y:
			pos.y = mouse.y - TEXT_OFFSET.y - label_size.y

		infoText.global_position = pos
		
	if randf() < 0.25:
		_heal_craters_tick()
		
	var tile_pos = pos_to_tile_pos(mouse)
	if selected:
		if can_place_at(tile_pos):
			var is_defense = selected is DefenderPlant
			var t := pos_to_tile_pos(mouse, activeLayer)
			var water := scan_nearby_water(t, selected.water_range)
			var usage = max(1, selected.water_usage)
			var abundance = float(water) / float(usage)

			var verdict := (
				"Not recommended" if abundance < 0.5
				else "No growth" if abundance < 1.0
				else "Good" if abundance < 1.5
				else "Abundance"
			)
			
			if verdict == "No growth" and is_defense:
				verdict = "OK, just no health regeneration"
			
			if abundance >= 1.0:
				placeHint.get_theme_stylebox("normal").bg_color = Color("#76e47e")
				placeHint.get_theme_stylebox("normal").border_color = Color("#009500")
			else:
				placeHint.get_theme_stylebox("normal").bg_color = Color("ffe47eff")
				placeHint.get_theme_stylebox("normal").border_color = Color("ff9500ff")
			placeHint.text = "Water Level: %0.0f%% - %s" % [abundance * 100.0, verdict]
		else:
			placeHint.get_theme_stylebox("normal").bg_color = Color("8e1800ff")
			placeHint.get_theme_stylebox("normal").border_color = Color("7a0018ff")
			placeHint.text = "You cannot plant here."
			
		placeHint.visible = true

		var hint_pos = mouse + Vector2(-40, -24)
		placeHint.reset_size()
		var ls = placeHint.size
		var vp = get_viewport().get_visible_rect().size
		if hint_pos.x + ls.x > vp.x: 
			hint_pos.x = mouse.x + 40 - ls.x
		if hint_pos.y < 0: 
			hint_pos.y = mouse.y + 18
		placeHint.global_position = hint_pos
	else:
		if placeHint:
			placeHint.visible = false
			
	if selected: 
		selected.position = tile_pos * 16
		cursor.position = tile_pos * 16
		
		if mouse_down:
			if selected and can_place_at(tile_pos):
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
				
				var slot = inventory.slots.get(selected_slot)
				if slot and slot.seed and slot.amount > 0:
					slot.amount -= 1
					selected._plant_original = slot.seed
				
				selected.process_mode = Node.PROCESS_MODE_INHERIT
				selected = null
				
				if slot.amount > 0:
					_spawn_preview(slot.seed)
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
