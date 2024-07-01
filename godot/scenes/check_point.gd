extends AnimatedSprite2D
class_name Checkpoint

var raised: bool = false
var spawnpoint:bool = false
@export var player_checkpoint_left: bool = false

func activate() -> void:
	GameManager.current_checkpoint = self
	play("raised")
	raised = true

func _on_area_2d_area_entered(area):
	if area.get_parent() is Player && !raised:
		var player = area.get_parent() as Player
		player_checkpoint_left = player.is_left_player
		activate()
