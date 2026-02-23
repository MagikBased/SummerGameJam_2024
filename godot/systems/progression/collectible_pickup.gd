extends Area2D
class_name CollectiblePickup

@export var collectible_type: StringName = &"key"
@export var collectible_id: StringName = &"default"

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area2D) -> void:
	var owner := area.get_parent()
	_try_collect(owner)

func _on_body_entered(body: Node) -> void:
	_try_collect(body)

func _try_collect(target: Node) -> void:
	if not (target is Player):
		return
	if collectible_type == &"key":
		GameProgression.collect_key(collectible_id)
	elif collectible_type == &"ability":
		GameProgression.unlock_ability(collectible_id)
	queue_free()
