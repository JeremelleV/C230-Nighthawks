extends Node

@onready var player = $AudioStreamPlayer

var overworld_music = preload("res://assets/audio/space_explore.mp3")
var combat_music = preload("res://assets/audio/combat.mp3")

func play_overworld():
	player.stream = overworld_music
	player.play()

func play_combat():
	player.stream = combat_music
	player.play()
