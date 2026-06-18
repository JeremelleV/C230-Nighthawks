extends Node
var enabled: bool = true #testing

const footstep_volume = {
	"road": -10,
	"grass": -16,
	"stone": -15,
	"unknown":-18
}

var tilemaps:Array[TileMapLayer] = []

const footstep_sounds = {
	"road":preload("res://assets/audio/walk_on_path.wav"),
	"grass":preload("res://assets/audio/walk_on_grass.mp3"),
	"stone":preload("res://assets/audio/walk_on_stone.mp3"),
	"unknown":preload("res://assets/audio/walk_on_unknown_material.wav")
}

func play_footstep(position: Vector2):
	if not enabled:
		return
	var tile_data = []
	for tilemap in tilemaps:
		if not is_instance_valid(tilemap):
			continue
		var tile_position = tilemap.local_to_map(position)
		var data = tilemap.get_cell_tile_data(tile_position)
		if data:
			tile_data.push_back(data)
			
	if tile_data.size() > 0:
		var tile_type = tile_data.back().get_custom_data("footstep_sound")
			
		if footstep_sounds.has(tile_type):
			var audio_player = AudioStreamPlayer2D.new()
			audio_player.stream = footstep_sounds[tile_type]#audio_player.stream = footstep_sounds[tile_type].pick_random()
			if footstep_volume.has(tile_type):
				audio_player.volume_db = footstep_volume[tile_type]
			get_tree().root.add_child(audio_player)
			audio_player.global_position = position
			audio_player.play()
			await audio_player.finished
			audio_player.queue_free()
