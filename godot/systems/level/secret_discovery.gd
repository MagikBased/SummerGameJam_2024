extends Area2D
class_name SecretDiscovery

signal secret_found(secret_id: StringName)

@export var secret_id: StringName = &"secret"
@export var one_shot: bool = true

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area2D) -> void:
	var owner := area.get_parent()
	_try_activate(owner)

func _on_body_entered(body: Node) -> void:
	_try_activate(body)

func _try_activate(target: Node) -> void:
	if not (target is Player):
		return
	emit_signal("secret_found", secret_id)
	if one_shot:
		queue_free()
