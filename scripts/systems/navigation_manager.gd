extends Node

const scene_test_map = preload("res://scenes/overworld/test_map.tscn")
const scene_test_map_2 = preload("res://scenes/overworld/test_map_2.tscn")
const scene_zone_1_start = preload("res://scenes/overworld/zone_1_start.tscn")
const scene_zone_2 = preload("res://scenes/overworld/zone_2.tscn")

const transition_scene = preload("res://scenes/elements/transition.tscn")

var player_scene = preload("res://scenes/entities/player/player.tscn")
var _player_instance

signal on_trigger_player_spawn

var spawn_door_tag
var _transition


func _ready() -> void:
	_player_instance = player_scene.instantiate()

	# transition overlay
	_transition = transition_scene.instantiate()
	add_child(_transition)


func go_to_level(level_tag, destination_tag):
	spawn_door_tag = destination_tag
	await _do_transition(level_tag)


func _do_transition(level_tag: String) -> void:
	# fade to black
	await _transition.fade_out()

	# remove player from current scene
	if _player_instance.get_parent():
		_player_instance.get_parent().remove_child(_player_instance)

	# change scene
	var scene_to_load = _get_scene(level_tag)
	if scene_to_load != null:
		get_tree().change_scene_to_packed(scene_to_load)

	await get_tree().process_frame
	await get_tree().process_frame


	# fade back in
	await _transition.fade_in()


func _get_scene(level_tag: String) -> PackedScene:
	match level_tag:
		"test_map": return scene_test_map
		"test_map_2": return scene_test_map_2
		"zone_1_start": return scene_zone_1_start
		"zone_2": return scene_zone_2
	return null


func trigger_player_spawn(spawn_position: Vector2, direction: String):
	# add player to new scene root after it loads
	get_tree().current_scene.add_child(_player_instance)
	on_trigger_player_spawn.emit(spawn_position, direction)
	spawn_door_tag = null
