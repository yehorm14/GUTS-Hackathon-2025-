extends Area2D
class_name Tornado

@export var speed: float = 120.0
@export var damage: int = 20
@export var lifetime: float = 6.0
@export var dir: Vector2 = Vector2.RIGHT
@export var spawn_interval: float = 0.2
@export var radius: float = 24.0

var _age := 0.0
var _acc := 0.0
var _rng := RandomNumberGenerator.new()
var _gust_scene := preload("res://entities/wind_gust.tscn")

func _ready() -> void:
	_rng.randomize()
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	position += dir * speed * delta
	_age += delta
	_acc += delta
	if _acc >= spawn_interval:
		_acc -= spawn_interval
		_spawn_gust()
	if _age >= lifetime:
		queue_free()

func _spawn_gust() -> void:
	var g = _gust_scene.instantiate()
	var a = _rng.randf_range(0.0, TAU)
	var off = Vector2(cos(a), sin(a)) * radius
	g.position = global_position + off
	g.dir = dir.rotated(_rng.randf_range(-0.4, 0.4))
	g.speed = _rng.randf_range(140.0, 220.0)
	g.damage = _rng.randi_range(3, 7)
	g.lifetime = _rng.randf_range(1.2, 2.0)
	get_parent().add_child(g)

func _on_area_entered(a: Area2D) -> void:
	var p = a.get_parent()
	if p is Plant:
		p.health -= damage
		if p.health <= 0:
			p.death()
