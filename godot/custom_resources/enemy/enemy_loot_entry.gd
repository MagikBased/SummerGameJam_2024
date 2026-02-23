extends Resource
class_name EnemyLootEntry

@export var collectible_type: StringName = &"key"
@export var collectible_id: StringName = &"default"
@export_range(0.0, 1.0, 0.01) var drop_chance: float = 0.25
