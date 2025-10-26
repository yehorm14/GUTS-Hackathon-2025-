extends Area2D
class_name WindGust

@export var speed = 180.0
@export var damage = 10
@export var lifetime = 4.0
@export var dir = Vector2.RIGHT

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _age = 0.0

func _ready() -> void:
	if randi() % 2 == 0:
		sprite.frame = 1
	else:
		sprite.frame = 2
	area_entered.connect(_on_area_entered)

func _process(delta):
	position += dir * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	var vp := get_viewport_rect()
	if position.x < -64 or position.x > vp.size.x + 64 or position.y < -64 or position.y > vp.size.y + 64:
		queue_free()

func _on_area_entered(a):
	if not a: return
	var p = a.get_parent()
	if p is Plant:
		p.health -= damage
		damage -= damage
		if damage <= 0:
			queue_free()
