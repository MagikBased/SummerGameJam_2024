extends AnimatableBody2D
class_name FallingPlatform

@export var trigger_area_path: NodePath = NodePath("TriggerArea")
@export var fall_delay_seconds: float = 0.2
@export var fall_speed: float = 150.0
@export var respawn_seconds: float = 2.0

var _initial_position: Vector2
var _is_triggered: bool = false
var _is_falling: bool = false
var _fall_delay_left: float = 0.0
var _respawn_left: float = 0.0

@onready var _trigger_area: Area2D = get_node_or_null(trigger_area_path)
@onready var _collision_shape: CollisionShape2D = _find_collision_shape()

func _ready() -> void:
	_initial_position = global_position
	if _trigger_area != null:
		_trigger_area.body_entered.connect(_on_body_entered)
		_trigger_area.area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if _is_falling:
		global_position.y += fall_speed * delta
		_respawn_left = max(0.0, _respawn_left - delta)
		if _respawn_left == 0.0:
			_respawn()
		return

	if _is_triggered:
		_fall_delay_left = max(0.0, _fall_delay_left - delta)
		if _fall_delay_left == 0.0:
			_start_fall()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		trigger_fall()

func _on_area_entered(area: Area2D) -> void:
	var owner := area.get_parent()
	if owner is Player:
		trigger_fall()

func trigger_fall() -> void:
	if _is_triggered or _is_falling:
		return
	_is_triggered = true
	_fall_delay_left = fall_delay_seconds

func _start_fall() -> void:
	_is_falling = true
	_respawn_left = respawn_seconds
	visible = false
	if _collision_shape != null:
		_collision_shape.disabled = true

func _respawn() -> void:
	_is_triggered = false
	_is_falling = false
	global_position = _initial_position
	visible = true
	if _collision_shape != null:
		_collision_shape.disabled = false

func _find_collision_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child
	return null
