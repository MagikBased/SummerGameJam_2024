extends Node

var current_checkpoint: Checkpoint
#var player: Player

func do_victory():
	var labels = get_tree().get_nodes_in_group("victory")
	for label in labels:
		label.visible = true

func respawn_player(player: Player):
	#print(current_checkpoint)
	if player.is_left_player:
		player.velocity.x = 0
		player.velocity.y = 0
		player.global_position = current_checkpoint.global_position
		if player.control_state == false:
			player.control_state_controller.flip_control_states()
	else:
		if player.control_state:
			player.control_state_controller.flip_control_states()
		player.other_player.velocity.x = 0
		player.other_player.velocity.y = 0
		player.other_player.global_position = current_checkpoint.global_position

