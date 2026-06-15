# combat_zone.gd
extends Area2D

@export var trigger_chance: float = 0.3
@export var step_interval: float = 1.5
@export var return_level_tag: String = ""  # set per zone in inspector

var player_inside: bool = false
var timer: float = 0.0


func _process(delta: float) -> void:
	if not player_inside:
		return
	timer += delta
	if timer >= step_interval:
		timer = 0.0
		roll_for_combat()


func roll_for_combat() -> void:
	if randf() < trigger_chance:
		trigger_battle()


func trigger_battle() -> void:	
	NavigationManager.battle_return_level = return_level_tag
	NavigationManager.battle_return_position = NavigationManager._player_instance.global_position
	NavigationManager.go_to_level("battle", null)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		timer = 0.0


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		timer = 0.0
