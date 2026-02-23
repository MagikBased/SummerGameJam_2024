extends VBoxContainer

@onready var master_volume_toggle := %MasterEnabledToggle
@onready var master_volume_slider := %MasterVolumeSlider
@onready var music_volume_toggle := %MusicEnabledToggle
@onready var music_volume_slider := %MusicVolumeSlider
@onready var sound_volume_toggle := %SoundEnabledToggle
@onready var sound_volume_slider := %SoundVolumeSlider
@onready var language_dropdown := %LanguageDropdown
@onready var assist_mode_toggle := %AssistModeToggle
@onready var game_speed_slider := %GameSpeedSlider

## maps the index of a locale to the locale itself
var locales:PackedStringArray = []

func _ready() -> void:
	self.locales = TranslationServer.get_loaded_locales()
	var current_locale = TranslationServer.get_locale()
	var idx = 0
	var select_index = -1
	for locale in locales:
		var language = TranslationServer.get_locale_name(locale)
		language_dropdown.add_item(language, idx)
		if current_locale == locale:
			select_index = idx
		idx += 1
	language_dropdown.select(select_index)		
	master_volume_toggle.button_pressed = bool(UserSettings.get_value("mastervolume_enabled"))
	music_volume_toggle.button_pressed = bool(UserSettings.get_value("musicvolume_enabled"))
	sound_volume_toggle.button_pressed = bool(UserSettings.get_value("soundvolume_enabled"))
	assist_mode_toggle.button_pressed = bool(UserSettings.get_value("assist_mode_enabled"))
	master_volume_slider.editable = master_volume_toggle.button_pressed
	music_volume_slider.editable = master_volume_toggle.button_pressed and music_volume_toggle.button_pressed
	sound_volume_slider.editable = master_volume_toggle.button_pressed and sound_volume_toggle.button_pressed
	game_speed_slider.editable = assist_mode_toggle.button_pressed
			

func _on_master_volume_toggle_toggled(button_pressed: bool) -> void:
	master_volume_slider.editable = button_pressed
	music_volume_slider.editable = music_volume_toggle.button_pressed and button_pressed
	sound_volume_slider.editable = sound_volume_toggle.button_pressed and button_pressed
	UserSettings.set_value("mastervolume_enabled", button_pressed)


func _on_music_enabled_toggle_toggled(button_pressed: bool) -> void:
	music_volume_slider.editable = master_volume_toggle.button_pressed and button_pressed
	UserSettings.set_value("musicvolume_enabled", button_pressed)


func _on_sound_enabled_toggle_toggled(button_pressed: bool) -> void:
	sound_volume_slider.editable = master_volume_toggle.button_pressed and button_pressed
	UserSettings.set_value("soundvolume_enabled", button_pressed)


func _on_language_dropdown_item_selected(index: int) -> void:
	UserSettings.set_value("game_locale", locales[index])

func _on_assist_mode_toggle_toggled(button_pressed: bool) -> void:
	game_speed_slider.editable = button_pressed
	UserSettings.set_value("assist_mode_enabled", button_pressed)
