extends Area2D
class_name DamageArea

@export var damage: int = 1
@export var one_shot: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area2D) -> void:
	var owner := area.get_parent()
	_apply(owner)

func _on_body_entered(body: Node) -> void:
	_apply(body)

func _apply(target: Node) -> void:
	if target == null:
		return
	if target.has_method("receive_damage"):
		target.call("receive_damage", damage, self)
	if one_shot:
		queue_free()
