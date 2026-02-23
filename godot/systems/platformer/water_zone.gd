extends Area2D
class_name WaterZone

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_body_entered(body: Node) -> void:
	_set_water(body, true)

func _on_body_exited(body: Node) -> void:
	_set_water(body, false)

func _on_area_entered(area: Area2D) -> void:
	_set_water(area.get_parent(), true)

func _on_area_exited(area: Area2D) -> void:
	_set_water(area.get_parent(), false)

func _set_water(target: Node, active: bool) -> void:
	if target is Player:
		(target as Player).set_water_contact(active)
