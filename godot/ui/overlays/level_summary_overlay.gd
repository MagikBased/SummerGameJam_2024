extends CenterContainer
class_name LevelSummaryOverlay

signal retry_pressed
signal hub_pressed
signal next_pressed

@onready var title_label: Label = %TitleLabel
@onready var time_label: Label = %TimeLabel
@onready var best_label: Label = %BestLabel
@onready var medal_label: Label = %MedalLabel
@onready var retry_button: Button = %RetryButton
@onready var hub_button: Button = %HubButton
@onready var next_button: Button = %NextButton

func _ready() -> void:
	retry_button.pressed.connect(func() -> void: emit_signal("retry_pressed"))
	hub_button.pressed.connect(func() -> void: emit_signal("hub_pressed"))
	next_button.pressed.connect(func() -> void: emit_signal("next_pressed"))

func show_summary(
	level_name: String,
	final_time_seconds: float,
	best_time_seconds: float,
	medal_name: String,
	is_new_best: bool,
	can_go_next: bool
) -> void:
	title_label.text = "%s Complete" % level_name
	time_label.text = "Time: %s" % _format_time(final_time_seconds)
	if best_time_seconds >= 0.0:
		var suffix := " (New Best!)" if is_new_best else ""
		best_label.text = "Best: %s%s" % [_format_time(best_time_seconds), suffix]
	else:
		best_label.text = "Best: --:--.---"
	medal_label.text = "Medal: %s" % medal_name
	next_button.visible = can_go_next
	visible = true
	retry_button.grab_focus()

func _format_time(seconds: float) -> String:
	var total_ms := int(seconds * 1000.0)
	var minutes := total_ms / 60000
	var secs := (total_ms % 60000) / 1000
	var millis := total_ms % 1000
	return "%02d:%02d.%03d" % [minutes, secs, millis]
