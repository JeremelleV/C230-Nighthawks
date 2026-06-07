class_name UIStyle

# Declan's colour palette — update here when the palette changes.

const PANEL_BG      := Color(0.13, 0.10, 0.09, 0.96)   # dark warm gray
const PANEL_BORDER  := Color(0.49, 0.13, 0.13, 1.00)   # deep red

const BTN_NORMAL    := Color(0.49, 0.13, 0.13, 1.00)   # deep red
const BTN_HOVER     := Color(0.62, 0.18, 0.18, 1.00)   # lighter red
const BTN_PRESSED   := Color(0.36, 0.09, 0.09, 1.00)   # darker red
const BTN_DISABLED  := Color(0.28, 0.20, 0.20, 1.00)   # muted red-gray

const TEXT          := Color(0.94, 0.91, 0.88, 1.00)   # warm off-white
const TEXT_MUTED    := Color(0.66, 0.56, 0.50, 1.00)   # warm gray
const TEXT_SPEAKER  := Color(0.85, 0.55, 0.55, 1.00)   # rose (speaker names)
const TEXT_CURRENCY := Color(0.95, 0.82, 0.38, 1.00)   # gold ($MRS)
const TEXT_ERROR    := Color(0.90, 0.35, 0.35, 1.00)   # error red


static func panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = PANEL_BG
	s.border_color = PANEL_BORDER
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	return s


static func _button_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = bg.lightened(0.15)
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s


static func style_panel(panel: Panel) -> void:
	panel.add_theme_stylebox_override("panel", panel_style())


static func style_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal",   _button_style(BTN_NORMAL))
	btn.add_theme_stylebox_override("hover",    _button_style(BTN_HOVER))
	btn.add_theme_stylebox_override("pressed",  _button_style(BTN_PRESSED))
	btn.add_theme_stylebox_override("disabled", _button_style(BTN_DISABLED))
	btn.add_theme_color_override("font_color",          TEXT)
	btn.add_theme_color_override("font_hover_color",    TEXT)
	btn.add_theme_color_override("font_pressed_color",  TEXT)
	btn.add_theme_color_override("font_disabled_color", TEXT_MUTED)
