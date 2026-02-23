extends Node

signal key_collected(key_id: StringName)
signal ability_unlocked(ability_id: StringName)
signal level_completed(level_id: StringName)

var _keys: Dictionary = {}
var _abilities: Dictionary = {}
var _completed_levels: Dictionary = {}

func collect_key(key_id: StringName) -> void:
	if _keys.has(key_id):
		return
	_keys[key_id] = true
	emit_signal("key_collected", key_id)

func unlock_ability(ability_id: StringName) -> void:
	if _abilities.has(ability_id):
		return
	_abilities[ability_id] = true
	emit_signal("ability_unlocked", ability_id)

func has_key(key_id: StringName) -> bool:
	return _keys.has(key_id)

func has_ability(ability_id: StringName) -> bool:
	return _abilities.has(ability_id)

func mark_level_completed(level_id: StringName) -> void:
	if level_id == &"":
		return
	if _completed_levels.has(level_id):
		return
	_completed_levels[level_id] = true
	emit_signal("level_completed", level_id)

func has_completed_level(level_id: StringName) -> bool:
	return _completed_levels.has(level_id)

func serialize_state() -> Dictionary:
	return {
		"keys": _keys.keys(),
		"abilities": _abilities.keys(),
		"completed_levels": _completed_levels.keys()
	}

func restore_state(data: Dictionary) -> void:
	_keys.clear()
	_abilities.clear()
	_completed_levels.clear()
	for key_id in data.get("keys", []):
		_keys[StringName(key_id)] = true
	for ability_id in data.get("abilities", []):
		_abilities[StringName(ability_id)] = true
	for level_id in data.get("completed_levels", []):
		_completed_levels[StringName(level_id)] = true
