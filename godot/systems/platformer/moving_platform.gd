extends AnimatableBody2D
class_name MovingPlatform

@export var point_a: Vector2
@export var point_b: Vector2 = Vector2(64, 0)
@export var speed: float = 40.0
@export var wait_time_at_ends: float = 0.2

var _target: Vector2
var _wait_left: float = 0.0
var _velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	if point_a == Vector2.ZERO:
		point_a = global_position
	if point_b == Vector2.ZERO:
		point_b = global_position + Vector2(64, 0)
	_target = point_b

func _physics_process(delta: float) -> void:
	if _wait_left > 0.0:
		_wait_left = max(0.0, _wait_left - delta)
		_velocity = Vector2.ZERO
		return

	var previous := global_position
	global_position = global_position.move_toward(_target, speed * delta)
	_velocity = (global_position - previous) / max(delta, 0.0001)
	if global_position.distance_to(_target) <= 0.5:
		_target = point_a if _target == point_b else point_b
		_wait_left = wait_time_at_ends

func get_platform_velocity() -> Vector2:
	return _velocity
