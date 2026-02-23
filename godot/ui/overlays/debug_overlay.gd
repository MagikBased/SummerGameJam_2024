extends CanvasLayer
class_name DebugOverlay

@export var target_level_id: StringName = &""

@onready var info_label: Label = %InfoLabel

var _visible_debug: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F3:
			_visible_debug = not _visible_debug
			visible = _visible_debug

func _process(_delta: float) -> void:
	if not _visible_debug or info_label == null:
		return
	var fps: int = Engine.get_frames_per_second()
	var slot: int = SaveGame.get_active_slot()
	var level_text: String = String(target_level_id)
	if level_text == "":
		level_text = get_tree().current_scene.scene_file_path
	var player_pos_text: String = _get_first_player_pos_text()
	info_label.text = "FPS: %d\nSlot: %d\nLevel: %s\nPlayer: %s\nRun: %.2fs" % [
		fps,
		slot,
		level_text,
		player_pos_text,
		RunStats.current_time_seconds
	]

func _get_first_player_pos_text() -> String:
	for node in get_tree().get_nodes_in_group("player"):
		if node is Player:
			var player := node as Player
			return "(%.1f, %.1f)" % [player.global_position.x, player.global_position.y]
	return "N/A"
