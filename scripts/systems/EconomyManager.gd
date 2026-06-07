extends Node

signal balance_changed(new_balance: int)

const STARTING_BALANCE: int = 200

var _balance: int = STARTING_BALANCE


func get_balance() -> int:
	return _balance


func earn(amount: int) -> void:
	_balance += amount
	balance_changed.emit(_balance)


func spend(amount: int) -> bool:
	if _balance < amount:
		return false
	_balance -= amount
	balance_changed.emit(_balance)
	return true


func can_afford(amount: int) -> bool:
	return _balance >= amount
