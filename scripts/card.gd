extends TextureButton
signal selected(card_node)

var card_number: int = 0
var original_scale: Vector2 = Vector2(1, 1)

func _ready() -> void:
	connect("pressed", Callable(self, "_on_pressed"))
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func initialize(number: int) -> void:
	card_number = number
	var texture_path = "res://assets/cards/card_%03d.png" % card_number
	self.texture_normal = load(texture_path)
	
	self.custom_minimum_size = Vector2(80, 120)
	self.ignore_texture_size = true
	self.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	
	# Set pivot offset to center so it scales from the middle
	self.pivot_offset = self.custom_minimum_size / 2.0

func _on_pressed() -> void:
	emit_signal("selected", self)

func _on_mouse_entered() -> void:
	if not disabled:
		var tween = get_tree().create_tween()
		tween.tween_property(self, "scale", original_scale * 1.15, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", original_scale, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
