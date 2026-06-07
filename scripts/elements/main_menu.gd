extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_start_pressed() -> void:
	NavigationManager.go_to_level("zone_1_start", null)

func _on_button_settings_pressed() -> void:
	pass # Replace with function body.


func _on_button_quit_pressed() -> void:
	get_tree().quit()
