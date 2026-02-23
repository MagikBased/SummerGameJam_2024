extends Area2D
class_name PressureSwitch

signal switched_on
signal switched_off

@export var target_gate_path: NodePath
@export var hold_to_keep_open: bool = false
@export var open_duration_seconds: float = 2.0

@onready var _target_gate: TimedGate = get_node_or_null(target_gate_path)

var _players_on_switch: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_body_entered(body: Node) -> void:
	_enter(body)

func _on_body_exited(body: Node) -> void:
	_exit(body)

func _on_area_entered(area: Area2D) -> void:
	_enter(area.get_parent())

func _on_area_exited(area: Area2D) -> void:
	_exit(area.get_parent())

func _enter(target: Node) -> void:
	if not (target is Player):
		return
	_players_on_switch += 1
	if _players_on_switch == 1:
		emit_signal("switched_on")
		_open_target_gate()

func _exit(target: Node) -> void:
	if not (target is Player):
		return
	_players_on_switch = max(0, _players_on_switch - 1)
	if _players_on_switch == 0:
		emit_signal("switched_off")
		if hold_to_keep_open:
			_close_target_gate()

func _open_target_gate() -> void:
	if _target_gate == null:
		return
	if hold_to_keep_open:
		_target_gate.open_gate(0.0)
	else:
		_target_gate.open_gate(open_duration_seconds)

func _close_target_gate() -> void:
	if _target_gate != null:
		_target_gate.close_gate()
