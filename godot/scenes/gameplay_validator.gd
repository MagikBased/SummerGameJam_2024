extends Node
class_name GameplayValidator

const REQUIRED_ACTIONS := [
	"move_left",
	"move_right",
	"move_up",
	"move_down",
	"interact",
	"dash",
	"pause",
	"restart"
]

func _ready() -> void:
	call_deferred("_validate")

func _validate() -> void:
	_validate_actions()
	_validate_main_wiring()

func _validate_actions() -> void:
	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			push_error("Missing input action: %s" % action)

func _validate_main_wiring() -> void:
	var main := get_parent()
	if main == null:
		return
	var left_lane: CharacterLane = main.get_node_or_null("HBoxContainer/SubViewportContainer/SubViewport/LeftLane")
	var right_lane: CharacterLane = main.get_node_or_null("HBoxContainer/SubViewportContainer2/SubViewport2/RightLane")
	if left_lane == null or right_lane == null:
		push_error("Missing left or right lane instance in main scene.")
		return
	_validate_player(left_lane.get_player(), &"left")
	_validate_player(right_lane.get_player(), &"right")
	left_lane.get_lane_world().validate_checkpoint_ids()
	right_lane.get_lane_world().validate_checkpoint_ids()

func _validate_player(player: Player, expected_lane_id: StringName) -> void:
	if player == null:
		push_error("Missing player for lane: %s" % String(expected_lane_id))
		return
	if player.lane_id != expected_lane_id:
		push_error("Player lane_id mismatch. expected=%s actual=%s" % [String(expected_lane_id), String(player.lane_id)])
	if player.get_node_or_null("PlayerMovement") == null:
		push_error("PlayerMovement node missing on player.")
	if player.get_node_or_null("PlayerVisuals") == null:
		push_error("PlayerVisuals node missing on player.")
	if player.get_node_or_null("PlayerLife") == null:
		push_error("PlayerLife node missing on player.")
	if player.get_node_or_null("LedgeWallRayLeft") == null:
		push_error("LedgeWallRayLeft node missing on player.")
	if player.get_node_or_null("LedgeWallRayRight") == null:
		push_error("LedgeWallRayRight node missing on player.")
	if player.get_node_or_null("LedgeTopRayLeft") == null:
		push_error("LedgeTopRayLeft node missing on player.")
	if player.get_node_or_null("LedgeTopRayRight") == null:
		push_error("LedgeTopRayRight node missing on player.")
