extends CharacterBody2D
class_name EnemyStateMachine

@export var config: EnemyConfig
@export var target_group: StringName = &"player"
@export var projectile_scene: PackedScene = preload("res://scenes/enemy_projectile.tscn")
@export var collectible_pickup_scene: PackedScene = preload("res://scenes/collectible_pickup.tscn")
@export var loot_table: EnemyLootTable
@export var elite: bool = false
@export_range(1.0, 3.0, 0.1) var elite_health_multiplier: float = 1.8
@export_range(1.0, 2.5, 0.1) var elite_speed_multiplier: float = 1.25

@onready var raycast: RayCast2D = $RayCast2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_right: bool = false
var attack_cooldown_left: float = 0.0
var alert_time_left: float = 0.0
var hit_points: int = 1
var target: Player
var current_state: EnemyState

var state_idle: EnemyIdleState = EnemyIdleState.new()
var state_patrol: EnemyPatrolState = EnemyPatrolState.new()
var state_alert: EnemyAlertState = EnemyAlertState.new()
var state_chase: EnemyChaseState = EnemyChaseState.new()
var state_attack: EnemyAttackState = EnemyAttackState.new()

func _ready() -> void:
	if config == null:
		config = load("res://custom_resources/enemy/default_enemy_config.tres")
	hit_points = config.max_health
	if elite:
		hit_points = int(ceil(float(hit_points) * elite_health_multiplier))
		config = config.duplicate()
		config.patrol_speed *= elite_speed_multiplier
		config.chase_speed *= elite_speed_multiplier
		config.attack_cooldown *= 0.9
	if animated_sprite != null:
		animated_sprite.play("walk")
		if elite:
			animated_sprite.modulate = Color(1.0, 0.85, 0.45, 1.0)
	_change_state(state_patrol)

func _physics_process(delta: float) -> void:
	if attack_cooldown_left > 0.0:
		attack_cooldown_left = max(0.0, attack_cooldown_left - delta)
	if alert_time_left > 0.0:
		alert_time_left = max(0.0, alert_time_left - delta)
	target = _get_closest_target()
	if current_state != null:
		current_state.physics_update(self, delta)

func _change_state(next_state: EnemyState) -> void:
	if current_state != null:
		current_state.exit(self)
	current_state = next_state
	if current_state != null:
		current_state.enter(self)

func request_state_patrol() -> void:
	_change_state(state_patrol)

func request_state_chase() -> void:
	_change_state(state_chase)

func request_state_alert() -> void:
	_change_state(state_alert)

func request_state_attack() -> void:
	_change_state(state_attack)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * config.gravity_scale * delta

func move_and_turn(speed: float, delta: float) -> void:
	velocity.x = -speed if not facing_right else speed
	move_and_slide()
	if raycast != null and not raycast.is_colliding() and is_on_floor():
		flip()

func flip() -> void:
	facing_right = not facing_right
	scale.x = abs(scale.x) * (-1 if facing_right else 1)

func can_attack_target() -> bool:
	if target == null:
		return false
	return global_position.distance_to(target.global_position) <= config.attack_range and attack_cooldown_left <= 0.0

func in_chase_range() -> bool:
	if target == null:
		return false
	if config.requires_line_of_sight and not has_line_of_sight_to_target():
		return false
	return global_position.distance_to(target.global_position) <= config.chase_range

func trigger_attack() -> void:
	attack_cooldown_left = config.attack_cooldown
	perform_attack()

func perform_attack() -> void:
	if target == null:
		return
	if not config.use_ranged_attack:
		return
	var projectile: EnemyProjectile = _spawn_projectile()
	if projectile == null:
		return
	var dir: Vector2 = (target.global_position - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT if facing_right else Vector2.LEFT
	projectile.direction = dir
	projectile.speed = config.projectile_speed
	projectile.lifetime_seconds = config.projectile_lifetime_seconds

func should_use_alert_state() -> bool:
	return config.use_alert_state and config.alert_duration_seconds > 0.0

func start_alert_timer() -> void:
	alert_time_left = config.alert_duration_seconds

func is_alerting() -> bool:
	return alert_time_left > 0.0

func should_enter_alert() -> bool:
	if not should_use_alert_state():
		return false
	return in_chase_range()

func has_line_of_sight_to_target() -> bool:
	if target == null:
		return false
	var params: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.exclude = [get_rid()]
	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(params)
	if result.is_empty():
		return true
	var collider: Variant = result.get("collider")
	return collider == target

func _get_closest_target() -> Player:
	var closest: Player
	var closest_distance: float = INF
	for node in get_tree().get_nodes_in_group(String(target_group)):
		if node is Player:
			var distance: float = global_position.distance_to(node.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest = node
	return closest

func receive_damage(_amount: int, _source: Node) -> void:
	if _is_blocking_source(_source):
		return
	hit_points = max(0, hit_points - _amount)
	if hit_points <= 0:
		_drop_loot()
		queue_free()

func _is_blocking_source(source: Node) -> bool:
	if not config.shielded_front_only:
		return false
	if not (source is Node2D):
		return false
	var source_node: Node2D = source as Node2D
	var incoming: Vector2 = (source_node.global_position - global_position).normalized()
	if incoming == Vector2.ZERO:
		return false
	var facing: Vector2 = Vector2.RIGHT if facing_right else Vector2.LEFT
	var half_angle_rad: float = deg_to_rad(config.shield_block_angle_degrees * 0.5)
	var min_dot: float = cos(half_angle_rad)
	return facing.dot(incoming) >= min_dot

func _spawn_projectile() -> EnemyProjectile:
	if projectile_scene == null:
		return null
	var projectile: Node = projectile_scene.instantiate()
	if not (projectile is EnemyProjectile):
		return null
	var parent: Node = get_parent()
	if parent == null:
		return null
	parent.add_child(projectile)
	projectile.global_position = global_position + Vector2(0, -6)
	return projectile

func _drop_loot() -> void:
	if loot_table == null or collectible_pickup_scene == null:
		return
	for entry in loot_table.entries:
		if entry == null:
			continue
		if randf() > entry.drop_chance:
			continue
		var pickup_node: Node = collectible_pickup_scene.instantiate()
		if pickup_node is CollectiblePickup:
			var pickup: CollectiblePickup = pickup_node as CollectiblePickup
			pickup.collectible_type = entry.collectible_type
			pickup.collectible_id = entry.collectible_id
			pickup.global_position = global_position + Vector2(0, -8)
			get_parent().add_child(pickup)
