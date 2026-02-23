extends BossController
class_name Midboss

@export var patrol_speed: float = 35.0
@export var chase_speed: float = 58.0
@export var chase_range: float = 120.0
@export var touch_damage: int = 1
@export var gravity_scale: float = 1.0
@export var base_attack_cooldown_seconds: float = 1.6
@export var projectile_scene: PackedScene = preload("res://scenes/enemy_projectile.tscn")
@export var projectile_speed: float = 170.0
@export var projectile_lifetime_seconds: float = 2.5

@onready var hitbox: DamageArea = $Hitbox

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var _facing_right: bool = false
var _attack_cooldown_left: float = 0.0
var _dash_time_left: float = 0.0

func _ready() -> void:
	super._ready()
	if hitbox != null:
		hitbox.damage = touch_damage

func _physics_process(delta: float) -> void:
	if health_component == null or not health_component.is_alive():
		return
	var phase: BossPhaseData = get_current_phase()
	if _attack_cooldown_left > 0.0:
		_attack_cooldown_left = max(0.0, _attack_cooldown_left - delta)
	if _dash_time_left > 0.0:
		_dash_time_left = max(0.0, _dash_time_left - delta)
	if not is_on_floor():
		velocity.y += _gravity * gravity_scale * delta
	var target: Player = _find_target()
	var move_speed: float = patrol_speed
	if target != null and global_position.distance_to(target.global_position) <= chase_range:
		move_speed = chase_speed
		_facing_right = target.global_position.x > global_position.x
	if phase != null:
		move_speed *= phase.move_speed_multiplier
	if _dash_time_left > 0.0:
		var dash_mult: float = phase.dash_speed_multiplier if phase != null else 1.0
		move_speed *= max(dash_mult, 1.0)
	velocity.x = move_speed if _facing_right else -move_speed
	move_and_slide()
	if is_on_wall():
		_facing_right = not _facing_right
	scale.x = abs(scale.x) * (-1 if _facing_right else 1)
	_try_attack(phase, target)
	_apply_phase_contact_damage(phase)

func receive_damage(amount: int, source: Node) -> void:
	if health_component != null:
		health_component.apply_damage(amount, source)

func _find_target() -> Player:
	var closest: Player
	var closest_distance: float = INF
	for node in get_tree().get_nodes_in_group("player"):
		if node is Player:
			var distance: float = global_position.distance_to(node.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest = node
	return closest

func _try_attack(phase: BossPhaseData, target: Player) -> void:
	if target == null or phase == null:
		return
	if _attack_cooldown_left > 0.0:
		return
	var distance: float = global_position.distance_to(target.global_position)
	if distance > chase_range:
		return
	match phase.attack_mode:
		&"single_shot":
			_fire_projectile_spread(target.global_position, 1, 0.0)
		&"triple_shot":
			_fire_projectile_spread(target.global_position, maxi(phase.projectile_count, 3), maxf(phase.projectile_spread_degrees, 20.0))
		&"dash_burst":
			_dash_time_left = 0.35
			_fire_projectile_spread(target.global_position, maxi(phase.projectile_count, 3), maxf(phase.projectile_spread_degrees, 24.0))
		_:
			_fire_projectile_spread(target.global_position, maxi(phase.projectile_count, 1), phase.projectile_spread_degrees)
	var cooldown_mult: float = maxf(phase.attack_cooldown_multiplier, 0.1)
	_attack_cooldown_left = base_attack_cooldown_seconds * cooldown_mult

func _fire_projectile_spread(target_position: Vector2, count: int, spread_degrees: float) -> void:
	if projectile_scene == null:
		return
	var center_dir: Vector2 = (target_position - global_position).normalized()
	if center_dir == Vector2.ZERO:
		center_dir = Vector2.RIGHT if _facing_right else Vector2.LEFT
	var count_clamped: int = maxi(count, 1)
	if count_clamped == 1:
		_spawn_projectile(center_dir)
		return
	var half_spread: float = spread_degrees * 0.5
	for i in range(count_clamped):
		var t: float = 0.0 if count_clamped <= 1 else float(i) / float(count_clamped - 1)
		var angle: float = deg_to_rad(lerpf(-half_spread, half_spread, t))
		_spawn_projectile(center_dir.rotated(angle))

func _spawn_projectile(direction: Vector2) -> void:
	var projectile: Node = projectile_scene.instantiate()
	if not (projectile is EnemyProjectile):
		return
	var typed: EnemyProjectile = projectile as EnemyProjectile
	typed.direction = direction.normalized()
	typed.speed = projectile_speed
	typed.lifetime_seconds = projectile_lifetime_seconds
	typed.global_position = global_position + Vector2(0, -8)
	get_parent().add_child(typed)

func _apply_phase_contact_damage(phase: BossPhaseData) -> void:
	if hitbox == null:
		return
	var bonus: int = 0
	if phase != null:
		bonus = phase.contact_damage_bonus
	hitbox.damage = touch_damage + bonus
