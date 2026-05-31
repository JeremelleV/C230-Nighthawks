extends Area2D

@onready var door_sound: AudioStreamPlayer = $AudioStreamPlayer

func interact():
	door_sound.play()
