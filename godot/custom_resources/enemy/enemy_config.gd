extends Resource
class_name EnemyConfig

@export var patrol_speed: float = 30.0
@export var chase_speed: float = 45.0
@export var gravity_scale: float = 1.0
@export var chase_range: float = 96.0
@export var attack_range: float = 22.0
@export var attack_cooldown: float = 0.7
@export var max_health: int = 1
@export var use_alert_state: bool = true
@export var alert_duration_seconds: float = 0.28
@export var requires_line_of_sight: bool = false
@export var use_ranged_attack: bool = false
@export var projectile_speed: float = 160.0
@export var projectile_lifetime_seconds: float = 2.5
@export var shielded_front_only: bool = false
@export var shield_block_angle_degrees: float = 120.0
