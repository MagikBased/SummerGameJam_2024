extends Area2D
class_name CameraZone

@export var deadzone_override: Vector2 = Vector2(12.0, 8.0)
@export var look_ahead_x_override: float = 10.0
@export var vertical_look_ahead_y_override: float = 3.0
@export var smoothing_speed_override: float = 7.0
@export var zoom_override: Vector2 = Vector2(1.2, 1.2)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_body_entered(body: Node) -> void:
	_apply_if_player(body)

func _on_body_exited(body: Node) -> void:
	_clear_if_player(body)

func _on_area_entered(area: Area2D) -> void:
	var parent: Node = area.get_parent()
	_apply_if_player(parent)

func _on_area_exited(area: Area2D) -> void:
	var parent: Node = area.get_parent()
	_clear_if_player(parent)

func _apply_if_player(target: Node) -> void:
	if not (target is Player):
		return
	var camera: PlayerCameraFollow = _resolve_camera(target as Player)
	if camera != null:
		camera.apply_zone_override(
			deadzone_override,
			look_ahead_x_override,
			vertical_look_ahead_y_override,
			smoothing_speed_override,
			zoom_override
		)

func _clear_if_player(target: Node) -> void:
	if not (target is Player):
		return
	var camera: PlayerCameraFollow = _resolve_camera(target as Player)
	if camera != null:
		camera.clear_zone_override()

func _resolve_camera(player: Player) -> PlayerCameraFollow:
	var viewport: Viewport = player.get_viewport()
	if viewport == null:
		return null
	var camera: Camera2D = viewport.get_camera_2d()
	if camera is PlayerCameraFollow:
		return camera as PlayerCameraFollow
	return null
