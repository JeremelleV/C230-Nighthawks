extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioPlayer.stop_music() #testing
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_button_start_mouse_entered() -> void:
	$button_hover.play()

func _on_button_start_pressed() -> void:
	$button_click.play()
	NavigationManager.go_to_level("zone_1_start", null)

func _on_button_settings_mouse_entered() -> void:
	$button_hover.play()
	
func _on_button_settings_pressed() -> void:
	$button_click.play()
	pass # Replace with function body.

func _on_button_quit_mouse_entered() -> void:
	$button_hover.play()
	
func _on_button_quit_pressed() -> void:
	$button_click.play()
	get_tree().quit()
