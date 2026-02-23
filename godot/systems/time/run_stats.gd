extends Node

signal run_started
signal run_finished(time_seconds: float)
signal split_recorded(split_id: int, split_time_seconds: float)

var current_time_seconds: float = 0.0
var best_time_seconds: float = -1.0
var is_running: bool = false
var current_splits: Dictionary = {}
var best_splits: Dictionary = {}
var current_level_id: String = ""
var best_time_by_level: Dictionary = {}

func _process(delta: float) -> void:
	if is_running:
		current_time_seconds += delta

func start_run(level_id: String = "") -> void:
	current_time_seconds = 0.0
	is_running = true
	current_level_id = level_id
	current_splits.clear()
	emit_signal("run_started")

func finish_run() -> void:
	if not is_running:
		return
	is_running = false
	if best_time_seconds < 0.0 or current_time_seconds < best_time_seconds:
		best_time_seconds = current_time_seconds
		best_splits = current_splits.duplicate(true)
	if current_level_id != "":
		var previous_best: float = float(best_time_by_level.get(current_level_id, -1.0))
		if previous_best < 0.0 or current_time_seconds < previous_best:
			best_time_by_level[current_level_id] = current_time_seconds
	emit_signal("run_finished", current_time_seconds)

func record_split(split_id: int) -> void:
	if split_id < 0:
		return
	if not is_running:
		return
	if current_splits.has(split_id):
		return
	current_splits[split_id] = current_time_seconds
	emit_signal("split_recorded", split_id, current_time_seconds)

func get_split_time(split_id: int) -> float:
	if not current_splits.has(split_id):
		return -1.0
	return float(current_splits[split_id])

func get_best_time_for_level(level_id: String) -> float:
	if level_id == "":
		return -1.0
	return float(best_time_by_level.get(level_id, -1.0))

func serialize_state() -> Dictionary:
	var packed_best_splits := {}
	for split_id in best_splits.keys():
		packed_best_splits[String(split_id)] = float(best_splits[split_id])
	var packed_level_bests := {}
	for level_id in best_time_by_level.keys():
		packed_level_bests[String(level_id)] = float(best_time_by_level[level_id])
	return {
		"best_time_seconds": best_time_seconds,
		"best_splits": packed_best_splits,
		"best_time_by_level": packed_level_bests
	}

func restore_state(data: Dictionary) -> void:
	best_time_seconds = float(data.get("best_time_seconds", -1.0))
	best_splits.clear()
	var packed_best_splits: Dictionary = data.get("best_splits", {})
	for key in packed_best_splits.keys():
		best_splits[int(key)] = float(packed_best_splits[key])
	best_time_by_level.clear()
	var packed_level_bests: Dictionary = data.get("best_time_by_level", {})
	for key in packed_level_bests.keys():
		best_time_by_level[String(key)] = float(packed_level_bests[key])
