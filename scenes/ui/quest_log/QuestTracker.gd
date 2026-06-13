extends CanvasLayer

@onready var _toggle_btn: Button = $Container/ToggleButton
@onready var _quest_panel: PanelContainer = $Container/QuestPanel
@onready var _quest_list: VBoxContainer = $Container/QuestPanel/MarginContainer/QuestList

var _expanded: bool = true


func _ready() -> void:
	_apply_theme()
	_toggle_btn.pressed.connect(_on_toggle)
	QuestManager.quest_started.connect(func(_id): _refresh())
	QuestManager.objective_updated.connect(func(_qid, _oid, _cur, _req): _refresh())
	QuestManager.quest_completed.connect(func(_id): _refresh())
	_refresh()


func _apply_theme() -> void:
	UIStyle.style_button(_toggle_btn)
	var style := UIStyle.panel_style()
	_quest_panel.add_theme_stylebox_override("panel", style)


func _on_toggle() -> void:
	_expanded = not _expanded
	_quest_panel.visible = _expanded
	_toggle_btn.text = "Quests  ▲" if _expanded else "Quests  ▼"


func _refresh() -> void:
	for child in _quest_list.get_children():
		child.queue_free()

	var active: Array = QuestManager.get_active_quests()

	if active.is_empty():
		_quest_panel.visible = false
		_toggle_btn.visible = false
		return

	_toggle_btn.visible = true
	_quest_panel.visible = _expanded

	for quest: Dictionary in active:
		_quest_list.add_child(_make_entry(quest))


func _make_entry(quest: Dictionary) -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)

	var title := Label.new()
	title.text = quest.get("title", "???")
	title.add_theme_color_override("font_color", UIStyle.TEXT)
	title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title)

	for obj: Dictionary in quest.get("objectives", []):
		var required: int = obj.get("required", 1)
		var current: int = QuestManager.get_progress(quest["id"], obj["id"])
		var done: bool = current >= required

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)

		var check := Label.new()
		check.text = "✓" if done else "·"
		check.add_theme_color_override("font_color", Color(0.40, 0.90, 0.45) if done else UIStyle.TEXT_MUTED)
		check.add_theme_font_size_override("font_size", 12)
		row.add_child(check)

		var obj_label := Label.new()
		var base: String = obj.get("description", obj["id"])
		obj_label.text = "%s (%d/%d)" % [base, current, required] if required > 1 else base
		obj_label.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)
		obj_label.add_theme_font_size_override("font_size", 12)
		row.add_child(obj_label)

		vbox.add_child(row)

	if quest != QuestManager.get_active_quests().back():
		var sep := HSeparator.new()
		vbox.add_child(sep)

	return vbox
