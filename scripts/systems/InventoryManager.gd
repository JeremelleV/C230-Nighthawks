extends Node

signal inventory_changed

# Dictionary: item_id (String) -> quantity (int)
var _items: Dictionary = {}


func add_item(item_id: String, quantity: int = 1) -> void:
	_items[item_id] = _items.get(item_id, 0) + quantity
	inventory_changed.emit()


func remove_item(item_id: String, quantity: int = 1) -> bool:
	var current: int = _items.get(item_id, 0)
	if current < quantity:
		return false
	_items[item_id] = current - quantity
	if _items[item_id] == 0:
		_items.erase(item_id)
	inventory_changed.emit()
	return true


func has_item(item_id: String) -> bool:
	return _items.get(item_id, 0) > 0


func get_quantity(item_id: String) -> int:
	return _items.get(item_id, 0)


func get_all_items() -> Dictionary:
	return _items.duplicate()
