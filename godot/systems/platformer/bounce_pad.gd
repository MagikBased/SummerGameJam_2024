extends Area2D
class_name BouncePad

@export var bounce_velocity: float = -300.0
@export var preserve_horizontal_speed: bool = true
@export var min_horizontal_speed: float = 90.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node) -> void:
	_try_bounce(body)

func _on_area_entered(area: Area2D) -> void:
	var owner := area.get_parent()
	_try_bounce(owner)

func _try_bounce(target: Node) -> void:
	if not (target is Player):
		return
	var player := target as Player
	player.velocity.y = min(player.velocity.y, bounce_velocity)
	player.is_ground_pounding = false
	if preserve_horizontal_speed and abs(player.velocity.x) < min_horizontal_speed:
		var dir := -1.0 if player.animated_sprite_2d.flip_h else 1.0
		player.velocity.x = dir * min_horizontal_speed
	player.play_stomp_feedback()
