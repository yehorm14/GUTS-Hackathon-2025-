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
		else:
			icon.sprite_frames = null
			button.get_node("Amount").text = ""
		
var amount: int = 0 :
	set(value):
		amount = value
		if !button:
			return
		button.get_node("Amount").text = "" if amount == 0 else "×" + str(amount)
		
var button: TextureButton

func set_button(b: TextureButton, seed_callable: Callable) -> void:
	button = b
	amount = 0
	
	button.pressed.connect(func():
		seed_callable.call(seed)
	)
	
