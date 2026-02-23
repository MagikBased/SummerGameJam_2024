extends Node
class_name TimeTrialMedal

@export var gold_seconds: float = 30.0
@export var silver_seconds: float = 45.0
@export var bronze_seconds: float = 60.0

func get_medal_for_time(time_seconds: float) -> StringName:
	if time_seconds <= gold_seconds:
		return &"gold"
	if time_seconds <= silver_seconds:
		return &"silver"
	if time_seconds <= bronze_seconds:
		return &"bronze"
	return &"none"
