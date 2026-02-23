extends CharacterBody2D
class_name Player

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var coyote_time = $CoyoteTime
@onready var body_collision_shape: CollisionShape2D = $CollisionShape2D
@onready var ledge_wall_ray_left: RayCast2D = $LedgeWallRayLeft
@onready var ledge_wall_ray_right: RayCast2D = $LedgeWallRayRight
@onready var ledge_top_ray_left: RayCast2D = $LedgeTopRayLeft
@onready var ledge_top_ray_right: RayCast2D = $LedgeTopRayRight
@onready var movement_component: PlayerMovement = $PlayerMovement
@onready var visuals_component: PlayerVisuals = $PlayerVisuals
@onready var life_component: PlayerLife = $PlayerLife
@onready var dash_sfx: AudioStreamPlayer2D = $DashSfx
@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSfx
@onready var pound_sfx: AudioStreamPlayer2D = $PoundSfx
@onready var dash_vfx: GPUParticles2D = $DashVfx
@onready var impact_vfx: GPUParticles2D = $ImpactVfx
@onready var landing_vfx: GPUParticles2D = $LandingVfx
@onready var speed_vfx: GPUParticles2D = $SpeedVfx
@onready var footstep_sfx: AudioStreamPlayer2D = $FootstepSfx

@export var movement_data: PlayerMovementData
@export var linked_player: Player
@export var coordinator: Node
@export var lane_id: StringName = &""
@export var control_state: bool = true
@export var is_left_player: bool
@export var death_rise_distance: float = 60.0
@export var death_fall_distance: float = 50.0
@export var death_rise_speed: float = 4.0
@export var death_fall_speed: float = 3.0
@export var death_step_seconds: float = 0.01
@export var max_hit_points: int = 1
@export var ledge_grab_enabled: bool = true
@export var ledge_snap_x_offset: float = 6.0
@export var ledge_climb_offset: Vector2 = Vector2(8.0, -12.0)
@export var landing_impact_threshold: float = 110.0
@export var speed_line_threshold: float = 135.0
@export var footstep_interval_seconds: float = 0.26
signal victory

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var has_wall_jumped_left: bool = false
var has_wall_jumped_right: bool = false
var respawn_point: Vector2
var is_dying: bool = false
var jump_buffer_time_left: float = 0.0
var drop_through_time_left: float = 0.0
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var invulnerability_left: float = 0.0
var hit_points: int = 1
var air_jumps_left: int = 0
var is_ground_pounding: bool = false
var is_ledge_hanging: bool = false
var ledge_side: int = 0
var footstep_time_left: float = 0.0
var is_on_ladder: bool = false
var ladder_contacts: int = 0
var is_in_water: bool = false
var water_contacts: int = 0

func _ready() -> void:
	respawn_point = global_position
	hit_points = max_hit_points
	air_jumps_left = movement_data.max_air_jumps if movement_data != null else 0
	if movement_data != null:
		coyote_time.wait_time = movement_data.coyote_time_seconds
	call_deferred("_validate_wiring")

func _validate_wiring() -> void:
	if movement_data == null:
		push_error("Player wiring failed: movement_data is not assigned.")
		set_physics_process(false)
		return
	if linked_player == null:
		push_error("Player wiring failed: linked_player is not assigned.")
		set_physics_process(false)
		return
	if coordinator == null:
		push_error("Player wiring failed: coordinator is not assigned.")
		set_physics_process(false)
		return
	if lane_id == &"":
		push_error("Player wiring failed: lane_id is not assigned.")
		set_physics_process(false)
		return

func _physics_process(delta):
	if is_dying: return
	if invulnerability_left > 0.0:
		invulnerability_left = max(0.0, invulnerability_left - delta)
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		
	var direction = Input.get_axis("move_left", "move_right")
	visuals_component.update_animations(self, direction)
	visuals_component.update_hurt_flash(self)
	
	if Input.is_action_just_pressed("interact") and is_left_player:
		if coordinator != null and coordinator.has_method("request_flip_controls"):
			coordinator.request_flip_controls()
	
	if control_state:
		var was_on_floor := is_on_floor()
		var pre_velocity_y := velocity.y
		movement_component.physics_step(self, direction, delta)
		_post_movement_feedback(was_on_floor, pre_velocity_y, delta)
	else:
		var partner := get_partner_player()
		if partner != null:
			global_position = partner.global_position
			velocity = partner.velocity

func _on_hurt_box_area_entered(area):
	var damage := 1
	if area != null and "damage" in area:
		damage = int(area.damage)
	receive_damage(damage, area)
	var partner := get_partner_player()
	if control_state and partner != null:
		partner.receive_damage(damage, area)

func can_flip_control() -> bool:
	var partner := get_partner_player()
	if partner == null:
		return false
	return not partner.is_on_floor() and not partner.is_on_wall()

func die() -> void:
	life_component.die(self)

func receive_damage(_amount: int, _source: Node = null) -> void:
	if is_dying or invulnerability_left > 0.0:
		return
	hit_points = max(0, hit_points - _amount)
	invulnerability_left = movement_data.damage_invulnerability_seconds
	play_hurt_feedback()
	if hit_points <= 0:
		die()

func get_partner_player() -> Player:
	return linked_player

func get_gravity_strength() -> float:
	return gravity

func set_respawn_point(point: Vector2) -> void:
	respawn_point = point

func set_lane_id(id: StringName) -> void:
	lane_id = id

func is_overlapping_terrain() -> bool:
	if body_collision_shape == null or body_collision_shape.shape == null:
		return false
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = body_collision_shape.shape
	params.transform = body_collision_shape.global_transform
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.exclude = [get_rid()]
	params.collision_mask = collision_mask
	var results := get_world_2d().direct_space_state.intersect_shape(params, 1)
	return not results.is_empty()

func try_resolve_terrain_overlap(max_snap_pixels: int) -> bool:
	if not is_overlapping_terrain():
		return true
	var origin := global_position
	var snap_dirs := [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT,
		Vector2(-1, -1),
		Vector2(1, -1),
		Vector2(-1, 1),
		Vector2(1, 1)
	]
	for distance in range(1, max_snap_pixels + 1):
		for dir in snap_dirs:
			global_position = origin + dir.normalized() * float(distance)
			if not is_overlapping_terrain():
				velocity = Vector2.ZERO
				return true
	global_position = origin
	return false

func set_one_way_collision_enabled(enabled: bool) -> void:
	set_collision_mask_value(movement_data.one_way_collision_layer, enabled)

func set_ladder_contact(active: bool) -> void:
	if active:
		ladder_contacts += 1
	else:
		ladder_contacts = max(0, ladder_contacts - 1)
	is_on_ladder = ladder_contacts > 0
	if is_on_ladder:
		is_ground_pounding = false

func set_water_contact(active: bool) -> void:
	if active:
		water_contacts += 1
	else:
		water_contacts = max(0, water_contacts - 1)
	is_in_water = water_contacts > 0

func start_dash_invulnerability() -> void:
	invulnerability_left = max(invulnerability_left, movement_data.dash_invulnerability_seconds)

func reset_after_respawn() -> void:
	hit_points = max_hit_points
	invulnerability_left = 0.0
	dash_time_left = 0.0
	dash_cooldown_left = 0.0
	air_jumps_left = movement_data.max_air_jumps
	is_ground_pounding = false
	is_ledge_hanging = false
	ledge_side = 0
	is_on_ladder = false
	ladder_contacts = 0
	is_in_water = false
	water_contacts = 0
	animated_sprite_2d.modulate = Color(1, 1, 1, 1)

func refresh_air_jumps_on_floor() -> void:
	air_jumps_left = movement_data.max_air_jumps
	is_ground_pounding = false

func can_use_air_jump() -> bool:
	if air_jumps_left <= 0:
		return false
	if movement_data.double_jump_unlock_ability == &"":
		return true
	return GameProgression.has_ability(movement_data.double_jump_unlock_ability)

func play_dash_feedback() -> void:
	if dash_sfx != null:
		dash_sfx.play()
	if dash_vfx != null:
		dash_vfx.restart()
		dash_vfx.emitting = true

func play_ground_pound_feedback() -> void:
	if pound_sfx != null:
		pound_sfx.play()
	if impact_vfx != null:
		impact_vfx.restart()
		impact_vfx.emitting = true

func play_stomp_feedback() -> void:
	if impact_vfx != null:
		impact_vfx.restart()
		impact_vfx.emitting = true

func play_hurt_feedback() -> void:
	if hurt_sfx != null:
		hurt_sfx.play()

func _post_movement_feedback(was_on_floor: bool, pre_velocity_y: float, delta: float) -> void:
	if not was_on_floor and is_on_floor() and pre_velocity_y > landing_impact_threshold:
		if landing_vfx != null:
			landing_vfx.restart()
			landing_vfx.emitting = true
	var moving_fast: bool = abs(velocity.x) >= speed_line_threshold and not is_on_floor()
	if speed_vfx != null:
		speed_vfx.emitting = moving_fast
		speed_vfx.amount_ratio = clamp(abs(velocity.x) / max(speed_line_threshold * 2.0, 1.0), 0.25, 1.0)
	_update_footsteps(delta)

func _update_footsteps(delta: float) -> void:
	if footstep_sfx == null:
		return
	if not is_on_floor() or abs(velocity.x) < 18.0:
		footstep_time_left = 0.0
		return
	footstep_time_left = max(0.0, footstep_time_left - delta)
	if footstep_time_left > 0.0:
		return
	footstep_time_left = footstep_interval_seconds
	footstep_sfx.pitch_scale = randf_range(0.94, 1.08)
	footstep_sfx.play()

func detect_ledge_side(direction: float) -> int:
	if not ledge_grab_enabled:
		return 0
	if direction < 0 and ledge_wall_ray_left != null and ledge_top_ray_left != null:
		if ledge_wall_ray_left.is_colliding() and not ledge_top_ray_left.is_colliding():
			return -1
	if direction > 0 and ledge_wall_ray_right != null and ledge_top_ray_right != null:
		if ledge_wall_ray_right.is_colliding() and not ledge_top_ray_right.is_colliding():
			return 1
	return 0

func start_ledge_hang(side: int) -> void:
	is_ledge_hanging = true
	ledge_side = side
	velocity = Vector2.ZERO
	if side < 0 and ledge_wall_ray_left != null and ledge_wall_ray_left.is_colliding():
		var point := ledge_wall_ray_left.get_collision_point()
		global_position.x = point.x + ledge_snap_x_offset
	elif side > 0 and ledge_wall_ray_right != null and ledge_wall_ray_right.is_colliding():
		var point := ledge_wall_ray_right.get_collision_point()
		global_position.x = point.x - ledge_snap_x_offset

func stop_ledge_hang() -> void:
	is_ledge_hanging = false
	ledge_side = 0

func update_ledge_hang() -> bool:
	if not is_ledge_hanging:
		return false
	velocity = Vector2.ZERO
	if Input.is_action_just_pressed("move_up"):
		var x_dir := float(ledge_side)
		global_position += Vector2(ledge_climb_offset.x * x_dir, ledge_climb_offset.y)
		stop_ledge_hang()
		velocity.y = movement_data.jump_velocity * 0.5
		return false
	if Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("dash"):
		stop_ledge_hang()
		velocity.y = 10.0
		return false
	return true
