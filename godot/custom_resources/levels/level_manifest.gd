extends Resource
class_name LevelManifest

@export var levels: Array[LevelManifestEntry] = []

func get_level_count() -> int:
	return levels.size()

func get_level(index: int) -> LevelManifestEntry:
	if index < 0 or index >= levels.size():
		return null
	return levels[index]

func get_level_index_by_id(level_id: StringName) -> int:
	for i in range(levels.size()):
		var entry := levels[i]
		if entry != null and entry.level_id == level_id:
			return i
	return -1

func get_level_by_id(level_id: StringName) -> LevelManifestEntry:
	var idx := get_level_index_by_id(level_id)
	if idx == -1:
		return null
	return levels[idx]

func get_level_by_scene_path(scene_path: String) -> LevelManifestEntry:
	if scene_path == "":
		return null
	for entry in levels:
		if entry == null or entry.scene == null:
			continue
		if entry.scene.resource_path == scene_path:
			return entry
	return null

func get_next_level(current_level_id: StringName) -> LevelManifestEntry:
	var idx := get_level_index_by_id(current_level_id)
	if idx == -1:
		return null
	for i in range(idx + 1, levels.size()):
		if levels[i] != null:
			return levels[i]
	return null
