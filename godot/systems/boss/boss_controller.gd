extends CharacterBody2D
class_name BossController

signal phase_changed(phase_name: StringName)
signal boss_defeated

@export var phases: Array[BossPhaseData] = []
@export var health_component_path: NodePath

@onready var health_component: HealthComponent = get_node_or_null(health_component_path)

var _current_phase_index: int = -1

func _ready() -> void:
	if health_component != null:
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)
	_update_phase(true)

func _on_damaged(_amount: int, _source: Node) -> void:
	_update_phase()

func _on_died(_source: Node) -> void:
	emit_signal("boss_defeated")
	queue_free()

func _update_phase(force: bool = false) -> void:
	if health_component == null or phases.is_empty():
		return
	var target_index: int = 0
	for i in range(phases.size()):
		if health_component.current_health <= phases[i].health_threshold:
			target_index = i
	if not force and target_index == _current_phase_index:
		return
	_current_phase_index = target_index
	emit_signal("phase_changed", phases[_current_phase_index].phase_name)

func get_current_phase() -> BossPhaseData:
	if _current_phase_index < 0 or _current_phase_index >= phases.size():
		return null
	return phases[_current_phase_index]
