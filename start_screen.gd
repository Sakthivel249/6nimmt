extends Node

func _ready():
	$TextureRect.texture = load("res://Entrance.png")
	$start_button.text = "Start"

# This function runs when the StartButton is pressed
func _on_start_button_pressed():
	# Move the command here
	get_tree().change_scene_to_file("res://MainScene.tscn")
