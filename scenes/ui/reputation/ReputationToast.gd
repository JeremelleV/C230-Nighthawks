extends CanvasLayer

@onready var _container: VBoxContainer = $ToastContainer

const FADE_IN:    float = 0.15
const HOLD:       float = 2.0
const FADE_OUT:   float = 0.4

const COLOR_POSITIVE := Color(0.40, 0.90, 0.45)
const COLOR_NEGATIVE := Color(0.90, 0.35, 0.35)


func _ready() -> void:
	FactionManager.reputation_changed.connect(_on_reputation_changed)


func _on_reputation_changed(faction_id: String, delta: int, _new_value: int, new_status: String) -> void:
	var toast := _make_toast(faction_id, delta, new_status)
	_container.add_child(toast)
	_animate(toast)


func _make_toast(faction_id: String, delta: int, status: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel_style())
	panel.modulate.a = 0.0

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	var faction_label := Label.new()
	faction_label.text = FactionManager.get_faction_name(faction_id)
	faction_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	faction_label.add_theme_color_override("font_color", UIStyle.TEXT)
	faction_label.add_theme_font_size_override("font_size", 13)

	var delta_label := Label.new()
	delta_label.text = ("▲ +%d" % delta) if delta > 0 else ("▼ %d" % delta)
	delta_label.add_theme_color_override("font_color", COLOR_POSITIVE if delta > 0 else COLOR_NEGATIVE)
	delta_label.add_theme_font_size_override("font_size", 13)

	var status_label := Label.new()
	status_label.text = "(%s)" % status
	status_label.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)
	status_label.add_theme_font_size_override("font_size", 12)

	row.add_child(faction_label)
	row.add_child(delta_label)
	row.add_child(status_label)

	return panel


func _animate(toast: Control) -> void:
	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, FADE_IN)
	tween.tween_interval(HOLD)
	tween.tween_property(toast, "modulate:a", 0.0, FADE_OUT)
	tween.tween_callback(toast.queue_free)
