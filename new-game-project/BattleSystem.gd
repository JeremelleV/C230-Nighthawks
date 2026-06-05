


extends Node

@export var player_labels: Array[Label] = []
@export var enemy_labels: Array[Label] = []


var player_team: Array[Unit] = []
var enemy_team: Array[Unit] = []
var combined_team: Array[Unit] = []


func _ready():
	
	var p1 = Unit.new("Lissandra", 100, 5, 0, 5, "player")
	var p2 = Unit.new("Chris", 50, 5, 0, 10, "player")
	var p3 = Unit.new("Mike", 100, 10, 0, 20, "player")
		
	var e1 = Unit.new("Goblin A", 40, 50, 0, 10, "enemy")
	var e2 = Unit.new("Goblin B", 100, 10, 0, 50, "enemy")
	var e3 = Unit.new("Boss Orc", 250, 50, 0, 2, "enemy")


	player_team = [p1, p2, p3]
	enemy_team = [e1, e2, e3]
	combined_team = [p1, p2, p3, e1, e2, e3]
	
	print("--- SUCCESS! ---")
	print("BattleSystem has successfully spawned ", combined_team.size(), " combatants!")


func _on_button_pressed() -> void:
	
	var attacker = player_team[0] #actually add the logic for the speed system tomorror
	var target = enemy_team[0]
	
	
	print(attacker.name + " attacks " + target.name + "!")
	
	
	target.take_dmg(attacker.strength)
	
	
	enemy_labels[0].text = target.name + " HP: " + str(target.hp)
