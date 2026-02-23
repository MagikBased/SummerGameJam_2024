extends StaticBody2D
class_name BossGate

@export var required_completed_levels: PackedStringArray = []
@export var required_key: StringName = &""
@export var hide_when_open: bool = true

@onready var _collision_shape: CollisionShape2D = _find_collision_shape()

func _ready() -> void:
	GameProgression.level_completed.connect(_on_progression_changed)
	GameProgression.key_collected.connect(_on_key_collected)
	_apply_state()

func _on_progression_changed(_level_id: StringName) -> void:
	_apply_state()

func _on_key_collected(_key_id: StringName) -> void:
	_apply_state()

func is_unlocked() -> bool:
	for level_id in required_completed_levels:
		if level_id == "":
			continue
		if not GameProgression.has_completed_level(StringName(level_id)):
			return false
	if required_key != &"" and not GameProgression.has_key(required_key):
		return false
	return true

func _apply_state() -> void:
	var unlocked := is_unlocked()
	if _collision_shape != null:
		_collision_shape.disabled = unlocked
	if hide_when_open and self is CanvasItem:
		(self as CanvasItem).visible = not unlocked

func _find_collision_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child
	return null
