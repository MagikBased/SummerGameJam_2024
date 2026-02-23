extends Node

@onready var left_camera = $HBoxContainer/SubViewportContainer/SubViewport/Camera2D
@onready var right_camera = $HBoxContainer/SubViewportContainer2/SubViewport2/Camera2D
@onready var left_lane: CharacterLane = $HBoxContainer/SubViewportContainer/SubViewport/LeftLane
@onready var right_lane: CharacterLane = $HBoxContainer/SubViewportContainer2/SubViewport2/RightLane
@onready var coordinator: DualWorldCoordinator = $DualWorldCoordinator
@onready var label = $Victory/Label
@onready var color_rect = $HBoxContainer/SubViewportContainer/ColorRect
@onready var color_rect2 = $HBoxContainer/SubViewportContainer2/ColorRect
@onready var run_hud: Label = $RunHud
@onready var split_hud: Label = $SplitHud
@onready var hub_button: Button = $HubButton
@onready var summary_overlay: LevelSummaryOverlay = %LevelSummaryOverlay

var split_message_left: float = 0.0
@export_file("*.tscn") var hub_scene_path: String = "res://scenes/level_hub_scene.tscn"
@export_file("*.tres") var level_manifest_path: String = "res://custom_resources/levels/default_level_manifest.tres"
@export var level_id: StringName = &""
@export var bronze_medal_seconds: float = 120.0
@export var silver_medal_seconds: float = 90.0
@export var gold_medal_seconds: float = 60.0

var _showing_summary: bool = false
var _next_level_scene: PackedScene
var _level_manifest_cache: LevelManifest


func _ready() -> void:
	GameManager.victory_triggered.connect(_on_victory_triggered)
	RunStats.run_finished.connect(_on_run_finished)
	RunStats.split_recorded.connect(_on_split_recorded)
	coordinator.configure(
		left_lane,
		right_lane,
		color_rect,
		color_rect2,
		left_camera,
		right_camera
	)
	if left_camera is PlayerCameraFollow:
		left_camera.target_path = left_lane.get_player().get_path()
	if right_camera is PlayerCameraFollow:
		right_camera.target_path = right_lane.get_player().get_path()
	var current_path := get_tree().current_scene.scene_file_path
	RunStats.start_run(String(_resolve_level_id(current_path)))
	if hub_button != null:
		hub_button.pressed.connect(_on_hub_button_pressed)
	if summary_overlay != null:
		summary_overlay.retry_pressed.connect(_on_summary_retry_pressed)
		summary_overlay.hub_pressed.connect(_on_summary_hub_pressed)
		summary_overlay.next_pressed.connect(_on_summary_next_pressed)
	set_process(true)
	
func _on_victory_triggered() -> void:
	if _showing_summary:
		return
	_showing_summary = true
	label.visible = false
	var current_level_path := get_tree().current_scene.scene_file_path
	var resolved_level_id := _resolve_level_id(current_level_path)
	var previous_best := RunStats.get_best_time_for_level(String(resolved_level_id))
	var final_time := RunStats.current_time_seconds
	RunStats.finish_run()
	GameProgression.mark_level_completed(resolved_level_id)
	SaveGame.save_game(get_tree())
	var best_time := RunStats.get_best_time_for_level(String(resolved_level_id))
	var is_new_best := previous_best < 0.0 or final_time < previous_best
	_next_level_scene = _resolve_next_level_scene(resolved_level_id)
	if summary_overlay != null:
		summary_overlay.show_summary(
			_level_name_from_path(current_level_path),
			final_time,
			best_time,
			_medal_name_for_time(best_time if best_time >= 0.0 else final_time),
			is_new_best,
			_next_level_scene != null
		)
	get_tree().paused = true

func _process(_delta: float) -> void:
	if run_hud == null:
		return
	if RunStats.is_running:
		run_hud.text = _format_time(RunStats.current_time_seconds)
	else:
		run_hud.text = "Final %s" % _format_time(RunStats.current_time_seconds)
	if split_hud != null and split_message_left > 0.0:
		split_message_left = max(0.0, split_message_left - _delta)
		split_hud.visible = split_message_left > 0.0

func _on_run_finished(time_seconds: float) -> void:
	if run_hud != null:
		run_hud.text = "Final %s" % _format_time(time_seconds)

func _on_split_recorded(split_id: int, split_time_seconds: float) -> void:
	if split_hud == null:
		return
	var best_split_raw: Variant = RunStats.best_splits.get(split_id, -1.0)
	var best_split_seconds: float = -1.0
	if best_split_raw is float or best_split_raw is int:
		best_split_seconds = float(best_split_raw)
	var delta_text: String = ""
	if best_split_seconds > 0.0:
		var diff: float = split_time_seconds - best_split_seconds
		var sign: String = "+" if diff >= 0.0 else "-"
		delta_text = " (%s%s)" % [sign, _format_time(abs(diff))]
	split_hud.text = "Split %d %s%s" % [split_id, _format_time(split_time_seconds), delta_text]
	split_hud.visible = true
	split_message_left = 1.35

func _format_time(seconds: float) -> String:
	var total_ms := int(seconds * 1000.0)
	var minutes := total_ms / 60000
	var secs := (total_ms % 60000) / 1000
	var millis := total_ms % 1000
	return "%02d:%02d.%03d" % [minutes, secs, millis]

func _on_hub_button_pressed() -> void:
	if _showing_summary:
		return
	if hub_scene_path == "":
		return
	var hub_scene: PackedScene = load(hub_scene_path)
	if hub_scene == null:
		return
	SaveGame.save_game(get_tree())
	TransitionManager.change_scene_to_packed(hub_scene)

func _on_summary_retry_pressed() -> void:
	_showing_summary = false
	SaveGame.save_game(get_tree())
	TransitionManager.reload_current_scene()

func _on_summary_hub_pressed() -> void:
	_showing_summary = false
	if hub_scene_path == "":
		return
	var hub_scene: PackedScene = load(hub_scene_path)
	if hub_scene == null:
		return
	SaveGame.save_game(get_tree())
	TransitionManager.change_scene_to_packed(hub_scene)

func _on_summary_next_pressed() -> void:
	if _next_level_scene == null:
		return
	_showing_summary = false
	SaveGame.save_game(get_tree())
	TransitionManager.change_scene_to_packed(_next_level_scene)

func _medal_name_for_time(seconds: float) -> String:
	if seconds <= gold_medal_seconds:
		return "Gold"
	if seconds <= silver_medal_seconds:
		return "Silver"
	if seconds <= bronze_medal_seconds:
		return "Bronze"
	return "None"

func _level_name_from_path(path: String) -> String:
	if path == "":
		return "Level"
	var slash := path.rfind("/")
	var dot := path.rfind(".")
	if slash == -1:
		slash = 0
	else:
		slash += 1
	if dot <= slash:
		dot = path.length()
	return path.substr(slash, dot - slash)

func _resolve_level_id(current_scene_path: String) -> StringName:
	if level_id != &"":
		return level_id
	var manifest := _get_level_manifest()
	if manifest == null:
		return StringName(current_scene_path)
	var entry := manifest.get_level_by_scene_path(current_scene_path)
	if entry == null:
		return StringName(current_scene_path)
	if entry.level_id == &"":
		return StringName(current_scene_path)
	return entry.level_id

func _resolve_next_level_scene(current_level_id: StringName) -> PackedScene:
	var manifest := _get_level_manifest()
	if manifest == null:
		return null
	var next_entry := manifest.get_next_level(current_level_id)
	if next_entry == null or next_entry.scene == null:
		return null
	for required_level in next_entry.prerequisite_level_ids:
		if required_level == "":
			continue
		if not GameProgression.has_completed_level(StringName(required_level)):
			return null
	for key_id in next_entry.required_keys:
		if key_id == "":
			continue
		if not GameProgression.has_key(StringName(key_id)):
			return null
	for ability_id in next_entry.required_abilities:
		if ability_id == "":
			continue
		if not GameProgression.has_ability(StringName(ability_id)):
			return null
	return next_entry.scene

func _get_level_manifest() -> LevelManifest:
	if _level_manifest_cache != null:
		return _level_manifest_cache
	if level_manifest_path == "":
		return null
	var loaded := load(level_manifest_path)
	if loaded is LevelManifest:
		_level_manifest_cache = loaded
	return _level_manifest_cache

# Legacy entry point kept for compatibility.
func victory() -> void:
	_on_victory_triggered()
