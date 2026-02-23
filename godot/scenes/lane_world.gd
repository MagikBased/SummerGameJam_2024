extends Node2D
class_name LaneWorld

@export var lane_id: StringName = &""
@export var initial_checkpoint_id: int = 0

@onready var player: Player = $Player
@onready var checkpoints_root: Node = $Checkpoints

func get_player() -> Player:
	return player

func set_lane_id(id: StringName) -> void:
	lane_id = id
	player.set_lane_id(id)

func initialize_checkpoint() -> void:
	GameManager.ensure_initial_checkpoint(initial_checkpoint_id, lane_id)

func get_checkpoint(checkpoint_id: int) -> Checkpoint:
	if checkpoints_root == null:
		return null
	for child in checkpoints_root.get_children():
		if child is Checkpoint and child.checkpoint_id == checkpoint_id:
			return child
	return null

func validate_checkpoint_ids() -> void:
	if checkpoints_root == null:
		return
	var seen := {}
	for child in checkpoints_root.get_children():
		if child is Checkpoint:
			if seen.has(child.checkpoint_id):
				push_error("Duplicate checkpoint_id in lane '%s': %d" % [String(lane_id), child.checkpoint_id])
			else:
				seen[child.checkpoint_id] = true
