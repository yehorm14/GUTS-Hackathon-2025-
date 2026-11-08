# i cleaned it up np 
extends Node
signal game_over(won: bool)

@onready var parent = get_parent()
@onready var gs = parent.get_node("GameState")
@onready var plants = parent.get_node("Plants")
@onready var hud = parent.get_node("HUD")
@onready var score_and_timer = hud.get_node("ScoreAndTimer")
@onready var score_and_timer2 = hud.get_node("ScoreAndTimer2")
@onready var event_name = hud.get_node("Event")
@onready var INVENTORY_SLOT_ITEMS = gs.INVENTORY_SLOT_ITEMS
@onready var weather = parent.get_node("Weather")

@onready var _active_layer: TileMapLayer = get_tree().current_scene.get_node("ActiveLayer")
@onready var _bg_layer: TileMapLayer = get_tree().current_scene.get_node("BackgroundLayer")
@onready var TILE_DATA = gs.TILE_DATA

@onready var SCN_GUST = preload("res://entities/wind_gust.tscn")
@onready var SCN_TORNADO = preload("res://entities/tornado.tscn")
@onready var SCN_RAIN = preload("res://entities/rain.tscn")
@onready var SCN_VOLCANO = preload("res://entities/volcano.tscn")
@onready var SCN_VOLCANO_PROJ = preload("res://entities/volcano_projectile.tscn")

@export var game_duration_seconds = 300
@export var seed_interval = 5.0
@export var event_interval = 20.0

@export var event_no = 0

var _game_started = false
var _time_left = 0.0
var _seed_accum = 0.0
var _event_accum = 0.0
var _rng := RandomNumberGenerator.new()
var score = 0

const GAME_EVENTS = [
	"volcano",
	"flooding",
	"tornado",
	"meteorite",
	"storm",
]

const CRATER_MAPPINGS = {
	Vector2i(0,0): Vector2i(0,1),
	Vector2i(1,0): Vector2i(1,1),
	Vector2i(0,1): Vector2i(0,2),
	Vector2i(1,1): Vector2i(1,2),
}

func _ready() -> void:
	_rng.randomize()
	_time_left = float(game_duration_seconds)
	_seed_accum = 0.0
	_event_accum = 0.0
	if _game_started:
		_update_score_stuff()

func _process(delta):
	if !_game_started:
		if plants.get_child_count() > 0:
			_game_started = true
			score_and_timer2.text = "GAME STARTED!"
		else:
			return

	if _time_left > 0.0:
		_time_left = max(0.0, _time_left - delta)
		_update_score_stuff()

		_seed_accum += delta
		if _seed_accum >= seed_interval:
			_seed_accum -= seed_interval
			_give_random_seed()

		event_interval = 20.0 * 0.95**(event_no)
		_event_accum += delta
		if _event_accum >= event_interval:
			_event_accum -= event_interval
			await _fire_random_event()

		if plants.get_child_count() <= 0:
			_time_left = 0
	else:
		set_process(false)
		var won = _has_any_plant_alive()
		_show_end_text(won)
		game_over.emit(won)

func _give_random_seed():
	var drops = 1
	for i in drops:
		var idx = _pick_weighted_index()
		_increment_inventory_slot(idx, 1)

	var bonus = _extra_bamboo_from_producers()
	var harvest_score = _harvest_multiplier() + (10 * _sakura_trees_count())
	score += harvest_score + bonus

func _pick_weighted_index():
	var n = INVENTORY_SLOT_ITEMS.size()
	var weights := PackedFloat32Array()
	for i in range(n):
		weights.append(float(n - i))
	return _rng.rand_weighted(weights)

func _increment_inventory_slot(idx, amount: = 1) :
	if idx < 0 or idx >= gs.inventory.slots.size():
		return
	var slot = gs.inventory.slots[idx]
	if slot:
		slot.amount += amount
		
func _bamboo_inventory_index():
	for i in range(INVENTORY_SLOT_ITEMS.size()):
		if str(INVENTORY_SLOT_ITEMS[i]).to_lower().find("bamboo") != -1:
			return i
	return -1
func _extra_bamboo_from_producers():
	var n = 0
	for c in plants.get_children():
		if c is Plant and c.is_fully_grown:
			n += int(c.extra_bamboo_seeds)
	return n
func _sakura_trees_count():
	var sakura_trees = 0
	for c in plants.get_children():
		if c is DefenderPlant and c.is_sakura_plant:
			sakura_trees += 1
	return sakura_trees

var timer = 0

func _fire_random_event():
	var weightings = randi_range(0,100)
	var namae = ""
	if weightings < 35:
		namae = GAME_EVENTS[1] # flooding
	elif 35 <= weightings and weightings < 60:
		namae = GAME_EVENTS[2]
	elif 60 <= weightings and weightings < 85:
		namae = GAME_EVENTS[4]
	elif 85 <= weightings and weightings < 93:
		namae = GAME_EVENTS[0]
	elif 93 <= weightings:
		namae = GAME_EVENTS[3]
	event_name.text = "EVENT: %s" % namae.to_upper()
	event_no += 1.0
	timer = 3.0
	await get_tree().create_timer(timer).timeout
	event_name.text = ""
	match namae:
		"flooding":
			await _on_event_flooding()
		"storm":
			await _on_event_storm()
		"tornado":
			await _on_event_tornado()
		"volcano":
			await _on_event_volcano()
		"meteorite":
			await _on_event_meteorite()
		_:
			pass

func _on_event_volcano():
	var spot = _find_volcano_spot()
	if spot == null: 
		return
	var pos = _tile_center(_active_layer, spot) - Vector2(32, 32) 
	var volcano = SCN_VOLCANO.instantiate()
	var spr: AnimatedSprite2D = volcano.get_node("AnimatedSprite2D")
	volcano.position = pos
	weather.add_child(volcano)

	for i in range(6):
		var active = (i % 2) == 0
		spr.frame = 1 if active else 0
		if active:
			var shots = _rng.randi_range(2, 5)
			for j in range(shots):
				_spawn_volcano_projectile(volcano.global_position + Vector2(32, 16))
				await get_tree().create_timer(_rng.randf_range(0.3, 0.7)).timeout
		await get_tree().create_timer(_rng.randf_range(1.0, 3.0)).timeout

	volcano.queue_free()
func _find_volcano_spot():
	var vp = get_viewport().get_visible_rect().size
	var tiles_w = int(vp.x / 16)
	var tiles_h = int(vp.y / 16)
	var margin_x = int(tiles_w * 0.125)
	var margin_y = int(tiles_h * 0.125)
	for i in range(120):
		var x = _rng.randi_range(margin_x, tiles_w - margin_x - 4)
		var y = _rng.randi_range(margin_y, tiles_h - margin_y - 4)
		var tl = Vector2i(x, y)
		if _rect_has_plant(tl, 4, 4): 
			continue
		if not _rect_placeable(tl, 4, 4): 
			continue
		return tl
	return null
func _rect_has_plant(tl, w , h):
	for c in plants.get_children():
		if c is Plant:
			var t = _active_layer.local_to_map(_active_layer.to_local(c.global_position))
			if t.x >= tl.x and t.x < tl.x + w and t.y >= tl.y and t.y < tl.y + h:
				return true
	return false
func _rect_placeable(tl, w, h):
	for yy in range(h):
		for xx in range(w):
			var p = tl + Vector2i(xx, yy)
			var atlas = _active_layer.get_cell_atlas_coords(p)
			var info = TILE_DATA.get(atlas)
			if not info or not info.Placeable:
				return false
	return true
func _arc_tween(node, start, target, up, t_up, t_down):
	var apex = (start + target) * 0.5
	apex.y -= up
	var tw = get_tree().create_tween()
	tw.tween_property(node, "position", apex, t_up).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(node, "position", target, t_down).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	return tw

func _spawn_volcano_projectile(start_pos):
	var vp = get_viewport().get_visible_rect().size
	var tx = _rng.randi_range(0, int(vp.x / 16) - 2)
	var ty = _rng.randi_range(0, int(vp.y / 16) - 2)
	var target_tile = Vector2i(tx, ty)
	var target = _tile_center(_active_layer, target_tile)

	var proj = SCN_VOLCANO_PROJ.instantiate()
	proj.position = start_pos
	weather.add_child(proj)
	
	_arc_tween(proj, start_pos, target, 64.0, 0.3, 0.3).chain().tween_callback(func():
		_impact_crater(target_tile)
		proj.queue_free()
	)

func _spawn_meteor(start_pos, target_tile):
	var target = _tile_center(_active_layer, target_tile)
	var proj = SCN_VOLCANO_PROJ.instantiate()
	proj.position = start_pos
	weather.add_child(proj)

	var spr: AnimatedSprite2D = proj.get_node("AnimatedSprite2D")
	spr.modulate = Color(1.0, 0.65, 0.2)
	_arc_tween(proj, start_pos, target, _rng.randf_range(96.0, 144.0), 0.35, 0.45).chain().tween_callback(func():
		_impact_crater(target_tile)
		proj.queue_free()
	)

func _impact_crater(tl) :
	for off in [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)]:
		var p = tl + off
		var plant = _tile_has_plant(p)
		if plant: plant.queue_free()
		_active_layer.erase_cell(p)

	for off in CRATER_MAPPINGS.keys():
		_bg_layer.set_cell(tl + off, 0, CRATER_MAPPINGS[off], 0)

func _on_event_flooding():
	var vp = get_viewport().get_visible_rect().size
	var drops = 128
	for i in range(drops):
		var tx = _rng.randi_range(0, int(vp.x / 16) - 1)
		var ty = _rng.randi_range(0, int(vp.y / 16) - 1)
		var tile = Vector2i(tx, ty)
		var target_pos = _tile_center(_active_layer, tile)

		var a = SCN_RAIN.instantiate()
		var start_y = max(-64.0, target_pos.y - 160.0)
		a.position = Vector2(target_pos.x, start_y)
		weather.add_child(a)

		var tw = get_tree().create_tween()
		tw.tween_property(a, "position", target_pos, 0.6).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(func():
			if _tile_has_plant(tile):
				a.queue_free(); return
			var atlas = _active_layer.get_cell_atlas_coords(tile)
			var info = TILE_DATA.get(atlas)
			if info and info.Name == "Water":
				_spread_water_from(tile, 1)
			a.queue_free()
		)
		await get_tree().create_timer(_rng.randf_range(0.02, 0.1)).timeout

func _tile_center(layer: TileMapLayer, tile: Vector2i) -> Vector2:
	return layer.to_global(layer.map_to_local(tile)) + Vector2(8, 8)

func _tile_has_plant(tile: Vector2i) -> Plant:
	for c in plants.get_children():
		if c is Plant:
			var t = _active_layer.local_to_map(_active_layer.to_local(c.global_position))
			if t == tile:
				return c
	return null

func _spread_water_from(start: Vector2i, steps: int):
	var WATER = Vector2i(1, 0)
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	var frontier = [start]
	var seen = {start: true}
	for d in range(steps):
		var nxt = []
		for p in frontier:
			for dd in dirs:
				var n = p + dd
				if seen.has(n): continue
				var plant = _tile_has_plant(n)
				if plant: plant.queue_free()
				var atlas = _active_layer.get_cell_atlas_coords(n)
				var info = TILE_DATA.get(atlas)
				if info and info.Placeable and info.Name != "Water":
					_active_layer.set_cell(n, 0, WATER, 0)
					nxt.append(n)
					seen[n] = true
		frontier = nxt
		if frontier.is_empty():
			break

func _on_event_tornado() :
	var vp = get_viewport().get_visible_rect().size
	var from_west = _rng.randf() < 0.5
	var start_x = -64.0 if from_west else vp.x + 64.0
	var dir = Vector2.RIGHT if from_west else Vector2.LEFT
	var count = 2 + _rng.randi_range(0, 1)
	for i in count:
		var t = SCN_TORNADO.instantiate()
		t.dir = dir
		t.speed = _rng.randf_range(110.0, 150.0)
		t.damage = _rng.randi_range(6, 12)
		t.lifetime = _rng.randf_range(5.0, 7.0)
		t.spawn_interval = _rng.randf_range(0.06, 0.12)
		var y = _rng.randi_range(32, int(vp.y) - 32)
		t.position = Vector2(start_x, y)
		weather.add_child(t)
		await get_tree().create_timer(_rng.randf_range(0.15, 0.35)).timeout

func _on_event_storm():
	var vp = get_viewport().get_visible_rect().size
	var from_west = _rng.randf() < 0.5
	var start_x = -48.0 if from_west else vp.x + 48.0
	var dir = Vector2.RIGHT if from_west else Vector2.LEFT
	var count = 32
	var y_margin = 8
	var dmg = randi_range(5, 12)
	for i in range(count):
		var g = SCN_GUST.instantiate()
		g.dir = dir
		g.speed = _rng.randf_range(140.0, 220.0)
		g.damage = dmg*(1.1**(event_no))
		g.lifetime = 4.0
		var y = _rng.randi_range(y_margin, int(vp.y) - y_margin)
		g.position = Vector2(start_x, float(y))
		weather.add_child(g)
		await get_tree().create_timer(randf() * 0.5).timeout

func _on_event_meteorite() :
	var vp = get_viewport().get_visible_rect().size
	var meteors = 8 + _rng.randi_range(0, 4)
	for i in range(meteors):
		var sx = _rng.randi_range(0, int(vp.x))
		var start = Vector2(sx, -64.0)
		var tx = _rng.randi_range(0, int(vp.x / 16) - 2)
		var ty = _rng.randi_range(0, int(vp.y / 16) - 2)
		var target_tile = Vector2i(tx, ty)
		_spawn_meteor(start, target_tile)
		await get_tree().create_timer(_rng.randf_range(0.12, 0.25)).timeout

func _harvest_multiplier():
	var n = 0
	for c in plants.get_children():
		if c is ProducerPlant and c.is_fully_grown:
			n += c.harvest
	return n

func _update_score_stuff():
	var mins = int(_time_left / 60)
	var secs = int(_time_left) % 60
	var t = "%d:%02d" % [mins, secs]
	var seed_in = max(0.0, seed_interval - _seed_accum)
	var event_in = max(0.0, event_interval - _event_accum)
	
	var mult = _harvest_multiplier()
	var bamboo_bonus = _extra_bamboo_from_producers()
	var sakura_trees = _sakura_trees_count()

	score_and_timer.text = "SCORE: %d\nTIME: %s" % [score, t]

	var lines = [
		"NEXT EVENT IN: %.0fs" % event_in,
		"NEXT HARVEST IN: %.0fs" % seed_in
	]
	if mult > 0: 
		lines.append("+(%d) SCORE PER HARVEST" % mult)
	if bamboo_bonus > 0: 
		lines.append("+(%d) BAMBOO SCORE PER HARVEST" % bamboo_bonus)
	if sakura_trees > 0: 
		lines.append("+(%d) SAKURA HARVEST MULTIPLIER" % sakura_trees)

	score_and_timer2.text = "\n".join(lines)

func add_score(points):
	score = max(0, score + points)
	_update_score_stuff()

func _has_any_plant_alive():
	for c in plants.get_children():
		if c is Plant:
			return true
	return false

func _show_end_text(won):
	var mins = int(_time_left / 60)
	var secs = int(_time_left) % 60
	var t = "%d:%02d" % [mins, secs]
	score_and_timer.text = "SCORE: %d\nTIME: %s\n%s" % [
		score, t, "YOU SURVIVED" if won else "ALL PLANTS LOST"
	]
