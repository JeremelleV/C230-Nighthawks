extends Node

signal reputation_changed(faction_id: String, delta: int, new_value: int, new_status: String)

const FACTIONS_PATH = "res://data/factions/factions.json"

var _reputations: Dictionary = {}
var _faction_data: Dictionary = {}


func _ready() -> void:
	_load_factions()


func _load_factions() -> void:
	var file := FileAccess.open(FACTIONS_PATH, FileAccess.READ)
	if not file:
		push_error("FactionManager: could not open '%s'" % FACTIONS_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		push_error("FactionManager: expected Array in factions.json")
		return
	for entry: Dictionary in parsed:
		_faction_data[entry["id"]] = entry
		_reputations[entry["id"]] = entry.get("starting_rep", 0)


func modify(faction_id: String, amount: int) -> void:
	if not _reputations.has(faction_id):
		push_error("FactionManager: unknown faction '%s'" % faction_id)
		return
	var old_value: int = _reputations[faction_id]
	_reputations[faction_id] = clamp(old_value + amount, -100, 100)
	var actual_delta: int = _reputations[faction_id] - old_value
	if actual_delta == 0:
		return
	reputation_changed.emit(faction_id, actual_delta, _reputations[faction_id], get_status(faction_id))


func get_rep(faction_id: String) -> int:
	return _reputations.get(faction_id, 0)


func get_status(faction_id: String) -> String:
	var rep: int = get_rep(faction_id)
	if rep >= 50:
		return "Allied"
	elif rep >= 10:
		return "Friendly"
	elif rep >= -9:
		return "Neutral"
	elif rep >= -50:
		return "Unfriendly"
	else:
		return "Enemy"


func get_faction_name(faction_id: String) -> String:
	return _faction_data.get(faction_id, {}).get("name", faction_id)


func get_all() -> Dictionary:
	return _reputations.duplicate()
