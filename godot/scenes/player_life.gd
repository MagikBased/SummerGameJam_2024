extends Node
class_name PlayerLife

func handle_hurt(player: Player) -> void:
	if not player.control_state:
		return
	die(player)
	var partner := player.get_partner_player()
	if partner != null:
		partner.die()

func die(player: Player) -> void:
	if player.is_dying:
		return
	player.is_dying = true
	player.animated_sprite_2d.play("death")
	await _move_player_death(player)
	_finish_death(player)

func _move_player_death(player: Player) -> void:
	var start_position := player.position
	var up_position := start_position + Vector2(0, -player.death_rise_distance)
	var down_position := start_position + Vector2(0, player.death_fall_distance)

	while player.position.y > up_position.y:
		player.position.y -= player.death_rise_speed
		await player.get_tree().create_timer(player.death_step_seconds).timeout
	while player.position.y < down_position.y:
		player.position.y += player.death_fall_speed
		await player.get_tree().create_timer(player.death_step_seconds).timeout

func _finish_death(player: Player) -> void:
	player.is_dying = false
	player.velocity = Vector2.ZERO
	SaveGame.record_death()
	if player.is_left_player:
		GameManager.respawn_player(player)
