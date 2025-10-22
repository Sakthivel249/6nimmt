extends TextureButton
signal selected(card_node)

var card_number: int = 0
var original_position: Vector2

func _ready() -> void:
	original_position = self.position
	connect("pressed", Callable(self, "_on_pressed"))  


func initialize(number: int) -> void:
	card_number = number
	var texture_path = "res://6nimmt_cards/card_%03d.png" % card_number
	self.texture_normal = load(texture_path)

	self.custom_minimum_size = Vector2(80, 120)
	self.ignore_texture_size = true
	self.stretch_mode = STRETCH_KEEP_ASPECT_CENTERED

func _on_pressed() -> void:
	emit_signal("selected", self)
