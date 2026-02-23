extends StaticBody2D
class_name BreakableBlock

signal broken(impact_kind: StringName)

@export var break_on_dash: bool = true
@export var break_on_ground_pound: bool = true
@export var debris_scene: PackedScene

func try_break(impact_kind: StringName) -> bool:
	if impact_kind == &"dash" and not break_on_dash:
		return false
	if impact_kind == &"ground_pound" and not break_on_ground_pound:
		return false
	emit_signal("broken", impact_kind)
	if debris_scene != null:
		var debris: Node = debris_scene.instantiate()
		if debris is Node2D:
			debris.global_position = global_position
		get_tree().current_scene.add_child(debris)
	queue_free()
	return true
