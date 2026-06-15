extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NavigationManager.previous_level_tag = "zone_2"
	if NavigationManager.saved_player_position != Vector2.ZERO:
		# Returning from battle, restore exact position
		NavigationManager.trigger_player_spawn(NavigationManager.saved_player_position, "down")
		NavigationManager.saved_player_position = Vector2.ZERO  # clear it
	elif NavigationManager.spawn_door_tag != null:
		_on_level_spawn.call_deferred(NavigationManager.spawn_door_tag)
	else:
		var default_spawn = get_node("default_spawn")
		NavigationManager.trigger_player_spawn(default_spawn.global_position, "down")

	_setup_minimap.call_deferred()


func _on_level_spawn(destination_tag: String):
	var door_path = "doors/door_" + destination_tag
	var door = get_node(door_path) as Door
	NavigationManager.trigger_player_spawn(door.spawn.global_position, door.spawn_direction)


func _setup_minimap() -> void:
	var minimap = get_node("minimap")
	minimap.set_follow_target(NavigationManager._player_instance)
