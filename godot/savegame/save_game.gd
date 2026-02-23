## Script that manages saving games.
extends Node

const ENABLED = true
const ENCRYPTION_KEY = "godotrules"
const SAVE_GAME_TEMPLATE = "savegame_slot_%d.save"
const SAVE_GROUP_NAME = "Persist"
const MAX_SLOTS = 3
const PROFILE_FILE = "user://profiles.cfg"
const PROFILE_SECTION_PREFIX = "slot_"
const PROFILE_NAME_KEY = "name"
const PROFILE_PLAYTIME_KEY = "playtime_seconds"
const PROFILE_LAST_PLAYED_KEY = "last_played_unix"
const PROFILE_DEATHS_KEY = "deaths"
const DEFAULT_SLOT_NAME = "Profile %d"

var _active_slot: int = 1
var _profile_config: ConfigFile
var _playtime_accumulator_seconds: float = 0.0

static func get_available_slots() -> Array[int]:
	return [1, 2, 3]

func _ready() -> void:
	_profile_config = ConfigFile.new()
	_profile_config.load(PROFILE_FILE)
	_ensure_profile_defaults()

func _process(delta: float) -> void:
	if get_tree() == null:
		return
	if get_tree().paused:
		return
	_playtime_accumulator_seconds += delta

func set_active_slot(slot: int) -> void:
	_flush_playtime_to_profile()
	_active_slot = clampi(slot, 1, MAX_SLOTS)
	_ensure_profile_defaults()

func get_active_slot() -> int:
	return _active_slot

func _slot_to_path(slot: int = -1) -> String:
	var resolved_slot: int = _active_slot if slot <= 0 else clampi(slot, 1, MAX_SLOTS)
	return "user://" + (SAVE_GAME_TEMPLATE % resolved_slot)

func delete_save(slot: int = -1) -> void:
	
	if not ENABLED:
		return
		
	DirAccess.remove_absolute(_slot_to_path(slot))
	if slot <= 0:
		_reset_profile_slot(_active_slot)
	else:
		_reset_profile_slot(clampi(slot, 1, MAX_SLOTS))

func has_save(slot: int = -1) -> bool:
	return FileAccess.file_exists(_slot_to_path(slot))

func save_game(tree: SceneTree, slot: int = -1):
	
	if not ENABLED:
		return
	_flush_playtime_to_profile()
	var resolved_slot: int = _active_slot if slot <= 0 else clampi(slot, 1, MAX_SLOTS)
	_set_profile_value(resolved_slot, PROFILE_LAST_PLAYED_KEY, int(Time.get_unix_time_from_system()))
	
	print("Saving game to %s" % _slot_to_path(slot))
	
	var save_file = null
	
	if OS.is_debug_build():
		save_file = FileAccess.open(_slot_to_path(slot), FileAccess.WRITE)
	else:
		save_file = FileAccess.open_encrypted_with_pass(_slot_to_path(slot), FileAccess.WRITE, ENCRYPTION_KEY)
		
	var save_nodes = tree.get_nodes_in_group(SAVE_GROUP_NAME)
	
	for node in save_nodes:
		
		var save_data = {}
		
		# Check the node is an instanced scene so it can be instanced again during load.
		if not node.scene_file_path.is_empty():
			save_data["scene_file_path"] = node.scene_file_path
			
		if not node.get_path().is_empty():
			save_data["path"] = node.get_path()
			
		if not node.get_parent().get_path().is_empty():
			save_data["parent"] = node.get_parent().get_path()
			
		if "position" in node:
			save_data["pos_x"] = node.position.x
			save_data["pos_y"] = node.position.y
			if node.position is Vector3:
				save_data["pos_z"] = node.position.z
				
		if node is Node2D:
			save_data["rotation"] = node.rotation
		elif node is Node3D:
			save_data["rotation_x"] = node.rotation.x
			save_data["rotation_y"] = node.rotation.y
			save_data["rotation_z"] = node.rotation.z

		if "scale" in node:
			save_data["scale_x"] = node.scale.x
			save_data["scale_y"] = node.scale.y
			if node.scale is Vector3:
				save_data["scale_z"] = node.scale.z
	
		save_data["visible"] = node.visible

		if node is CanvasItem:
			save_data["modulate_r"] = node.modulate.r
			save_data["modulate_g"] = node.modulate.g
			save_data["modulate_b"] = node.modulate.b
			save_data["modulate_a"] = node.modulate.a

		# Call the node's save function.
		if node.has_method("save_data"):
			save_data["node_data"] = node.call("save_data")
		
		# Store the save dictionary as a new line in the save file.
		save_file.store_line(JSON.stringify(save_data))

	# Persist global gameplay state that is not tied to a scene node.
	save_file.store_line(JSON.stringify({
		"__gamemanager__": true,
		"state": GameManager.serialize_state()
	}))
	save_file.store_line(JSON.stringify({
		"__progression__": true,
		"state": GameProgression.serialize_state()
	}))
	save_file.store_line(JSON.stringify({
		"__runstats__": true,
		"state": RunStats.serialize_state()
	}))
	_save_profile_config()

func load_globals_only(slot: int = -1) -> void:
	if not ENABLED:
		return
	if not has_save(slot):
		_reset_global_state()
		return
	_reset_global_state()
	var save_file = null
	if OS.is_debug_build():
		save_file = FileAccess.open(_slot_to_path(slot), FileAccess.READ)
	else:
		save_file = FileAccess.open_encrypted_with_pass(_slot_to_path(slot), FileAccess.READ, ENCRYPTION_KEY)
	while save_file.get_position() < save_file.get_length():
		var test_json_conv = JSON.new()
		test_json_conv.parse(save_file.get_line())
		var save_data = test_json_conv.get_data()
		if save_data.has("__gamemanager__") and save_data["__gamemanager__"] == true:
			if save_data.has("state") and save_data["state"] is Dictionary:
				GameManager.restore_state(save_data["state"])
			continue
		if save_data.has("__progression__") and save_data["__progression__"] == true:
			if save_data.has("state") and save_data["state"] is Dictionary:
				GameProgression.restore_state(save_data["state"])
			continue
		if save_data.has("__runstats__") and save_data["__runstats__"] == true:
			if save_data.has("state") and save_data["state"] is Dictionary:
				RunStats.restore_state(save_data["state"])
			continue

func load_game(tree:SceneTree, slot: int = -1) -> void:
	
	if not ENABLED:
		return

	if not has_save(slot):
		print("No save game found. Skipped loading!")
		_reset_global_state()
		return
	_reset_global_state()
	
	print("Load game from %s" % _slot_to_path(slot))
		
	var save_nodes = tree.get_nodes_in_group(SAVE_GROUP_NAME)
	
	var nodes_by_path = {}
	for node in save_nodes:
		if not node.get_path().is_empty():
			nodes_by_path[node.get_path()] = node

	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	var save_file = null
	
	if OS.is_debug_build():
		save_file = FileAccess.open(_slot_to_path(slot), FileAccess.READ)
	else:
		save_file = FileAccess.open_encrypted_with_pass(_slot_to_path(slot), FileAccess.READ, ENCRYPTION_KEY)
		
	while save_file.get_position() < save_file.get_length():
		# Get the saved dictionary from the next line in the save file
		var test_json_conv = JSON.new()
		test_json_conv.parse(save_file.get_line())
		var save_data = test_json_conv.get_data()

		if save_data.has("__gamemanager__") and save_data["__gamemanager__"] == true:
			if save_data.has("state") and save_data["state"] is Dictionary:
				GameManager.restore_state(save_data["state"])
			continue
		if save_data.has("__progression__") and save_data["__progression__"] == true:
			if save_data.has("state") and save_data["state"] is Dictionary:
				GameProgression.restore_state(save_data["state"])
			continue
		if save_data.has("__runstats__") and save_data["__runstats__"] == true:
			if save_data.has("state") and save_data["state"] is Dictionary:
				RunStats.restore_state(save_data["state"])
			continue

		# Firstly, we need to create the object and add it to the tree and set its position.
		var node = null
		
		if "path" in save_data and nodes_by_path.has(NodePath(save_data.path)):
			node = nodes_by_path[NodePath(save_data.path)]
			nodes_by_path.erase(NodePath(save_data.path))
		elif "path" in save_data and "parent" in save_data and "scene_file_path" in save_data:
			# node is not present in tree so it was dynamically added at runtime
			var parent = tree.root.get_node(NodePath(save_data["parent"]))
			node = load(save_data["scene_file_path"]).instantiate()
			parent.add_child(node)
		else:
			push_warning("skipping loading node from save game: node got moved.")
			continue

		if "position" in node:
			if node.scale is Vector2:
				node.position = Vector2(save_data["pos_x"], save_data["pos_y"])
			elif node.scale is Vector3:
				node.position = Vector3(save_data["pos_x"], save_data["pos_y"], save_data["pos_z"])
			
		if node is Node2D:
			node.rotation = save_data["rotation"]
		elif node is Node3D:
			node.rotation = Vector3(save_data["rotation_x"], save_data["rotation_y"], save_data["rotation_z"])
			
		if "scale" in node:
			if node.scale is Vector2:
				node.scale = Vector2(save_data["scale_x"], save_data["scale_y"])
			elif node.scale is Vector3:
				node.scale = Vector3(save_data["scale_x"], save_data["scale_y"], save_data["scale_z"])
				
		if save_data.has("visible") and "visible" in node:
			node.visible = save_data["visible"]
		
		if node is CanvasItem:
			node.modulate = Color(save_data["modulate_r"], save_data["modulate_g"], save_data["modulate_b"], save_data["modulate_a"])
				
		if node.has_method("load_data") and save_data.has("node_data"):
			node.call("load_data", save_data["node_data"])
	
	# delete any node from scene that was not persisted into the save file
	# but is currently tagged as "Persisted" -> this means node got removed in the meantime
	for key in nodes_by_path:
		var node = nodes_by_path[key]
		node.queue_free()

func _reset_global_state() -> void:
	GameManager.restore_state({})
	GameProgression.restore_state({})
	RunStats.restore_state({})

func get_slot_metadata(slot: int = -1) -> Dictionary:
	_flush_playtime_to_profile()
	var resolved_slot: int = _active_slot if slot <= 0 else clampi(slot, 1, MAX_SLOTS)
	var metadata: Dictionary = {
		"slot": resolved_slot,
		"has_save": false,
		"name": get_slot_name(resolved_slot),
		"completed_levels": 0,
		"keys": 0,
		"abilities": 0,
		"best_time_seconds": -1.0,
		"playtime_seconds": get_slot_playtime_seconds(resolved_slot),
		"last_played_unix": get_slot_last_played_unix(resolved_slot),
		"deaths": get_slot_deaths(resolved_slot)
	}
	if not has_save(slot):
		return metadata
	metadata["has_save"] = true
	var global_state: Dictionary = _read_global_state(slot)
	var progression: Dictionary = global_state.get("progression", {})
	var runstats: Dictionary = global_state.get("runstats", {})
	metadata["completed_levels"] = (progression.get("completed_levels", []) as Array).size()
	metadata["keys"] = (progression.get("keys", []) as Array).size()
	metadata["abilities"] = (progression.get("abilities", []) as Array).size()
	metadata["best_time_seconds"] = float(runstats.get("best_time_seconds", -1.0))
	return metadata

func _read_global_state(slot: int = -1) -> Dictionary:
	var result: Dictionary = {
		"gamemanager": {},
		"progression": {},
		"runstats": {}
	}
	if not has_save(slot):
		return result
	var save_file = null
	if OS.is_debug_build():
		save_file = FileAccess.open(_slot_to_path(slot), FileAccess.READ)
	else:
		save_file = FileAccess.open_encrypted_with_pass(_slot_to_path(slot), FileAccess.READ, ENCRYPTION_KEY)
	while save_file.get_position() < save_file.get_length():
		var test_json_conv = JSON.new()
		test_json_conv.parse(save_file.get_line())
		var save_data = test_json_conv.get_data()
		if save_data.has("__gamemanager__") and save_data["__gamemanager__"] == true:
			if save_data.has("state") and save_data["state"] is Dictionary:
				result["gamemanager"] = save_data["state"]
			continue
		if save_data.has("__progression__") and save_data["__progression__"] == true:
			if save_data.has("state") and save_data["state"] is Dictionary:
				result["progression"] = save_data["state"]
			continue
		if save_data.has("__runstats__") and save_data["__runstats__"] == true:
			if save_data.has("state") and save_data["state"] is Dictionary:
				result["runstats"] = save_data["state"]
			continue
	return result

func set_slot_name(slot: int, name: String) -> void:
	var resolved_slot: int = clampi(slot, 1, MAX_SLOTS)
	var safe_name: String = name.strip_edges()
	if safe_name == "":
		safe_name = DEFAULT_SLOT_NAME % resolved_slot
	_set_profile_value(resolved_slot, PROFILE_NAME_KEY, safe_name)
	_save_profile_config()

func get_slot_name(slot: int = -1) -> String:
	var resolved_slot: int = _active_slot if slot <= 0 else clampi(slot, 1, MAX_SLOTS)
	return String(_get_profile_value(resolved_slot, PROFILE_NAME_KEY, DEFAULT_SLOT_NAME % resolved_slot))

func get_slot_playtime_seconds(slot: int = -1) -> float:
	var resolved_slot: int = _active_slot if slot <= 0 else clampi(slot, 1, MAX_SLOTS)
	var base_seconds: float = float(_get_profile_value(resolved_slot, PROFILE_PLAYTIME_KEY, 0.0))
	if resolved_slot == _active_slot:
		return base_seconds + _playtime_accumulator_seconds
	return base_seconds

func get_slot_last_played_unix(slot: int = -1) -> int:
	var resolved_slot: int = _active_slot if slot <= 0 else clampi(slot, 1, MAX_SLOTS)
	return int(_get_profile_value(resolved_slot, PROFILE_LAST_PLAYED_KEY, 0))

func get_slot_deaths(slot: int = -1) -> int:
	var resolved_slot: int = _active_slot if slot <= 0 else clampi(slot, 1, MAX_SLOTS)
	return int(_get_profile_value(resolved_slot, PROFILE_DEATHS_KEY, 0))

func record_death() -> void:
	var current_deaths: int = get_slot_deaths(_active_slot)
	_set_profile_value(_active_slot, PROFILE_DEATHS_KEY, current_deaths + 1)
	_save_profile_config()

func _ensure_profile_defaults() -> void:
	for slot in get_available_slots():
		if _profile_config.has_section_key(_profile_section(slot), PROFILE_NAME_KEY) == false:
			_set_profile_value(slot, PROFILE_NAME_KEY, DEFAULT_SLOT_NAME % slot)
		if _profile_config.has_section_key(_profile_section(slot), PROFILE_PLAYTIME_KEY) == false:
			_set_profile_value(slot, PROFILE_PLAYTIME_KEY, 0.0)
		if _profile_config.has_section_key(_profile_section(slot), PROFILE_LAST_PLAYED_KEY) == false:
			_set_profile_value(slot, PROFILE_LAST_PLAYED_KEY, 0)
		if _profile_config.has_section_key(_profile_section(slot), PROFILE_DEATHS_KEY) == false:
			_set_profile_value(slot, PROFILE_DEATHS_KEY, 0)
	_save_profile_config()

func _reset_profile_slot(slot: int) -> void:
	_set_profile_value(slot, PROFILE_NAME_KEY, DEFAULT_SLOT_NAME % slot)
	_set_profile_value(slot, PROFILE_PLAYTIME_KEY, 0.0)
	_set_profile_value(slot, PROFILE_LAST_PLAYED_KEY, 0)
	_set_profile_value(slot, PROFILE_DEATHS_KEY, 0)
	_save_profile_config()

func _profile_section(slot: int) -> String:
	return "%s%d" % [PROFILE_SECTION_PREFIX, slot]

func _set_profile_value(slot: int, key: String, value: Variant) -> void:
	_profile_config.set_value(_profile_section(slot), key, value)

func _get_profile_value(slot: int, key: String, default_value: Variant) -> Variant:
	return _profile_config.get_value(_profile_section(slot), key, default_value)

func _save_profile_config() -> void:
	_profile_config.save(PROFILE_FILE)

func _flush_playtime_to_profile() -> void:
	if _playtime_accumulator_seconds <= 0.0:
		return
	var current_playtime: float = float(_get_profile_value(_active_slot, PROFILE_PLAYTIME_KEY, 0.0))
	_set_profile_value(_active_slot, PROFILE_PLAYTIME_KEY, current_playtime + _playtime_accumulator_seconds)
	_playtime_accumulator_seconds = 0.0
	_save_profile_config()
