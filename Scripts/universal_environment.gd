extends Node3D

@onready var environment_node: WorldEnvironment = $EnvironmentNode

func _ready() -> void:
	Settings.changed.connect(_apply_settings)
	_apply_settings()

func _apply_settings() -> void:
	var environment := environment_node.environment
	environment.ssao_enabled = Settings.ssao
	environment.ssil_enabled = Settings.ssil
	environment.glow_enabled = Settings.glow
