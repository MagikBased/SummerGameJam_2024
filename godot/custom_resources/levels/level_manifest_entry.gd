extends Resource
class_name LevelManifestEntry

@export var level_id: StringName = &""
@export var display_name: String = "Level"
@export_multiline var description: String = ""
@export var difficulty: String = "Normal"
@export var scene: PackedScene
@export var required_keys: PackedStringArray = []
@export var required_abilities: PackedStringArray = []
@export var prerequisite_level_ids: PackedStringArray = []
@export var bronze_medal_seconds: float = 120.0
@export var silver_medal_seconds: float = 90.0
@export var gold_medal_seconds: float = 60.0
