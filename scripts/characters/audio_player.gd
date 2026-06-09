extends AudioStreamPlayer


const level_music = preload("res://assets/audio/space_explore.mp3")

func _play_music(music: AudioStream, volume = -30.0):
	if stream == music and playing: #testing
		return
	stream = music
	volume_db = volume
	if not playing: #testing
		play()

func play_music_level():
	_play_music(level_music)
	
func stop_music():
	stop()
	stream = null #testing
