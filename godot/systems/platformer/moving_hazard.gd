extends AnimatableBody2D
class_name MovingHazard

@export var point_a: Vector2
@export var point_b: Vector2 = Vector2(48, 0)
@export var speed: float = 48.0
@export var wait_time_at_ends: float = 0.15

var _target: Vector2
var _wait_left: float = 0.0

func _ready() -> void:
	if point_a == Vector2.ZERO:
		point_a = global_position
	if point_b == Vector2.ZERO:
		point_b = global_position + Vector2(48, 0)
	_target = point_b

func _physics_process(delta: float) -> void:
	if _wait_left > 0.0:
		_wait_left = max(0.0, _wait_left - delta)
		return
	global_position = global_position.move_toward(_target, speed * delta)
	if global_position.distance_to(_target) <= 0.5:
		_target = point_a if _target == point_b else point_b
		_wait_left = wait_time_at_ends
