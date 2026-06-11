extends CanvasLayer


@export var pause_menu: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _input(event: InputEvent) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		_go_back()


func _go_back() -> void:
	visible = false
	if pause_menu:
		get_tree().paused = true
		pause_menu.call_deferred("set", "visible", true)
	


func _on_back_button_pressed() -> void:
	_go_back()

#test
#func _on_volume_slider_value_changed(value: float) -> void:
	# Volume
	#pass # Replace with function body.
