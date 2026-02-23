extends StaticBody2D
class_name TimedGate

signal gate_state_changed(is_open: bool)

@export var auto_close_seconds: float = 3.0
@export var start_open: bool = false
@export var hide_when_open: bool = true

@onready var _collision_shape: CollisionShape2D = _find_collision_shape()

var _close_time_left: float = 0.0
var _is_open: bool = false

func _ready() -> void:
	_set_open(start_open)

func _physics_process(delta: float) -> void:
	if not _is_open:
		return
	if _close_time_left < 0.0:
		return
	if auto_close_seconds <= 0.0:
		return
	_close_time_left = max(0.0, _close_time_left - delta)
	if _close_time_left == 0.0:
		close_gate()

func open_gate(duration_seconds: float = -1.0) -> void:
	_set_open(true)
	if duration_seconds == 0.0:
		_close_time_left = -1.0
		return
	var close_after := auto_close_seconds if duration_seconds < 0.0 else duration_seconds
	_close_time_left = max(0.0, close_after)

func close_gate() -> void:
	_set_open(false)
	_close_time_left = 0.0

func toggle_gate() -> void:
	if _is_open:
		close_gate()
	else:
		open_gate()

func is_gate_open() -> bool:
	return _is_open

func _set_open(open: bool) -> void:
	_is_open = open
	if _collision_shape != null:
		_collision_shape.disabled = open
	if hide_when_open and self is CanvasItem:
		(self as CanvasItem).visible = not open
	emit_signal("gate_state_changed", _is_open)

func _find_collision_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child
	return null
