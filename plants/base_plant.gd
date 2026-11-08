extends AnimatedSprite2D
class_name Plant

@export var health:int = 50 :
	set(val):
		health = val
		if health <= 0:
			queue_free()
			
@export var plant_stages:int = 3
@export var drink_timer:int = 10
@export_multiline var item_description : String
@export var water_range = 1
@export var water_usage = 1
@export var _plant_original: Plant

var extra_bamboo_seeds: int = 0

var max_health: int
var nearby_water_perc: int = 0
var is_fully_grown: bool = true
var _active_time: float = 0.0
var _time_until_next_water_drink: float = 0.0

var water:bool = true

@onready var _active_layer: TileMapLayer = get_tree().current_scene.get_node("ActiveLayer")
@onready var game_state = get_tree().current_scene.get_node("GameState")
@onready var TILE_DATA = game_state.TILE_DATA

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	on_plant_ready()
	
	if process_mode == PROCESS_MODE_DISABLED:
		while true:
			if not get_tree():
				return
				
			await get_tree().process_frame
			if process_mode != PROCESS_MODE_DISABLED:
				break
	
	frame = 0
	on_start_grow()
	
	max_health = health
	
	nearby_water_perc = _scan_nearby_water_count()
	_time_until_next_water_drink = drink_timer

func on_start_grow():
	pass
	
func on_plant_ready():
	pass
	
func on_drink_water():
	pass
	
func death():
	queue_free()

func _process(delta: float) -> void:
	_active_time += delta
	_time_until_next_water_drink = max(_time_until_next_water_drink - delta, 0.0)
	if _time_until_next_water_drink == 0.0:
		_on_drink_tick()
		_time_until_next_water_drink = drink_timer
		
		var water_abundance = (float(nearby_water_perc) / float(water_usage))
		if water_abundance < 0.5:
			var next_frame = frame - 1
			if next_frame < 0:
				queue_free()
			else:
				frame = next_frame
		
func _on_drink_tick() -> void:
	nearby_water_perc = _scan_nearby_water_count()
	on_drink_water()
	
	var perc = float(nearby_water_perc) / float(water_usage)
	if perc > 0.5:
		perc *= 0.3
		health = min(health + perc, max_health)
	

func _scan_nearby_water_count() -> int:
	var tile_pos := _active_layer.local_to_map(_active_layer.to_local(global_position))
	var count := 0
	for dy in range(-water_range, water_range + 1):
		for dx in range(-water_range, water_range + 1):
			var p := tile_pos + Vector2i(dx, dy)
			var atlas := _active_layer.get_cell_atlas_coords(p)
			var info = TILE_DATA.get(atlas)
			if info:
				count += info.Water
	
	return count
