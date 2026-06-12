extends Node

signal quest_started(quest_id: String)
signal objective_updated(quest_id: String, objective_id: String, current: int, required: int)
signal quest_completed(quest_id: String)

const QUESTS_PATH = "res://data/quests/quests.json"

enum QuestState { AVAILABLE, ACTIVE, COMPLETED, FAILED }

var _quest_data: Dictionary = {}
var _quest_states: Dictionary = {}
var _progress: Dictionary = {}


func _ready() -> void:
	_load_quests()
	InventoryManager.inventory_changed.connect(_on_inventory_changed)


func _load_quests() -> void:
	var file := FileAccess.open(QUESTS_PATH, FileAccess.READ)
	if not file:
		push_error("QuestManager: could not open '%s'" % QUESTS_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		push_error("QuestManager: expected Array in quests.json")
		return
	for quest: Dictionary in parsed:
		var qid: String = quest["id"]
		_quest_data[qid] = quest
		_quest_states[qid] = QuestState.AVAILABLE
		_progress[qid] = {}
		for obj: Dictionary in quest.get("objectives", []):
			_progress[qid][obj["id"]] = 0


func start_quest(quest_id: String) -> bool:
	if not _quest_data.has(quest_id):
		push_error("QuestManager: unknown quest '%s'" % quest_id)
		return false
	if _quest_states[quest_id] != QuestState.AVAILABLE:
		return false
	_quest_states[quest_id] = QuestState.ACTIVE
	quest_started.emit(quest_id)
	return true


func get_state(quest_id: String) -> QuestState:
	return _quest_states.get(quest_id, QuestState.AVAILABLE)


func get_progress(quest_id: String, objective_id: String) -> int:
	return _progress.get(quest_id, {}).get(objective_id, 0)


func notify_enemies_defeated(count: int) -> void:
	for qid: String in _quest_states:
		if _quest_states[qid] != QuestState.ACTIVE:
			continue
		for obj: Dictionary in _quest_data[qid].get("objectives", []):
			if obj.get("type") == "defeat_enemy":
				_advance(qid, obj["id"], count, obj.get("required", 1))


func _advance(quest_id: String, obj_id: String, amount: int, required: int) -> void:
	var current: int = _progress[quest_id][obj_id]
	if current >= required:
		return
	_progress[quest_id][obj_id] = mini(current + amount, required)
	objective_updated.emit(quest_id, obj_id, _progress[quest_id][obj_id], required)
	_check_completion(quest_id)


func _on_inventory_changed() -> void:
	for qid: String in _quest_states:
		if _quest_states[qid] != QuestState.ACTIVE:
			continue
		for obj: Dictionary in _quest_data[qid].get("objectives", []):
			if obj.get("type") != "collect_item":
				continue
			var item_id: String = obj.get("item_id", "")
			var required: int = obj.get("required", 1)
			var current: int = mini(InventoryManager.get_quantity(item_id), required)
			if _progress[qid][obj["id"]] != current:
				_progress[qid][obj["id"]] = current
				objective_updated.emit(qid, obj["id"], current, required)
				_check_completion(qid)


func _check_completion(quest_id: String) -> void:
	var quest: Dictionary = _quest_data[quest_id]
	for obj: Dictionary in quest.get("objectives", []):
		if _progress[quest_id][obj["id"]] < obj.get("required", 1):
			return
	_grant_rewards(quest_id)
	_quest_states[quest_id] = QuestState.COMPLETED
	quest_completed.emit(quest_id)


func _grant_rewards(quest_id: String) -> void:
	var rewards: Dictionary = _quest_data[quest_id].get("rewards", {})
	if rewards.get("money", 0) > 0:
		EconomyManager.earn(rewards["money"])
	for item_id: String in rewards.get("items", []):
		InventoryManager.add_item(item_id, 1)
	for faction_id: String in rewards.get("reputation", {}):
		FactionManager.modify(faction_id, rewards["reputation"][faction_id])


func get_active_quests() -> Array:
	var result: Array = []
	for qid: String in _quest_states:
		if _quest_states[qid] == QuestState.ACTIVE:
			result.append(_quest_data[qid])
	return result


func get_completed_quests() -> Array:
	var result: Array = []
	for qid: String in _quest_states:
		if _quest_states[qid] == QuestState.COMPLETED:
			result.append(_quest_data[qid])
	return result


func get_quest(quest_id: String) -> Dictionary:
	return _quest_data.get(quest_id, {})
