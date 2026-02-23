extends AnimatedSprite2D
class_name Checkpoint

var raised: bool = false
@export var checkpoint_id: int = 0

func activate(source_lane_id: StringName) -> void:
	if raised:
		return
	GameManager.set_current_checkpoint(checkpoint_id, source_lane_id)
	RunStats.record_split(checkpoint_id)
	raise_visual_only()

func raise_visual_only() -> void:
	play("raised")
	raised = true

func _on_area_2d_area_entered(area):
	if area.get_parent() is Player && !raised:
		var player = area.get_parent() as Player
		activate(player.lane_id)
