extends Node2D
class_name GateLock

@export var required_key_id: StringName = &"default"
@export var locked_node_path: NodePath
@export var unlock_hide_instead_of_disable: bool = true

@onready var _locked_node: Node = get_node_or_null(locked_node_path)

func _ready() -> void:
	GameProgression.key_collected.connect(_on_key_collected)
	_apply_lock_state()

func _on_key_collected(_key_id: StringName) -> void:
	_apply_lock_state()

func _apply_lock_state() -> void:
	var unlocked := GameProgression.has_key(required_key_id)
	if _locked_node == null:
		return
	if unlock_hide_instead_of_disable and _locked_node is CanvasItem:
		(_locked_node as CanvasItem).visible = not unlocked
	if "disabled" in _locked_node:
		_locked_node.set("disabled", unlocked)
