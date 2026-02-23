extends Node
class_name PlayerVisuals

func update_animations(player: Player, direction: float) -> void:
	if player.is_dying:
		return
	if player.dash_time_left > 0.0:
		player.animated_sprite_2d.play("dash")
		return
	if player.is_ledge_hanging:
		player.animated_sprite_2d.play("jump")
		return
	if player.is_ground_pounding:
		player.animated_sprite_2d.play("fall_fast")
		return
	if direction != 0:
		player.animated_sprite_2d.flip_h = direction < 0
		player.animated_sprite_2d.play("run")
	else:
		player.animated_sprite_2d.play("idle")
	if not player.is_on_floor() and player.velocity.y > 40.0:
		player.animated_sprite_2d.play("fall_fast")
	elif not player.is_on_floor():
		player.animated_sprite_2d.play("jump")

func update_hurt_flash(player: Player) -> void:
	if player.invulnerability_left > 0.0:
		var blink := int(Time.get_ticks_msec() / 70) % 2 == 0
		player.animated_sprite_2d.modulate.a = 0.55 if blink else 1.0
	else:
		player.animated_sprite_2d.modulate = Color(1, 1, 1, 1)
