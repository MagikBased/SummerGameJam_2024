extends Area2D
class_name LevelTrigger

signal triggered(trigger_id: StringName, payload: Dictionary)

@export var trigger_id: StringName = &""
@export var one_shot: bool = true
@export var action: StringName = &"none"
@export var payload: Dictionary = {}

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area2D) -> void:
	var owner := area.get_parent()
	_handle(owner)

func _on_body_entered(body: Node) -> void:
	_handle(body)

func _handle(target: Node) -> void:
	if not (target is Player):
		return
	emit_signal("triggered", trigger_id, payload)
	_run_action()
	if one_shot:
		queue_free()

func _run_action() -> void:
	match action:
		&"start_run":
			RunStats.start_run()
		&"finish_run":
			RunStats.finish_run()
		&"victory":
			GameManager.trigger_victory()
		_:
			pass
