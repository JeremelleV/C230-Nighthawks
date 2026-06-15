extends CanvasLayer

@onready var _panel: Panel = $Panel
@onready var _balance_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderRow/BalanceLabel
@onready var _list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ItemListContainer
@onready var _empty_label: Label = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ItemListContainer/EmptyLabel
@onready var _close_btn: Button = $Panel/MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	_apply_theme()
	_close_btn.pressed.connect(hide)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	hide()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			toggle()
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_ESCAPE:
			hide()
			get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		hide()
	else:
		_refresh()
		show()


func _apply_theme() -> void:
	UIStyle.style_panel(_panel)
	UIStyle.style_button(_close_btn)
	_balance_label.add_theme_color_override("font_color", UIStyle.TEXT_CURRENCY)
	_balance_label.add_theme_font_size_override("font_size", 15)
	$Panel/MarginContainer/VBoxContainer/HeaderRow/TitleLabel.add_theme_color_override("font_color", UIStyle.TEXT)


func _on_inventory_changed() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	_balance_label.text = "$MRS %d" % EconomyManager.get_balance()

	for child in _list.get_children():
		if child != _empty_label:
			child.queue_free()

	var items: Dictionary = InventoryManager.get_all_items()

	if items.is_empty():
		_empty_label.visible = true
		return

	_empty_label.visible = false

	for item_id: String in items:
		var quantity: int = items[item_id]
		var data: Dictionary = ShopManager.get_item(item_id)
		_list.add_child(_make_row(item_id, quantity, data))


func _make_row(item_id: String, quantity: int, data: Dictionary) -> Control:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = data.get("name", item_id)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", UIStyle.TEXT)
	name_label.add_theme_font_size_override("font_size", 14)
	row.add_child(name_label)

	var qty_label := Label.new()
	qty_label.text = "x%d" % quantity
	qty_label.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)
	qty_label.add_theme_font_size_override("font_size", 14)
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(qty_label)

	var sell_price: int = data.get("sell_price", 0)
	if sell_price > 0:
		var value_label := Label.new()
		value_label.text = "↑ $%d" % sell_price
		value_label.add_theme_color_override("font_color", UIStyle.TEXT_CURRENCY)
		value_label.add_theme_font_size_override("font_size", 13)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value_label)

	container.add_child(row)

	var desc := Label.new()
	desc.text = data.get("description", "")
	desc.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)
	desc.add_theme_font_size_override("font_size", 11)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 440.0
	container.add_child(desc)

	var sep := HSeparator.new()
	container.add_child(sep)

	return container
