extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	get_tree().paused = false


func _input(event: InputEvent) -> void:
	if not NavigationManager.in_game:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		if get_tree().paused:
			visible = false
			get_tree().paused = false
		else:
			visible = true
			get_tree().paused = true


func _on_button_resume_pressed() -> void:
	visible = false
	get_tree().paused = false


func _on_button_settings_pressed() -> void:
	pass # Replace with function body.


func _on_button_main_menu_pressed() -> void:
	NavigationManager.go_to_main_menu()
	visible = false
	get_tree().paused = false
