extends Node2D

@onready var left_player = $"../LeftPlayer"
@onready var right_player = $"../RightPlayer"

signal states_flipped


func flip_control_states():
	var temp_velocity = left_player.velocity
	left_player.velocity = right_player.velocity
	right_player.velocity = temp_velocity

	left_player.control_state = not left_player.control_state
	right_player.control_state = not right_player.control_state
	
	emit_signal("states_flipped")
