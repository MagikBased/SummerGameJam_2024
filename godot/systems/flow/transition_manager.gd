extends Node

var _overlay: ColorRect
var _busy: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func change_scene_to_packed(scene: PackedScene, duration: float = 0.2) -> void:
	if scene == null or _busy:
		return
	_busy = true
	await _fade_out(duration)
	get_tree().paused = false
	get_tree().change_scene_to_packed(scene)
	await _fade_in(duration)
	_busy = false

func reload_current_scene(duration: float = 0.2) -> void:
	if _busy:
		return
	_busy = true
	await _fade_out(duration)
	get_tree().paused = false
	get_tree().reload_current_scene()
	await _fade_in(duration)
	_busy = false

func _fade_out(duration: float) -> void:
	var overlay := _ensure_overlay()
	overlay.visible = true
	overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, max(duration, 0.01))
	await tween.finished

func _fade_in(duration: float) -> void:
	var overlay := _ensure_overlay()
	overlay.visible = true
	overlay.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, max(duration, 0.01))
	await tween.finished
	overlay.visible = false

func _ensure_overlay() -> ColorRect:
	if _overlay != null and is_instance_valid(_overlay):
		return _overlay
	_overlay = ColorRect.new()
	_overlay.name = "TransitionOverlay"
	_overlay.color = Color(0, 0, 0, 1)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.offset_left = 0
	_overlay.offset_top = 0
	_overlay.offset_right = 0
	_overlay.offset_bottom = 0
	_overlay.visible = false
	var layer := CanvasLayer.new()
	layer.name = "TransitionLayer"
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(_overlay)
	get_tree().root.add_child(layer)
	return _overlay
