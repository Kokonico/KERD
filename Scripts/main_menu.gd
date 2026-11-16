extends Control

const GAME_SCENE := "res://Scenes/game.tscn"
const SETTINGS_SCENE := "res://Scenes/settings.tscn"

@onready var new_game_button: Button = $"VBoxContainer/New Game"
@onready var continue_game_button: Button = $"VBoxContainer/Continue Game"
@onready var settings_button: Button = $VBoxContainer/Settings

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	new_game_button.grab_focus()

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)
