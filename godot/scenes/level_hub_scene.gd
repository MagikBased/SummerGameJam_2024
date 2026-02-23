extends Node2D

@export var level_manifest: LevelManifest
@export var require_previous_level_completion: bool = true
@export var show_locked_levels: bool = true
@export var settings_scene: PackedScene
@export_file("*.tscn") var main_menu_scene_path: String = "res://scenes/main_menu_scene.tscn"

@onready var levels_container: VBoxContainer = %LevelsContainer
@onready var settings_button: Button = %SettingsButton
@onready var back_button: Button = %BackButton
@onready var status_label: Label = %StatusLabel
@onready var preview_name_label: Label = %PreviewNameLabel
@onready var preview_difficulty_label: Label = %PreviewDifficultyLabel
@onready var preview_best_time_label: Label = %PreviewBestTimeLabel
@onready var preview_medal_label: Label = %PreviewMedalLabel
@onready var preview_lock_label: Label = %PreviewLockLabel
@onready var preview_description_label: Label = %PreviewDescriptionLabel
@onready var save_slot_selector: OptionButton = %SaveSlotSelector
@onready var slot_name_edit: LineEdit = %SlotNameEdit
@onready var slot_meta_label: Label = %SlotMetaLabel
@onready var unlock_graph_label: RichTextLabel = %UnlockGraphLabel

func _ready() -> void:
	settings_button.disabled = settings_scene == null
	back_button.disabled = main_menu_scene_path == ""
	settings_button.pressed.connect(_on_settings_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	save_slot_selector.item_selected.connect(_on_slot_selected)
	slot_name_edit.text_submitted.connect(_on_slot_name_submitted)
	_populate_save_slots()
	SaveGame.load_globals_only()
	_update_slot_name_field()
	_update_slot_metadata()
	_build_level_buttons()
	_refresh_unlock_graph()
	_validate_manifest()

func _populate_save_slots() -> void:
	save_slot_selector.clear()
	for slot in SaveGame.get_available_slots():
		var has_data: bool = SaveGame.has_save(slot)
		var label: String = "Slot %d%s" % [slot, " (used)" if has_data else ""]
		save_slot_selector.add_item(label, slot)
	var active: int = SaveGame.get_active_slot()
	for i in range(save_slot_selector.item_count):
		if save_slot_selector.get_item_id(i) == active:
			save_slot_selector.select(i)
			break
	_update_slot_name_field()

func _on_slot_selected(index: int) -> void:
	var slot: int = save_slot_selector.get_item_id(index)
	SaveGame.set_active_slot(slot)
	SaveGame.load_globals_only()
	_update_slot_name_field()
	_update_slot_metadata()
	_build_level_buttons()
	_refresh_unlock_graph()

func _on_slot_name_submitted(new_text: String) -> void:
	SaveGame.set_slot_name(SaveGame.get_active_slot(), new_text)
	_populate_save_slots()
	_update_slot_name_field()
	_update_slot_metadata()

func _build_level_buttons() -> void:
	for child in levels_container.get_children():
		child.queue_free()
	var first_focus_target: Button
	var fallback_button: Button
	for i in range(_level_count()):
		var entry: LevelManifestEntry = _get_level(i)
		if entry == null or entry.scene == null:
			continue
		var locked_reason: String = _get_locked_reason(i)
		var is_locked: bool = locked_reason != ""
		if is_locked and not show_locked_levels:
			continue
		var button: Button = Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var best: float = RunStats.get_best_time_for_level(String(entry.level_id))
		var medal_suffix: String = ""
		if best >= 0.0:
			medal_suffix = " [%s]" % _medal_name_for_best(entry, best)
		button.text = "%s%s" % [entry.display_name, medal_suffix]
		button.set_meta("level_index", i)
		button.disabled = is_locked
		if is_locked:
			button.text = "%s [Locked]" % button.text
		button.pressed.connect(_on_level_selected.bind(i))
		button.focus_entered.connect(_on_level_focused.bind(i))
		button.mouse_entered.connect(_on_level_focused.bind(i))
		levels_container.add_child(button)
		if fallback_button == null:
			fallback_button = button
		if not is_locked and first_focus_target == null:
			first_focus_target = button
	if levels_container.get_child_count() == 0:
		status_label.text = "No levels configured in manifest."
		_update_preview(-1)
		return
	if first_focus_target != null:
		first_focus_target.grab_focus()
		_on_level_focused(_index_from_button(first_focus_target))
	elif fallback_button != null:
		fallback_button.grab_focus()
		_on_level_focused(_index_from_button(fallback_button))

func _index_from_button(button: Button) -> int:
	if button.has_meta("level_index"):
		return int(button.get_meta("level_index"))
	return -1

func _on_level_focused(index: int) -> void:
	_update_preview(index)

func _on_level_selected(index: int) -> void:
	var entry: LevelManifestEntry = _get_level(index)
	if entry == null or entry.scene == null:
		return
	var locked_reason: String = _get_locked_reason(index)
	if locked_reason != "":
		status_label.text = locked_reason
		return
	_run_level_transition("Loading %s..." % entry.display_name, entry.scene)

func _on_settings_button_pressed() -> void:
	if settings_scene == null:
		return
	_run_level_transition("Opening settings...", settings_scene)

func _on_back_button_pressed() -> void:
	if main_menu_scene_path == "":
		return
	var target_scene: PackedScene = load(main_menu_scene_path)
	if target_scene == null:
		return
	_run_level_transition("Returning to main menu...", target_scene)

func _run_level_transition(message: String, target_scene: PackedScene) -> void:
	status_label.text = message
	TransitionManager.change_scene_to_packed(target_scene)

func _get_locked_reason(index: int) -> String:
	var entry: LevelManifestEntry = _get_level(index)
	if entry == null:
		return "Invalid level."
	if require_previous_level_completion and index > 0:
		var previous_entry: LevelManifestEntry = _get_level(index - 1)
		if previous_entry != null and previous_entry.level_id != &"":
			if not GameProgression.has_completed_level(previous_entry.level_id):
				return "Beat %s first." % previous_entry.display_name
	for required_id in entry.prerequisite_level_ids:
		if required_id == "":
			continue
		if not GameProgression.has_completed_level(StringName(required_id)):
			return "Requires completion: %s" % required_id
	for key_id in entry.required_keys:
		if key_id == "":
			continue
		if not GameProgression.has_key(StringName(key_id)):
			return "Requires key: %s" % key_id
	for ability_id in entry.required_abilities:
		if ability_id == "":
			continue
		if not GameProgression.has_ability(StringName(ability_id)):
			return "Requires ability: %s" % ability_id
	return ""

func _update_preview(index: int) -> void:
	var entry: LevelManifestEntry = _get_level(index)
	if entry == null:
		preview_name_label.text = "No Level"
		preview_difficulty_label.text = "Difficulty: -"
		preview_best_time_label.text = "Best Time: --:--.---"
		preview_medal_label.text = "Medal: None"
		preview_lock_label.text = ""
		preview_description_label.text = "Select a level to see details."
		return
	preview_name_label.text = entry.display_name
	preview_difficulty_label.text = "Difficulty: %s" % entry.difficulty
	var best: float = RunStats.get_best_time_for_level(String(entry.level_id))
	if best >= 0.0:
		preview_best_time_label.text = "Best Time: %s" % _format_time(best)
		preview_medal_label.text = "Medal: %s" % _medal_name_for_best(entry, best)
	else:
		preview_best_time_label.text = "Best Time: --:--.---"
		preview_medal_label.text = "Medal: None"
	var lock_reason: String = _get_locked_reason(index)
	preview_lock_label.text = lock_reason if lock_reason != "" else "Unlocked"
	preview_description_label.text = entry.description
	status_label.text = "Selected: %s" % entry.display_name

func _medal_name_for_best(entry: LevelManifestEntry, best_time: float) -> String:
	if best_time <= entry.gold_medal_seconds:
		return "Gold"
	if best_time <= entry.silver_medal_seconds:
		return "Silver"
	if best_time <= entry.bronze_medal_seconds:
		return "Bronze"
	return "None"

func _format_time(seconds: float) -> String:
	var total_ms: int = int(seconds * 1000.0)
	var minutes: int = total_ms / 60000
	var secs: int = (total_ms % 60000) / 1000
	var millis: int = total_ms % 1000
	return "%02d:%02d.%03d" % [minutes, secs, millis]

func _level_count() -> int:
	return level_manifest.get_level_count() if level_manifest != null else 0

func _get_level(index: int) -> LevelManifestEntry:
	return level_manifest.get_level(index) if level_manifest != null else null

func _update_slot_metadata() -> void:
	if slot_meta_label == null:
		return
	var metadata: Dictionary = SaveGame.get_slot_metadata()
	if not bool(metadata.get("has_save", false)):
		slot_meta_label.text = "No save data in this slot."
		return
	var best_time: float = float(metadata.get("best_time_seconds", -1.0))
	var best_time_text: String = _format_time(best_time) if best_time >= 0.0 else "--:--.---"
	var deaths: int = int(metadata.get("deaths", 0))
	var last_played_unix: int = int(metadata.get("last_played_unix", 0))
	var last_played_text: String = _format_last_played(last_played_unix)
	slot_meta_label.text = "Levels: %d  Keys: %d  Abilities: %d  Deaths: %d  Best: %s  Last: %s" % [
		int(metadata.get("completed_levels", 0)),
		int(metadata.get("keys", 0)),
		int(metadata.get("abilities", 0)),
		deaths,
		best_time_text,
		last_played_text
	]

func _update_slot_name_field() -> void:
	if slot_name_edit == null:
		return
	slot_name_edit.text = SaveGame.get_slot_name(SaveGame.get_active_slot())

func _refresh_unlock_graph() -> void:
	if unlock_graph_label == null:
		return
	if level_manifest == null or level_manifest.levels.is_empty():
		unlock_graph_label.text = "No unlock graph data."
		return
	var lines: PackedStringArray = []
	lines.append("Unlock Graph")
	for entry in level_manifest.levels:
		if entry == null:
			continue
		var completed: bool = GameProgression.has_completed_level(entry.level_id)
		var prefix: String = "[x]" if completed else "[ ]"
		var deps: PackedStringArray = []
		for dep in entry.prerequisite_level_ids:
			if dep != "":
				deps.append(dep)
		var dep_text: String = "none" if deps.is_empty() else ", ".join(deps)
		lines.append("%s %s <- %s" % [prefix, entry.level_id, dep_text])
	unlock_graph_label.text = "\n".join(lines)

func _validate_manifest() -> void:
	var issues: PackedStringArray = LevelManifestValidator.validate(level_manifest)
	if issues.is_empty():
		return
	push_warning("Manifest validation issues:\n%s" % "\n".join(issues))
	status_label.text = "Manifest issues: %d (see output)." % issues.size()

func _format_last_played(unix_time: int) -> String:
	if unix_time <= 0:
		return "never"
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	return "%04d-%02d-%02d %02d:%02d" % [
		int(dt.get("year", 0)),
		int(dt.get("month", 0)),
		int(dt.get("day", 0)),
		int(dt.get("hour", 0)),
		int(dt.get("minute", 0))
	]
