extends RefCounted
class_name LevelManifestValidator

static func validate(manifest: LevelManifest) -> PackedStringArray:
	var issues: PackedStringArray = []
	if manifest == null:
		issues.append("Manifest missing.")
		return issues
	var seen_ids: Dictionary = {}
	for i in range(manifest.levels.size()):
		var entry: LevelManifestEntry = manifest.levels[i]
		if entry == null:
			issues.append("Entry %d is null." % i)
			continue
		if entry.level_id == &"":
			issues.append("Entry %d has empty level_id." % i)
		elif seen_ids.has(entry.level_id):
			issues.append("Duplicate level_id: %s" % String(entry.level_id))
		else:
			seen_ids[entry.level_id] = true
		if entry.scene == null:
			issues.append("Entry %s has no scene." % String(entry.level_id))
		if entry.gold_medal_seconds > entry.silver_medal_seconds or entry.silver_medal_seconds > entry.bronze_medal_seconds:
			issues.append("Entry %s medal thresholds are not ordered." % String(entry.level_id))
	for entry in manifest.levels:
		if entry == null:
			continue
		for prereq in entry.prerequisite_level_ids:
			if prereq == "":
				continue
			if not seen_ids.has(StringName(prereq)):
				issues.append("Entry %s has unknown prerequisite: %s" % [String(entry.level_id), prereq])
	return issues
