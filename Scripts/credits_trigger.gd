extends Area3D
# Rolls the credits once the player reaches it

const MAIN_MENU_SCENE := "res://Scenes/main_menu.tscn"

@export var credits_time := 5.0

@onready var credits: CanvasLayer = $Credits

func _ready() -> void:
	credits.visible = false
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if credits.visible or not body is CharacterBody3D:
		return
	credits.visible = true
	await get_tree().create_timer(credits_time).timeout
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
