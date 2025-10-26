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
		var old_amount = amount
		amount = value
		
		if amount != old_amount:
			var added_label: Label = button.get_node("Added").duplicate()
			added_label.label_settings = added_label.label_settings.duplicate()
			added_label.visible = true
			button.add_child(added_label)
			if amount > old_amount:
				added_label.text = "+" + str(amount)
				added_label.label_settings.font_color = Color(1.0, 1, 0.0, 1.0)
			else:
				added_label.text = "-" + str(amount)
				added_label.label_settings.font_color = Color(1.0, 0.0, 0.0, 1.0)
			
			var tween = button.create_tween()
			tween.tween_property(added_label, "position", Vector2(0.0, -36.0), 0.9)
			tween.parallel().tween_property(added_label, "modulate:a", 0.0, 0.6)
			tween.chain().tween_callback(func(): added_label.queue_free())
		
		if button:
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
	
