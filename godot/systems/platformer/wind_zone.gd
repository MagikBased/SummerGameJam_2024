extends Area2D
class_name WindZone

@export var wind_velocity: Vector2 = Vector2(90.0, -35.0)
@export var accelerate_lerp: float = 6.0
@export var only_when_airborne: bool = true

var _players_inside: Array[Player] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _physics_process(delta: float) -> void:
	if _players_inside.is_empty():
		return
	for player in _players_inside:
		if player == null or not is_instance_valid(player):
			continue
		if only_when_airborne and player.is_on_floor():
			continue
		player.velocity = player.velocity.lerp(wind_velocity, clamp(accelerate_lerp * delta, 0.0, 1.0))

func _on_body_entered(body: Node) -> void:
	_add_player(body)

func _on_body_exited(body: Node) -> void:
	_remove_player(body)

func _on_area_entered(area: Area2D) -> void:
	_add_player(area.get_parent())

func _on_area_exited(area: Area2D) -> void:
	_remove_player(area.get_parent())

func _add_player(target: Node) -> void:
	if target is Player and not _players_inside.has(target):
		_players_inside.append(target)

func _remove_player(target: Node) -> void:
	if target is Player:
		_players_inside.erase(target)
