extends Node2D
class_name CharacterLane

@export var lane_id: StringName = &""
@onready var lane_world: LaneWorld = $World/LaneWorld

func _ready() -> void:
	if lane_id != &"":
		configure_lane(lane_id)

func get_player() -> Player:
	return lane_world.get_player()

func get_lane_world() -> LaneWorld:
	return lane_world

func configure_lane(id: StringName) -> void:
	lane_id = id
	lane_world.set_lane_id(id)
