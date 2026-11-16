extends Node

# The order levels are played in. Each exit elevator leads to the next entry.
const LEVEL_ORDER: Array[PackedScene] = [
	preload("res://Scenes/Levels/level_one.tscn"),
	preload("res://Scenes/Levels/level_two.tscn"),
	preload("res://Scenes/Levels/level_three.tscn"),
	preload("res://Scenes/Levels/level_four.tscn"),
	preload("res://Scenes/Levels/level_five.tscn"),
	preload("res://Scenes/Levels/level_six.tscn"),
	preload("res://Scenes/Levels/level_seven.tscn"),
]
