extends Resource
class_name PlayerMovementData

@export var speed: float = 120.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0
@export var air_acceleration: float = 500.0
@export var gravity_scale: float = 1.0
@export var jump_velocity: float = -215.0

@export var coyote_time_seconds: float = 0.1
@export var jump_buffer_seconds: float = 0.12
@export var drop_through_seconds: float = 0.2
@export var one_way_collision_layer: int = 5
@export var wall_slide_max_fall_speed: float = 60.0
@export var dash_speed: float = 240.0
@export var dash_duration_seconds: float = 0.14
@export var dash_cooldown_seconds: float = 0.45
@export var dash_invulnerability_seconds: float = 0.1
@export var stomp_bounce_velocity: float = -170.0
@export var stomp_damage: int = 1
@export var damage_invulnerability_seconds: float = 0.35
@export var max_air_jumps: int = 1
@export var double_jump_unlock_ability: StringName = &"double_jump"
@export var ground_pound_speed: float = 320.0
@export var ground_pound_bounce_velocity: float = -120.0
