extends TextureButton

# Signal emitted when the card is clicked. It sends a reference to itself.
signal selected(card_node)

var card_number: int = 0
var original_position: Vector2

func _ready() -> void:
	original_position = self.position
	connect("pressed", Callable(self, "_on_pressed"))  # <-- Connects Godot's pressed signal


func initialize(number: int) -> void:
	card_number = number
	# Make sure this path is correct for your project
	var texture_path = "res://6nimmt_cards/card_%03d.png" % card_number
	self.texture_normal = load(texture_path)

	if self.texture_normal == null:
		push_warning("Failed to load texture: %s" % texture_path)

	self.custom_minimum_size = Vector2(80, 120)
	self.ignore_texture_size = true
	self.stretch_mode = STRETCH_KEEP_ASPECT_CENTERED

func _on_pressed() -> void:
	emit_signal("selected", self)

func select() -> void:
	position.y = original_position.y - 30
	modulate = Color("lightcyan")

func deselect() -> void:
	position = original_position
	modulate = Color.WHITE
