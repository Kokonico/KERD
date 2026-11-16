class_name KillZone
extends Area3D
# Sends the player back to the level's entry elevator

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		respawn.call_deferred(body)

func respawn(player: CharacterBody3D) -> void:
	var entry_point: Node3D = owner.get_node("ElevatorEntryPoint")
	var respawn_position := entry_point.global_position + Vector3.UP * 1.5
	if player.has_method("die"):
		player.die(respawn_position)
		return
	player.global_position = respawn_position
	player.velocity = Vector3.ZERO
