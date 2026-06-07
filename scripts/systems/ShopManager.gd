extends Node

signal shop_opened(shop: Dictionary)
signal shop_closed
signal purchase_succeeded(item: Dictionary)
signal purchase_failed(item: Dictionary)
signal sale_succeeded(item: Dictionary)

var _item_catalogue: Dictionary = {}
var _shop_catalogue: Dictionary = {}
var _current_shop: Dictionary = {}
var _active: bool = false

const ITEMS_PATH = "res://data/items/items.json"
const SHOPS_PATH = "res://data/shops/shops.json"


func _ready() -> void:
	_load_into(ITEMS_PATH, _item_catalogue)
	_load_into(SHOPS_PATH, _shop_catalogue)


func _load_into(path: String, target: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("ShopManager: could not open '%s'" % path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		push_error("ShopManager: expected Array in '%s'" % path)
		return
	for entry: Dictionary in parsed:
		target[entry["id"]] = entry


func open_shop(shop_id: String) -> void:
	if not _shop_catalogue.has(shop_id):
		push_error("ShopManager: unknown shop id '%s'" % shop_id)
		return
	_current_shop = _shop_catalogue[shop_id]
	_active = true
	shop_opened.emit(_current_shop)


func close_shop() -> void:
	_active = false
	_current_shop = {}
	shop_closed.emit()


func buy_item(item_id: String) -> void:
	var item: Dictionary = _item_catalogue.get(item_id, {})
	if item.is_empty():
		return
	if not EconomyManager.spend(item["price"]):
		purchase_failed.emit(item)
		return
	InventoryManager.add_item(item_id)
	purchase_succeeded.emit(item)


func sell_item(item_id: String) -> void:
	var item: Dictionary = _item_catalogue.get(item_id, {})
	if item.is_empty() or item.get("category") == "key_item":
		return
	if not InventoryManager.remove_item(item_id):
		return
	EconomyManager.earn(item["sell_price"])
	sale_succeeded.emit(item)


func get_shop_items() -> Array:
	var result: Array = []
	for item_id: String in _current_shop.get("items", []):
		if _item_catalogue.has(item_id):
			result.append(_item_catalogue[item_id])
	return result


func get_item(item_id: String) -> Dictionary:
	return _item_catalogue.get(item_id, {})


func is_active() -> bool:
	return _active
