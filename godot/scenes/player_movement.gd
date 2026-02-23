extends Node
class_name PlayerMovement

func physics_step(player: Player, direction: float, delta: float) -> void:
	if _handle_ladder_movement(player, direction):
		return

	if player.update_ledge_hang():
		return

	_tick_jump_buffer(player, delta)
	_tick_drop_through(player, delta)
	_tick_dash_timers(player, delta)
	_try_start_ground_pound(player)

	if _try_dash(player, direction):
		return

	if _update_ground_pound(player):
		return

	if _try_drop_through(player):
		return

	_try_start_ledge_hang(player, direction)
	if player.is_ledge_hanging:
		return

	if not player.is_on_floor():
		var gravity_scale: float = player.movement_data.gravity_scale
		if player.is_in_water:
			gravity_scale *= 0.35
		player.velocity.y += player.get_gravity_strength() * gravity_scale * delta
		if player.is_in_water:
			player.velocity.y = min(player.velocity.y, 95.0)
		_apply_wall_slide(player, direction)
	else:
		player.has_wall_jumped_left = true
		player.has_wall_jumped_right = true
		player.refresh_air_jumps_on_floor()

	_handle_acceleration(player, direction, delta)
	_jump(player)
	_handle_wall_jump(player)
	var was_on_floor: bool = player.is_on_floor()
	player.move_and_slide()
	_apply_platform_carry(player)
	_try_stomp_bounce(player)
	var over_ledge: bool = was_on_floor and not player.is_on_floor() and player.velocity.y >= 0.0
	if over_ledge:
		player.coyote_time.start()

func _handle_ladder_movement(player: Player, direction: float) -> bool:
	if not player.is_on_ladder:
		return false
	var climb_axis: float = Input.get_axis("move_up", "move_down")
	if abs(climb_axis) > 0.01:
		player.velocity.y = climb_axis * 70.0
	else:
		player.velocity.y = 0.0
	player.velocity.x = move_toward(player.velocity.x, direction * player.movement_data.speed * 0.65, player.movement_data.acceleration * get_physics_process_delta_time())
	if Input.is_action_just_pressed("move_up"):
		player.velocity.y = player.movement_data.jump_velocity * 0.8
		player.is_on_ladder = false
		player.ladder_contacts = 0
	player.move_and_slide()
	return true

func _tick_dash_timers(player: Player, delta: float) -> void:
	if player.dash_time_left > 0.0:
		player.dash_time_left = max(0.0, player.dash_time_left - delta)
	if player.dash_cooldown_left > 0.0:
		player.dash_cooldown_left = max(0.0, player.dash_cooldown_left - delta)

func _try_dash(player: Player, direction: float) -> bool:
	if player.is_ground_pounding:
		return false
	player.stop_ledge_hang()
	if player.dash_time_left > 0.0:
		var dash_dir: float = 1.0 if player.animated_sprite_2d.flip_h == false else -1.0
		player.velocity = Vector2(dash_dir * player.movement_data.dash_speed, 0)
		player.move_and_slide()
		_try_breakables(player, &"dash")
		return true
	if not Input.is_action_just_pressed("dash"):
		return false
	if player.dash_cooldown_left > 0.0:
		return false
	var dash_dir: float = direction
	if dash_dir == 0:
		dash_dir = 1.0 if player.animated_sprite_2d.flip_h == false else -1.0
	player.animated_sprite_2d.flip_h = dash_dir < 0
	player.dash_time_left = player.movement_data.dash_duration_seconds
	player.dash_cooldown_left = player.movement_data.dash_cooldown_seconds
	player.start_dash_invulnerability()
	player.play_dash_feedback()
	player.velocity = Vector2(dash_dir * player.movement_data.dash_speed, 0)
	player.move_and_slide()
	_try_breakables(player, &"dash")
	return true

func _apply_wall_slide(player: Player, direction: float) -> void:
	if not player.is_on_wall_only():
		return
	var wall_normal: Vector2 = player.get_wall_normal()
	var pressing_into_wall: bool = (wall_normal == Vector2.LEFT and direction < 0.0) or (wall_normal == Vector2.RIGHT and direction > 0.0)
	if pressing_into_wall:
		player.velocity.y = min(player.velocity.y, player.movement_data.wall_slide_max_fall_speed)

func _try_stomp_bounce(player: Player) -> void:
	if player.velocity.y < 0:
		return
	for i in range(player.get_slide_collision_count()):
		var collision: KinematicCollision2D = player.get_slide_collision(i)
		if collision == null:
			continue
		var collider: Node = collision.get_collider() as Node
		if collider == null:
			continue
		if not collider.is_in_group("enemy"):
			continue
		if collision.get_normal().y < -0.7:
			if collider.has_method("receive_damage"):
				collider.call("receive_damage", player.movement_data.stomp_damage, player)
			if player.is_ground_pounding:
				player.velocity.y = player.movement_data.ground_pound_bounce_velocity
				player.is_ground_pounding = false
				player.play_ground_pound_feedback()
			else:
				player.velocity.y = player.movement_data.stomp_bounce_velocity
				player.play_stomp_feedback()
			return

func _apply_platform_carry(player: Player) -> void:
	if not player.is_on_floor():
		return
	for i in range(player.get_slide_collision_count()):
		var collision: KinematicCollision2D = player.get_slide_collision(i)
		if collision == null:
			continue
		var collider: Node = collision.get_collider() as Node
		if collider != null and collider.has_method("get_platform_velocity"):
			player.global_position += collider.call("get_platform_velocity") * get_physics_process_delta_time()
			return

func _tick_jump_buffer(player: Player, delta: float) -> void:
	if Input.is_action_just_pressed("move_up"):
		player.jump_buffer_time_left = player.movement_data.jump_buffer_seconds
	elif player.jump_buffer_time_left > 0.0:
		player.jump_buffer_time_left = max(0.0, player.jump_buffer_time_left - delta)

func _tick_drop_through(player: Player, delta: float) -> void:
	if player.drop_through_time_left <= 0.0:
		return
	player.drop_through_time_left = max(0.0, player.drop_through_time_left - delta)
	if player.drop_through_time_left == 0.0:
		player.set_one_way_collision_enabled(true)

func _try_drop_through(player: Player) -> bool:
	if not player.is_on_floor():
		return false
	if not Input.is_action_pressed("move_down"):
		return false
	if not Input.is_action_just_pressed("move_up"):
		return false
	player.drop_through_time_left = player.movement_data.drop_through_seconds
	player.set_one_way_collision_enabled(false)
	player.global_position.y += 2.0
	player.jump_buffer_time_left = 0.0
	return true

func _jump(player: Player) -> void:
	if player.is_on_floor() or player.coyote_time.time_left > 0.0:
		if player.jump_buffer_time_left > 0.0:
			player.velocity.y = player.movement_data.jump_velocity
			player.jump_buffer_time_left = 0.0
			player.is_ground_pounding = false
	elif player.jump_buffer_time_left > 0.0 and player.can_use_air_jump():
		player.velocity.y = player.movement_data.jump_velocity
		player.jump_buffer_time_left = 0.0
		player.air_jumps_left -= 1
		player.is_ground_pounding = false
	if not player.is_on_floor():
		if Input.is_action_just_released("move_up") and player.velocity.y < player.movement_data.jump_velocity / 2:
			player.velocity.y = player.movement_data.jump_velocity / 2

func _try_start_ground_pound(player: Player) -> void:
	if player.is_on_floor():
		return
	if player.is_ground_pounding:
		return
	if not Input.is_action_pressed("move_down"):
		return
	if not Input.is_action_just_pressed("dash"):
		return
	player.is_ground_pounding = true
	player.velocity.x = 0.0
	player.velocity.y = max(player.velocity.y, 0.0)
	player.play_ground_pound_feedback()

func _update_ground_pound(player: Player) -> bool:
	if not player.is_ground_pounding:
		return false
	player.velocity.x = 0.0
	player.velocity.y = player.movement_data.ground_pound_speed
	player.move_and_slide()
	_try_breakables(player, &"ground_pound")
	if player.is_on_floor():
		player.is_ground_pounding = false
		player.play_ground_pound_feedback()
	return true

func _try_start_ledge_hang(player: Player, direction: float) -> void:
	if player.is_on_floor():
		return
	if player.is_ground_pounding or player.dash_time_left > 0.0:
		return
	if player.velocity.y < 0.0:
		return
	var side: int = player.detect_ledge_side(direction)
	if side == 0:
		return
	player.start_ledge_hang(side)

func _try_breakables(player: Player, impact_kind: StringName) -> void:
	for i in range(player.get_slide_collision_count()):
		var collision: KinematicCollision2D = player.get_slide_collision(i)
		if collision == null:
			continue
		var collider: Node = collision.get_collider() as Node
		if collider != null and collider.has_method("try_break"):
			collider.call("try_break", impact_kind)

func _handle_acceleration(player: Player, direction: float, delta: float) -> void:
	var acceleration: float
	if player.is_dying:
		return
	if player.is_on_floor():
		acceleration = player.movement_data.acceleration
	else:
		acceleration = player.movement_data.air_acceleration
	if direction:
		player.velocity.x = move_toward(player.velocity.x, player.movement_data.speed * direction, acceleration * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.movement_data.friction * delta)

func _handle_wall_jump(player: Player) -> void:
	if not player.is_on_wall_only():
		return
	var wall_normal: Vector2 = player.get_wall_normal()
	if Input.is_action_just_pressed("move_left") and wall_normal == Vector2.LEFT and player.has_wall_jumped_left:
		player.velocity.x = wall_normal.x * player.movement_data.speed
		player.velocity.y = player.movement_data.jump_velocity
		player.has_wall_jumped_left = false
		player.has_wall_jumped_right = true
	if Input.is_action_just_pressed("move_right") and wall_normal == Vector2.RIGHT and player.has_wall_jumped_right:
		player.velocity.x = wall_normal.x * player.movement_data.speed
		player.velocity.y = player.movement_data.jump_velocity
		player.has_wall_jumped_left = true
		player.has_wall_jumped_right = false
