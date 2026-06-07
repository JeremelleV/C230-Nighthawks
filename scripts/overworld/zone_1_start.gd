extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioPlayer.play_music_level() #testing
	if NavigationManager.spawn_door_tag != null:
		_on_level_spawn.call_deferred(NavigationManager.spawn_door_tag)
	else:
		# first load, default spawn
		var default_spawn = get_node("default_spawn")
		NavigationManager.trigger_player_spawn(default_spawn.global_position, "down")


func _on_level_spawn(destination_tag: String):
	var door_path = "doors/door_" + destination_tag
	var door = get_node(door_path) as Door
	NavigationManager.trigger_player_spawn(door.spawn.global_position, door.spawn_direction)
