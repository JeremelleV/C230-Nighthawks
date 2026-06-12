extends CanvasLayer

@onready var _shop_name_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderRow/ShopNameLabel
@onready var _balance_label: Label = $Panel/MarginContainer/VBoxContainer/HeaderRow/BalanceLabel
@onready var _buy_tab: Button = $Panel/MarginContainer/VBoxContainer/TabRow/BuyTabButton
@onready var _sell_tab: Button = $Panel/MarginContainer/VBoxContainer/TabRow/SellTabButton
@onready var _item_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ItemListContainer
@onready var _status_label: Label = $Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var _close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

var _showing_buy: bool = true


func _ready() -> void:
	visible = false
	ShopManager.shop_opened.connect(_on_shop_opened)
	ShopManager.shop_closed.connect(_on_shop_closed)
	ShopManager.purchase_succeeded.connect(func(_item): _refresh())
	ShopManager.purchase_failed.connect(func(_item): _show_status("Not enough $MRS"))
	ShopManager.sale_succeeded.connect(func(_item): _refresh())
	EconomyManager.balance_changed.connect(_on_balance_changed)
	_buy_tab.pressed.connect(_show_buy)
	_sell_tab.pressed.connect(_show_sell)
	_close_button.pressed.connect(ShopManager.close_shop)
	_apply_theme()
	_update_balance_label(EconomyManager.get_balance())


func _apply_theme() -> void:
	UIStyle.style_panel($Panel)
	_shop_name_label.add_theme_color_override("font_color", UIStyle.TEXT)
	_balance_label.add_theme_color_override("font_color", UIStyle.TEXT_CURRENCY)
	_status_label.add_theme_color_override("font_color", UIStyle.TEXT_ERROR)
	UIStyle.style_button(_buy_tab)
	UIStyle.style_button(_sell_tab)
	UIStyle.style_button(_close_button)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			ShopManager.close_shop()
			get_viewport().set_input_as_handled()


func _on_shop_opened(shop: Dictionary) -> void:
	_shop_name_label.text = shop.get("name", "Shop")
	_status_label.text = ""
	_showing_buy = true
	visible = true
	_show_buy()


func _on_shop_closed() -> void:
	visible = false
	_clear_list()


func _on_balance_changed(new_balance: int) -> void:
	_update_balance_label(new_balance)


func _update_balance_label(balance: int) -> void:
	_balance_label.text = "$MRS %d" % balance


func _show_buy() -> void:
	_showing_buy = true
	_clear_list()
	for item: Dictionary in ShopManager.get_shop_items():
		_item_list.add_child(_make_buy_row(item))


func _show_sell() -> void:
	_showing_buy = false
	_clear_list()
	var owned: Dictionary = InventoryManager.get_all_items()
	var has_sellable := false
	for item_id: String in owned:
		var item: Dictionary = ShopManager.get_item(item_id)
		if item.is_empty() or item.get("category") == "key_item":
			continue
		_item_list.add_child(_make_sell_row(item, owned[item_id]))
		has_sellable = true
	if not has_sellable:
		var empty_label := Label.new()
		empty_label.text = "Nothing to sell."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_item_list.add_child(empty_label)


func _refresh() -> void:
	if _showing_buy:
		_show_buy()
	else:
		_show_sell()


func _show_status(message: String) -> void:
	_status_label.text = message
	get_tree().create_timer(2.0).timeout.connect(func():
		if _status_label.text == message:
			_status_label.text = ""
	)


func _make_buy_row(item: Dictionary) -> Control:
	var wrapper := VBoxContainer.new()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = item.get("name", "")
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", UIStyle.TEXT)

	var desc_label := Label.new()
	desc_label.text = item.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	info.add_child(name_label)
	info.add_child(desc_label)

	var item_id: String = item["id"]
	var base_price: int = item.get("price", 0)
	var actual_price: int = ShopManager.get_buy_price(item_id)

	var price_col := VBoxContainer.new()
	price_col.alignment = BoxContainer.ALIGNMENT_CENTER

	var price_label := Label.new()
	price_label.text = "$MRS %d" % actual_price
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_label.add_theme_color_override("font_color", UIStyle.TEXT_CURRENCY)
	price_col.add_child(price_label)

	if actual_price < base_price:
		var pct: int = roundi((1.0 - float(actual_price) / float(base_price)) * 100)
		var disc_label := Label.new()
		disc_label.text = "-%d%%" % pct
		disc_label.add_theme_color_override("font_color", Color(0.40, 0.90, 0.45))
		disc_label.add_theme_font_size_override("font_size", 11)
		price_col.add_child(disc_label)

	var buy_btn := Button.new()
	buy_btn.text = "Buy"
	buy_btn.disabled = not EconomyManager.can_afford(actual_price)
	UIStyle.style_button(buy_btn)
	buy_btn.pressed.connect(func(): ShopManager.buy_item(item_id))

	row.add_child(info)
	row.add_child(price_col)
	row.add_child(buy_btn)

	wrapper.add_child(row)
	wrapper.add_child(HSeparator.new())

	return wrapper


func _make_sell_row(item: Dictionary, quantity: int) -> Control:
	var wrapper := VBoxContainer.new()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = item.get("name", "")
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", UIStyle.TEXT)

	var desc_label := Label.new()
	desc_label.text = item.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)

	info.add_child(name_label)
	info.add_child(desc_label)

	var qty_label := Label.new()
	qty_label.text = "x%d" % quantity
	qty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	qty_label.custom_minimum_size = Vector2(32, 0)
	qty_label.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)

	var price_label := Label.new()
	price_label.text = "$MRS %d" % item.get("sell_price", 0)
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_label.add_theme_color_override("font_color", UIStyle.TEXT_CURRENCY)

	var sell_btn := Button.new()
	sell_btn.text = "Sell"
	UIStyle.style_button(sell_btn)
	var item_id: String = item["id"]
	sell_btn.pressed.connect(func(): ShopManager.sell_item(item_id))

	row.add_child(info)
	row.add_child(qty_label)
	row.add_child(price_label)
	row.add_child(sell_btn)

	wrapper.add_child(row)
	wrapper.add_child(HSeparator.new())

	return wrapper


func _clear_list() -> void:
	for child: Node in _item_list.get_children():
		child.queue_free()
