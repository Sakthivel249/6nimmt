extends Control

@onready var click_player = $ClickPlayer
var CardScene = preload("res://card.tscn")

func _ready():
	# Generate a beautiful radial gradient background programmatically
	var gradient = Gradient.new()
	# Fix: Use set_color to override default points instead of add_point to avoid white corners!
	gradient.set_color(0, Color(0.18, 0.12, 0.35, 1)) # Deep purple in center
	gradient.set_color(1, Color(0.05, 0.05, 0.1, 1))  # Very dark blue/black on edges
	
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1, 1)
	
	$BackgroundRect.texture = tex
	
	$CenterContainer/VBoxContainer/ButtonsVBox/StartButton.grab_focus()
	
	# Setup initial UI animation
	$CenterContainer.scale = Vector2(0.8, 0.8)
	$CenterContainer.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property($CenterContainer, "scale", Vector2(1, 1), 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($CenterContainer, "modulate:a", 1.0, 0.4)
	
	spawn_floating_cards()

func spawn_floating_cards():
	for i in range(50):
		var card = CardScene.instantiate()
		var random_number = randi() % 104 + 1
		card.initialize(random_number)
		card.disabled = true
		
		# Depth logic for parallax effect (0.0 = background, 1.0 = foreground)
		var depth = randf()
		
		# Scale based on depth (smaller = further back)
		var scale_val = lerp(0.5, 2.5, depth)
		card.scale = Vector2(scale_val, scale_val)
		
		# Color and transparency based on depth (darker/more transparent = further back)
		var alpha = lerp(0.15, 0.8, depth)
		var darkness = lerp(0.2, 1.0, depth)
		card.modulate = Color(darkness, darkness, darkness, alpha)
		
		# Set pivot to center for proper rotation
		card.pivot_offset = Vector2(50, 75)
		
		var screen_size = get_viewport_rect().size
		if screen_size.x < 100:
			screen_size = Vector2(1280, 720) # Fallback
			
		card.position = Vector2(randf_range(-200, screen_size.x + 200), randf_range(-200, screen_size.y + 200))
		card.rotation_degrees = randf_range(-180, 180)
		
		add_child(card)
		move_child(card, 1) # Place above TextureRect, behind CenterContainer
		
		animate_floating_card(card, depth)

func animate_floating_card(card: Node, depth: float):
	var tween = card.create_tween().set_loops()
	
	# Foreground objects (depth near 1.0) move faster (shorter duration)
	# Background objects (depth near 0.0) move slower (longer duration)
	var duration = lerp(45.0, 12.0, depth)
	
	# Float upwards
	tween.tween_property(card, "position:y", card.position.y - 1200, duration).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property(card, "rotation_degrees", card.rotation_degrees + randf_range(90, 270), duration)
	
	# Wrap around when out of screen (callback)
	tween.tween_callback(func(): if is_instance_valid(card): card.position.y = get_viewport_rect().size.y + 300)

func _on_start_button_pressed():
	$CenterContainer/VBoxContainer/ButtonsVBox/StartButton.disabled = true
	click_player.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://MainScene.tscn")

func _on_exit_button_pressed():
	click_player.play()
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
