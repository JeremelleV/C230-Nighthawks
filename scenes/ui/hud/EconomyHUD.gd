extends CanvasLayer

@onready var _balance_label: Label = $Panel/MarginContainer/Row/BalanceLabel


func _ready() -> void:
	_apply_theme()
	EconomyManager.balance_changed.connect(_on_balance_changed)
	_balance_label.text = "$MRS %d" % EconomyManager.get_balance()


func _apply_theme() -> void:
	var style := UIStyle.panel_style()
	$Panel.add_theme_stylebox_override("panel", style)
	_balance_label.add_theme_color_override("font_color", UIStyle.TEXT_CURRENCY)
	_balance_label.add_theme_font_size_override("font_size", 15)
	$Panel/MarginContainer/Row/IconLabel.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)
	$Panel/MarginContainer/Row/IconLabel.add_theme_font_size_override("font_size", 13)


func _on_balance_changed(new_balance: int) -> void:
	_balance_label.text = "$MRS %d" % new_balance
