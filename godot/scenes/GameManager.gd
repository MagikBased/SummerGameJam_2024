extends Node

var current_checkpoint_id: int = -1
var lane_respawn_points: Dictionary = {}
signal victory_triggered
signal checkpoint_updated(checkpoint_id: int, source_lane_id: StringName)

func trigger_victory() -> void:
	emit_signal("victory_triggered")

# Legacy alias kept for compatibility with existing callers.
func do_victory() -> void:
	trigger_victory()

func set_current_checkpoint(checkpoint_id: int, source_lane_id: StringName) -> void:
	current_checkpoint_id = checkpoint_id
	emit_signal("checkpoint_updated", checkpoint_id, source_lane_id)

func ensure_initial_checkpoint(checkpoint_id: int, source_lane_id: StringName) -> void:
	if current_checkpoint_id != -1:
		return
	set_current_checkpoint(checkpoint_id, source_lane_id)

func set_lane_respawn_point(lane_id: StringName, point: Vector2) -> void:
	lane_respawn_points[lane_id] = point

func get_lane_respawn_point(lane_id: StringName) -> Variant:
	return lane_respawn_points.get(lane_id, null)

func respawn_player(player: Player):
	if current_checkpoint_id == -1:
		return
	var partner := player.get_partner_player()
	_reset_player_at_checkpoint(player)
	if partner != null:
		_reset_player_at_checkpoint(partner)
	if partner != null and player.control_state == partner.control_state:
		partner.control_state = not player.control_state

func _reset_player_at_checkpoint(player: Player) -> void:
	var respawn: Variant = get_lane_respawn_point(player.lane_id)
	if respawn == null:
		return
	player.velocity = Vector2.ZERO
	player.global_position = respawn
	player.set_respawn_point(respawn)
	player.reset_after_respawn()

func serialize_state() -> Dictionary:
	var packed_respawns := {}
	for lane_id in lane_respawn_points.keys():
		var point: Vector2 = lane_respawn_points[lane_id]
		packed_respawns[String(lane_id)] = [point.x, point.y]
	return {
		"checkpoint_id": current_checkpoint_id,
		"lane_respawns": packed_respawns
	}

func restore_state(data: Dictionary) -> void:
	current_checkpoint_id = int(data.get("checkpoint_id", -1))
	lane_respawn_points.clear()
	var packed_respawns: Dictionary = data.get("lane_respawns", {})
	for key in packed_respawns.keys():
		var values = packed_respawns[key]
		if values is Array and values.size() == 2:
			lane_respawn_points[StringName(key)] = Vector2(values[0], values[1])
	if current_checkpoint_id != -1:
		emit_signal("checkpoint_updated", current_checkpoint_id, &"restored")

