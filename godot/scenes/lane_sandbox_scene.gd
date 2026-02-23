extends Node2D

@export_file("*.tscn") var hub_scene_path: String = "res://scenes/level_hub_scene.tscn"
@export var level_id: StringName = &"lane_sandbox"

@onready var lane: CharacterLane = $Lane
@onready var camera: PlayerCameraFollow = $Camera2D
@onready var back_button: Button = %BackToHubButton

var _is_exiting: bool = false

func _ready() -> void:
	if lane != null:
		lane.configure_lane(&"left")
	if camera != null and lane != null:
		camera.target_path = lane.get_player().get_path()
	RunStats.start_run(String(level_id))
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	if _is_exiting:
		return
	_is_exiting = true
	back_button.disabled = true
	RunStats.finish_run()
	GameProgression.mark_level_completed(level_id)
	SaveGame.save_game(get_tree())
	if hub_scene_path == "":
		return
	var hub_scene: PackedScene = load(hub_scene_path)
	if hub_scene == null:
		return
	TransitionManager.change_scene_to_packed(hub_scene)
