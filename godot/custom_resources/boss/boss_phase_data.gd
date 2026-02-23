extends Resource
class_name BossPhaseData

@export var phase_name: StringName = &"phase"
@export var health_threshold: int = 0
@export var move_speed_multiplier: float = 1.0
@export var attack_cooldown_multiplier: float = 1.0
@export var attack_mode: StringName = &"single_shot"
@export var projectile_count: int = 1
@export var projectile_spread_degrees: float = 0.0
@export var dash_speed_multiplier: float = 1.0
@export var contact_damage_bonus: int = 0
