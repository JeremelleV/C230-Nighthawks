extends Node
## DialogueManager — Autoload Singleton
##
## The central controller for all dialogue in the game.
## Any script can call:
##   DialogueManager.start_dialogue("some_id")
##
## This manager:
##   1. Loads all .json files from data/dialogue/ on startup
##   2. Sequences lines and handles branching choices
##   3. Talks to the DialogueBox UI via signals


# ── Signals ───────────────────────────────────────────────────────────────────
## Fired when a new conversation begins. The UI shows itself in response.
signal dialogue_started(dialogue_id: String)

## Fired when all lines are done. The UI hides itself in response.
signal dialogue_finished

## Fired for each line. The UI updates speaker name, portrait, and text.
signal line_displayed(speaker: String, text: String, portrait: String)

## Fired when a line has player choices. The UI builds choice buttons.
signal choices_presented(choices: Array)


# ── Internal State ────────────────────────────────────────────────────────────
var _all_dialogues: Dictionary = {}
var _current: Dictionary = {}
var _line_index: int = 0
var _active: bool = false
var _filtered_choices: Array = []

const DIALOGUE_DIR = "res://data/dialogue/"


# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_all_dialogues()


# ── Public API ────────────────────────────────────────────────────────────────

func start_dialogue(dialogue_id: String) -> void:
	if not _all_dialogues.has(dialogue_id):
		push_error("DialogueManager: unknown dialogue id '%s'" % dialogue_id)
		return
	_current = _all_dialogues[dialogue_id]
	_line_index = 0
	_active = true
	_filtered_choices = []
	emit_signal("dialogue_started", dialogue_id)
	_show_line()


func advance() -> void:
	if not _active:
		return
	# Block advance when choices are waiting — player must click one.
	if _current_line().has("choices") and not _filtered_choices.is_empty():
		return
	_line_index += 1
	if _line_index >= _current.get("lines", []).size():
		_end_dialogue()
	else:
		_show_line()


func make_choice(choice_index: int) -> void:
	if choice_index >= _filtered_choices.size():
		return
	var choice: Dictionary = _filtered_choices[choice_index]

	if choice.has("rep_delta"):
		for faction: String in choice["rep_delta"]:
			FactionManager.modify(faction, choice["rep_delta"][faction])

	if choice.has("quest_start"):
		QuestManager.start_quest(choice["quest_start"])

	if choice.has("earn_money"):
		EconomyManager.earn(choice["earn_money"])

	if choice.has("give_item"):
		var gi: Dictionary = choice["give_item"]
		InventoryManager.add_item(gi["id"], gi.get("quantity", 1))

	# quest_start must run before complete_quest so the quest is ACTIVE when completed.
	if choice.has("complete_quest"):
		QuestManager.complete_quest(choice["complete_quest"])

	if choice.has("remove_item"):
		var ri: Dictionary = choice["remove_item"]
		InventoryManager.remove_item(ri["id"], ri.get("quantity", 1))

	if choice.has("next") and choice["next"] != null:
		start_dialogue(choice["next"])
	else:
		_end_dialogue()


func is_active() -> bool:
	return _active


# ── Private ───────────────────────────────────────────────────────────────────

func _load_all_dialogues() -> void:
	var dir := DirAccess.open(DIALOGUE_DIR)
	if dir == null:
		push_warning("DialogueManager: folder not found — %s" % DIALOGUE_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			_load_file(DIALOGUE_DIR + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueManager: cannot open %s" % path)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("DialogueManager: bad JSON in %s — %s" % [path, json.get_error_message()])
		return
	var data = json.get_data()
	if data is Array:
		for entry: Dictionary in data:
			_all_dialogues[entry["id"]] = entry
	elif data is Dictionary:
		_all_dialogues[data["id"]] = data
	print("DialogueManager: loaded ", path)


func _current_line() -> Dictionary:
	var lines: Array = _current.get("lines", [])
	if _line_index < lines.size():
		return lines[_line_index]
	return {}


func _show_line() -> void:
	var line := _current_line()
	if line.is_empty():
		_end_dialogue()
		return
	emit_signal("line_displayed",
		line.get("speaker", ""),
		line.get("text", ""),
		line.get("portrait", "")
	)
	if line.has("choices"):
		_filtered_choices = _filter_choices(line["choices"])
		emit_signal("choices_presented", _filtered_choices)


func _filter_choices(choices: Array) -> Array:
	var result: Array = []
	for choice: Dictionary in choices:
		if not choice.has("condition") or _check_condition(choice["condition"]):
			result.append(choice)
	return result


func _check_condition(condition) -> bool:
	# Supports a single condition dict or an array of conditions (all must pass).
	if condition is Array:
		for c in condition:
			if not _check_condition(c):
				return false
		return true
	match condition.get("type", ""):
		"has_item":
			return InventoryManager.get_quantity(condition.get("id", "")) >= condition.get("quantity", 1)
		"quest_active":
			return QuestManager.get_state(condition.get("id", "")) == QuestManager.QuestState.ACTIVE
		"quest_available":
			return QuestManager.get_state(condition.get("id", "")) == QuestManager.QuestState.AVAILABLE
		"quest_completed":
			return QuestManager.get_state(condition.get("id", "")) == QuestManager.QuestState.COMPLETED
		"rep_above":
			return FactionManager.get_rep(condition.get("faction", "")) >= condition.get("threshold", 0)
		"rep_below":
			return FactionManager.get_rep(condition.get("faction", "")) < condition.get("threshold", 0)
	return true


func _end_dialogue() -> void:
	_active = false
	_current = {}
	_line_index = 0
	_filtered_choices = []
	emit_signal("dialogue_finished")
