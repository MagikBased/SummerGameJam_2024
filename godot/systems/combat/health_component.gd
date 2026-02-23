extends Node
class_name HealthComponent

signal damaged(amount: int, source: Node)
signal died(source: Node)
signal healed(amount: int)

@export var max_health: int = 1
@export var invulnerability_seconds: float = 0.0

var current_health: int = 1
var _invulnerability_left: float = 0.0

func _ready() -> void:
	current_health = max_health

func _physics_process(delta: float) -> void:
	if _invulnerability_left > 0.0:
		_invulnerability_left = max(0.0, _invulnerability_left - delta)

func apply_damage(amount: int, source: Node = null) -> void:
	if amount <= 0 or _invulnerability_left > 0.0:
		return
	current_health = max(0, current_health - amount)
	_invulnerability_left = invulnerability_seconds
	emit_signal("damaged", amount, source)
	if current_health == 0:
		emit_signal("died", source)

func heal(amount: int) -> void:
	if amount <= 0:
		return
	current_health = min(max_health, current_health + amount)
	emit_signal("healed", amount)

func is_alive() -> bool:
	return current_health > 0
