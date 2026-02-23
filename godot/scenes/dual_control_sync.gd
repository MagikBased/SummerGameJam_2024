extends RefCounted
class_name DualControlSync

func wire_players(left_player: Player, right_player: Player, coordinator: Node) -> void:
	left_player.coordinator = coordinator
	right_player.coordinator = coordinator
	left_player.linked_player = right_player
	right_player.linked_player = left_player
	left_player.is_left_player = true
	right_player.is_left_player = false
	right_player.control_state = not left_player.control_state

func flip_controls(left_player: Player, right_player: Player) -> void:
	var temp_velocity := left_player.velocity
	left_player.velocity = right_player.velocity
	right_player.velocity = temp_velocity
	left_player.control_state = not left_player.control_state
	right_player.control_state = not right_player.control_state

func sync_inactive_player(left_player: Player, right_player: Player) -> void:
	if left_player.control_state:
		right_player.global_position = left_player.global_position
		right_player.velocity = left_player.velocity
	else:
		left_player.global_position = right_player.global_position
		left_player.velocity = right_player.velocity
