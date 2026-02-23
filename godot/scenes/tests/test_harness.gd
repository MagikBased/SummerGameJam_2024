extends Node

@export var test_name: String = "Unnamed"
@export var checklist: PackedStringArray = []

func _ready() -> void:
	print("[Harness] Running: %s" % test_name)
	for item in checklist:
		print("[Harness] - %s" % item)
