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
# Dictionary of all loaded dialogues. Key = id string, value = dialogue dict.
var _all_dialogues: Dictionary = {}

# The dialogue currently being shown and where we are in its line list.
var _current: Dictionary = {}
var _line_index: int = 0
var _active: bool = false

const DIALOGUE_DIR = "res://data/dialogue/"


# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_all_dialogues()


# ── Public API ────────────────────────────────────────────────────────────────

## Begin a dialogue by its id string (matches the "id" field in your JSON).
func start_dialogue(dialogue_id: String) -> void:
	if not _all_dialogues.has(dialogue_id):
		push_error("DialogueManager: unknown dialogue id '%s'" % dialogue_id)
		return
	_current = _all_dialogues[dialogue_id]
	_line_index = 0
	_active = true
	emit_signal("dialogue_started", dialogue_id)
	_show_line()


## Called by DialogueBox when the player presses Space/Enter.
## Moves to the next line, or ends the dialogue if we're at the last line.
func advance() -> void:
	if not _active:
		return
	# If the current line has choices, the player must click one — no skipping.
	if _current_line().has("choices"):
		return
	_line_index += 1
	if _line_index >= _current.get("lines", []).size():
		_end_dialogue()
	else:
		_show_line()


## Called by DialogueBox when the player clicks a choice button.
## choice_index is the button's position in the list (0, 1, 2...).
func make_choice(choice_index: int) -> void:
	var line := _current_line()
	if not line.has("choices"):
		return
	var choice: Dictionary = line["choices"][choice_index]

	if choice.has("rep_delta"):
		for faction: String in choice["rep_delta"]:
			FactionManager.modify(faction, choice["rep_delta"][faction])

	if choice.has("quest_start"):
		QuestManager.start_quest(choice["quest_start"])

	# Jump to a follow-up dialogue id, or end if no "next" key.
	if choice.has("next") and choice["next"] != null:
		start_dialogue(choice["next"])
	else:
		_end_dialogue()


## Returns true while a conversation is visible on screen.
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
		emit_signal("choices_presented", line["choices"])


func _end_dialogue() -> void:
	_active = false
	_current = {}
	_line_index = 0
	emit_signal("dialogue_finished")
