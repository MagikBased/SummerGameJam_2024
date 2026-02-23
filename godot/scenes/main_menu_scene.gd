extends Node2D

@export var game_scene:PackedScene
@export var settings_scene:PackedScene

@onready var overlay: FadeOverlay = %FadeOverlay
@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton
@onready var save_slot_selector: OptionButton = %SaveSlotSelector
@onready var slot_meta_label: Label = %SlotMetaLabel
@onready var slot_name_edit: LineEdit = %SlotNameEdit

var next_scene: PackedScene
var new_game: bool = true

func _ready() -> void:
	next_scene = game_scene
	overlay.visible = true
	new_game_button.disabled = game_scene == null
	settings_button.disabled = settings_scene == null
	_populate_save_slots()
	continue_button.visible = SaveGame.has_save() and SaveGame.ENABLED
	
	# connect signals
	new_game_button.pressed.connect(_on_play_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	save_slot_selector.item_selected.connect(_on_slot_selected)
	slot_name_edit.text_submitted.connect(_on_slot_name_submitted)
	overlay.on_complete_fade_out.connect(_on_fade_overlay_on_complete_fade_out)
	
	if continue_button.visible:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()

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
	_update_slot_metadata()
	_update_slot_name_field()

func _on_slot_selected(index: int) -> void:
	var slot: int = save_slot_selector.get_item_id(index)
	SaveGame.set_active_slot(slot)
	continue_button.visible = SaveGame.has_save() and SaveGame.ENABLED
	_update_slot_name_field()
	_update_slot_metadata()

func _on_slot_name_submitted(new_text: String) -> void:
	SaveGame.set_slot_name(SaveGame.get_active_slot(), new_text)
	_populate_save_slots()
	_update_slot_name_field()
	_update_slot_metadata()

func _on_settings_button_pressed() -> void:
	new_game = false
	next_scene = settings_scene
	overlay.fade_out()
	
func _on_play_button_pressed() -> void:
	next_scene = game_scene
	overlay.fade_out()
	
func _on_continue_button_pressed() -> void:
	new_game = false
	next_scene = game_scene
	overlay.fade_out()

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_fade_overlay_on_complete_fade_out() -> void:
	if new_game and SaveGame.has_save():
		SaveGame.delete_save()
	SaveGame.load_globals_only()
	get_tree().change_scene_to_packed(next_scene)

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

func _format_time(seconds: float) -> String:
	var total_ms: int = int(seconds * 1000.0)
	var minutes: int = total_ms / 60000
	var secs: int = (total_ms % 60000) / 1000
	var millis: int = total_ms % 1000
	return "%02d:%02d.%03d" % [minutes, secs, millis]

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
