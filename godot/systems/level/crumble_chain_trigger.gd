extends Area2D
class_name CrumbleChainTrigger

@export var platform_paths: Array[NodePath] = []
@export var trigger_interval_seconds: float = 0.12
@export var one_shot: bool = true

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node) -> void:
	_try_trigger(body)

func _on_area_entered(area: Area2D) -> void:
	_try_trigger(area.get_parent())

func _try_trigger(target: Node) -> void:
	if _triggered and one_shot:
		return
	if not (target is Player):
		return
	_triggered = true
	_trigger_chain.call_deferred()

func _trigger_chain() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for path in platform_paths:
		var platform := get_node_or_null(path)
		if platform != null and platform.has_method("trigger_fall"):
			platform.call("trigger_fall")
		if trigger_interval_seconds > 0.0:
			await tree.create_timer(trigger_interval_seconds).timeout
