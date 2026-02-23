extends Area2D
class_name EnemyProjectile

@export var speed: float = 160.0
@export var damage: int = 1
@export var lifetime_seconds: float = 2.0

var direction: Vector2 = Vector2.LEFT
var _lifetime_left: float = 0.0

func _ready() -> void:
	_lifetime_left = lifetime_seconds
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta
	_lifetime_left = max(0.0, _lifetime_left - delta)
	if _lifetime_left == 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_hit(area.get_parent())

func _hit(target: Node) -> void:
	if target is Player:
		(target as Player).receive_damage(damage, self)
		queue_free()
