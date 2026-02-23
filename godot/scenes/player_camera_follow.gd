extends Camera2D
class_name PlayerCameraFollow

@export var target_path: NodePath
@export var deadzone: Vector2 = Vector2(18.0, 12.0)
@export var look_ahead_x: float = 18.0
@export var vertical_look_ahead_y: float = 6.0
@export var smoothing_speed: float = 10.0
@export var velocity_threshold: float = 20.0
@export var shake_damping: float = 18.0

var _target: Player
var _look_direction: float = 1.0
var _shake_strength: float = 0.0
var _shake_time_left: float = 0.0
var _base_deadzone: Vector2
var _base_look_ahead_x: float = 0.0
var _base_vertical_look_ahead_y: float = 0.0
var _base_smoothing_speed: float = 0.0
var _base_zoom: Vector2
var _has_zone_override: bool = false

func _ready() -> void:
	_base_deadzone = deadzone
	_base_look_ahead_x = look_ahead_x
	_base_vertical_look_ahead_y = vertical_look_ahead_y
	_base_smoothing_speed = smoothing_speed
	_base_zoom = zoom
	_resolve_target()

func _physics_process(delta: float) -> void:
	if _target == null:
		_resolve_target()
		return

	if abs(_target.velocity.x) > velocity_threshold:
		_look_direction = sign(_target.velocity.x)

	var desired := _target.global_position
	desired.x += _look_direction * look_ahead_x
	if _target.velocity.y < -velocity_threshold:
		desired.y -= vertical_look_ahead_y
	elif _target.velocity.y > velocity_threshold:
		desired.y += vertical_look_ahead_y * 0.5

	var raw_target := global_position
	var delta_to_target := desired - raw_target
	if abs(delta_to_target.x) > deadzone.x:
		raw_target.x += delta_to_target.x - sign(delta_to_target.x) * deadzone.x
	if abs(delta_to_target.y) > deadzone.y:
		raw_target.y += delta_to_target.y - sign(delta_to_target.y) * deadzone.y

	var t: float = clampf(smoothing_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(raw_target, t)
	_update_shake(delta)

func _resolve_target() -> void:
	if target_path == NodePath():
		return
	var node: Node = get_node_or_null(target_path)
	if node is Player:
		_target = node

func start_shake(strength: float, duration_seconds: float) -> void:
	_shake_strength = max(_shake_strength, strength)
	_shake_time_left = max(_shake_time_left, duration_seconds)

func apply_zone_override(
	new_deadzone: Vector2,
	new_look_ahead_x: float,
	new_vertical_look_ahead_y: float,
	new_smoothing_speed: float,
	new_zoom: Vector2
) -> void:
	_has_zone_override = true
	deadzone = new_deadzone
	look_ahead_x = new_look_ahead_x
	vertical_look_ahead_y = new_vertical_look_ahead_y
	smoothing_speed = new_smoothing_speed
	zoom = new_zoom

func clear_zone_override() -> void:
	if not _has_zone_override:
		return
	_has_zone_override = false
	deadzone = _base_deadzone
	look_ahead_x = _base_look_ahead_x
	vertical_look_ahead_y = _base_vertical_look_ahead_y
	smoothing_speed = _base_smoothing_speed
	zoom = _base_zoom

func _update_shake(delta: float) -> void:
	if _shake_time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_shake_time_left = max(0.0, _shake_time_left - delta)
	_shake_strength = move_toward(_shake_strength, 0.0, shake_damping * delta)
	offset = Vector2(
		randf_range(-_shake_strength, _shake_strength),
		randf_range(-_shake_strength, _shake_strength)
	)
