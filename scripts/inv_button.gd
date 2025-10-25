extends Node
class_name InventoryButton

var seed: Plant :
	set(value):
		seed = value
		if !button:
			return
			
		var icon: AnimatedSprite2D = button.get_node("Icon")
		if seed:
			icon.sprite_frames = seed.sprite_frames
			icon.frame = icon.sprite_frames.get_frame_count("default")
			icon.plant_redirect = seed
		else:
			icon.sprite_frames = null
			button.get_node("Amount").text = ""
			icon.plant_redirect = null
		
var amount: int = 0 :
	set(value):
		amount = value
		if !button:
			return
		var material: ShaderMaterial = button.get_node("Icon").material
		material.set_shader_parameter("grayscale", true if amount == 0 else false)
		button.get_node("Amount").text = "" if amount == -1 else "×" + str(amount)
		
var button: TextureButton

func set_button(b: TextureButton, seed_callable: Callable) -> void:
	button = b
	amount = 0
	
	button.pressed.connect(func():
		if amount <= 0:
			return
		seed_callable.call(seed, int(b.name))
	)
	
