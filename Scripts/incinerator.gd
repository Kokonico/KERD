extends KillZone
# Burns the player if they're still inside when the timer runs out

@export var burn_time := 4.0

var _burning := false

func _on_body_entered(body: Node3D) -> void:
	if _burning or not body is CharacterBody3D:
		return
	_burning = true
	await get_tree().create_timer(burn_time).timeout
	_burning = false
	if overlaps_body(body):
		respawn(body)
