extends RefCounted
class_name DualCheckpointSync

func apply_checkpoint(
	left_lane: CharacterLane,
	right_lane: CharacterLane,
	checkpoint_id: int
) -> void:
	var left_checkpoint := left_lane.get_lane_world().get_checkpoint(checkpoint_id)
	var right_checkpoint := right_lane.get_lane_world().get_checkpoint(checkpoint_id)
	if left_checkpoint != null:
		left_checkpoint.raise_visual_only()
		GameManager.set_lane_respawn_point(left_lane.lane_id, left_checkpoint.global_position)
	if right_checkpoint != null:
		right_checkpoint.raise_visual_only()
		GameManager.set_lane_respawn_point(right_lane.lane_id, right_checkpoint.global_position)
