extends CanvasLayer

@onready var _panel: Panel = $Panel
@onready var _title_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderRow/TitleLabel
@onready var _active_btn: Button = $Panel/MarginContainer/VBoxContainer/TabRow/ActiveTabButton
@onready var _done_btn: Button = $Panel/MarginContainer/VBoxContainer/TabRow/DoneTabButton
@onready var _list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/QuestListContainer
@onready var _close_btn: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

var _show_active: bool = true


func _ready() -> void:
	_apply_theme()
	_active_btn.pressed.connect(_on_active_tab)
	_done_btn.pressed.connect(_on_done_tab)
	_close_btn.pressed.connect(hide)
	QuestManager.quest_started.connect(func(_id): _refresh())
	QuestManager.quest_completed.connect(func(_id): _refresh())
	QuestManager.objective_updated.connect(func(_qid, _oid, _cur, _req): _refresh())
	hide()


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		hide()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		hide()
	else:
		_show_active = true
		_refresh()
		show()


func _apply_theme() -> void:
	UIStyle.style_panel(_panel)
	_title_label.add_theme_color_override("font_color", UIStyle.TEXT)
	for btn in [_active_btn, _done_btn, _close_btn]:
		UIStyle.style_button(btn)


func _on_active_tab() -> void:
	_show_active = true
	_refresh()


func _on_done_tab() -> void:
	_show_active = false
	_refresh()


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()

	var quests: Array = QuestManager.get_active_quests() if _show_active else QuestManager.get_completed_quests()

	if quests.is_empty():
		var empty := Label.new()
		empty.text = "No active quests." if _show_active else "No completed quests."
		empty.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)
		empty.add_theme_font_size_override("font_size", 14)
		_list.add_child(empty)
		return

	for quest: Dictionary in quests:
		_list.add_child(_make_quest_entry(quest))


func _make_quest_entry(quest: Dictionary) -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var title := Label.new()
	title.text = quest.get("title", "???")
	title.add_theme_color_override("font_color", UIStyle.TEXT)
	title.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = quest.get("description", "")
	desc.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)
	desc.add_theme_font_size_override("font_size", 12)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 520.0
	vbox.add_child(desc)

	for obj: Dictionary in quest.get("objectives", []):
		vbox.add_child(_make_objective_row(quest["id"], obj))

	return vbox


func _make_objective_row(quest_id: String, obj: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var required: int = obj.get("required", 1)
	var current: int = QuestManager.get_progress(quest_id, obj["id"])
	var done: bool = current >= required

	var check := Label.new()
	check.text = "✓" if done else "○"
	check.add_theme_color_override("font_color", Color(0.40, 0.90, 0.45) if done else UIStyle.TEXT_MUTED)
	check.add_theme_font_size_override("font_size", 13)
	row.add_child(check)

	var obj_label := Label.new()
	var base_text: String = obj.get("description", obj["id"])
	obj_label.text = "%s (%d/%d)" % [base_text, current, required] if required > 1 else base_text
	obj_label.add_theme_color_override("font_color", UIStyle.TEXT_MUTED if done else UIStyle.TEXT)
	obj_label.add_theme_font_size_override("font_size", 13)
	row.add_child(obj_label)

	return row
