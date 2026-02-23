extends Node
class_name MidbossRoomController

@export var boss_path: NodePath
@export var reward_key_on_defeat: StringName = &"midboss_key"

@onready var _boss: BossController = get_node_or_null(boss_path)

func _ready() -> void:
	if _boss != null:
		_boss.boss_defeated.connect(_on_boss_defeated)

func _on_boss_defeated() -> void:
	if reward_key_on_defeat != &"":
		GameProgression.collect_key(reward_key_on_defeat)
	GameManager.trigger_victory()
