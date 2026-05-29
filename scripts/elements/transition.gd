extends CanvasLayer

signal animation_finished

@onready var animation_player: AnimationPlayer = $ColorRect/AnimationPlayer


func fade_out() -> void:
	animation_player.play("fade_out")
	await animation_player.animation_finished


func fade_in() -> void:
	animation_player.play("fade_in")
	await animation_player.animation_finished


func _ready() -> void:
	animation_player.animation_finished.connect(func(_name): animation_finished.emit())
