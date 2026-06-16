extends Node


@export var player_labels: Array[Label] = []
@export var enemy_labels: Array[Label] = []
@onready var combat1 = $combat1
@onready var combat2 = $combat2
@onready var combat3 = $combat3
@onready var combatrain = $combatrain
@onready var combatplaceholder = $combatplaceholder
@export var menu_button: ColorRect
@onready var battle_background: TextureRect = $CanvasLayer/battle_background
@export var player_indicators: Array[TextureRect] = []
@export var enemy_indicators: Array[TextureRect] = []
@export var enemy_texture: Array[TextureRect] = []
@export var player_texture: Array[TextureRect] = []
@export var button_3: Button


var player_team: Array[Unit] = []
var enemy_team: Array[Unit] = []
var combined_team: Array[Unit] = []
var is_waiting_for_input: bool = false
var active_unit: Unit = null # Track whose turn it currently is
var all_players_dead = false
var all_enemies_dead = false
var active_target = null


func _process(delta: float):
	if is_waiting_for_input == true:
		return
		
	if is_waiting_for_input:
		return
		
	for unit in combined_team:
		# Double-check to ensure dead units aren't building speed
		if unit.hp <= 0:
			continue	
			
	for unit in combined_team:
		unit.turn_bar += unit.speed * delta 
		print(unit.name, "    ", unit.turn_bar)
		
		if unit.turn_bar >= 100.0:
			is_waiting_for_input = true
			unit.turn_bar -= 100.0		
			execute_turn(unit)
			return


func execute_turn(Unit):
	active_unit = Unit
	
	
	# First, hide EVERY indicator so old turns clear out cleanly
	clear_all_indicators()
	
	
	# Show the indicator for whoever is active right now using their glabel index
	if Unit.tag == "player":
		player_indicators[Unit.glabel].visible = true
		player_turn(Unit)
	else:
		enemy_indicators[Unit.glabel].visible = true
		enemy_turn(Unit)
		
		
func clear_all_indicators():
	for indicator in player_indicators:
		indicator.visible = false
	for indicator in enemy_indicators:
		indicator.visible = false


func player_turn(Unit):
	active_unit = Unit
	print("It's " + Unit.name + "'s turn!")
	is_waiting_for_input = true	
	##make combat bar interactable
	set_button_interactable(true)
	if active_unit.blocking == true:
		active_unit.blockturn -= 1
	
	
func enemy_turn(Unit):
	is_waiting_for_input = true
	set_button_interactable(false)
	await get_tree().create_timer(1.5).timeout
	var who_do_i_target = randi_range(0, 4)
	if who_do_i_target == 4:
		Unit.healed(20)
		enemy_labels[Unit.glabel].text = Unit.name + " HP: " + str(Unit.hp)
		
	
		
	else:
		if who_do_i_target in [0, 1, 2, 3]:
			while player_team[who_do_i_target].hp <= 0:
				who_do_i_target = randi_range(0, 3)
		var attack_player = player_team[who_do_i_target]
		if player_team[who_do_i_target].blocking == true:
			
				
			attack_player.take_dmg(Unit.strength / 2)
			player_labels[who_do_i_target].text = attack_player.name + " HP: " + str(attack_player.hp)
			if player_team[who_do_i_target].hp <= 0:
				attack_player.turn_bar -= 10000000000000
				player_labels[who_do_i_target].visible = false
				player_texture[who_do_i_target].visible = false
		else:
			attack_player.take_dmg(Unit.strength)
			player_labels[who_do_i_target].text = attack_player.name + " HP: " + str(attack_player.hp)	
			if attack_player.hp <= 0:
				attack_player.turn_bar -= 10000000000000
				player_labels[who_do_i_target].visible = false
				player_texture[who_do_i_target].visible = false
	check_battle_status()
	clear_all_indicators()
	active_unit = null
	is_waiting_for_input = false		
			
			
			
func update_label():
	for i in player_team:
		player_labels[i.glabel].text = i.name + " HP: " + str(i.hp)
	
	for i in enemy_team:
		enemy_labels[i.glabel].text = i.name + " HP: " + str(i.hp)
	
	
	
func check_battle_status():
	# 1. Check if all players are dead
	var all_players_dead = true
	for player in player_team:
		if player.hp > 0:
			all_players_dead = false
			break # Found a living hero, stop checking players
			
	# 2. Check if all enemies are dead
	var all_enemies_dead = true
	for enemy in enemy_team:
		if enemy.hp > 0:
			all_enemies_dead = false
			break # Found a living enemy, stop checking enemies

	# 3. Handle results
	if all_players_dead == true:
		print("DEFEAT! All your party members have fallen.")
		end_battle(false)
	elif all_enemies_dead == true:
		print("VICTORY! All enemies have been defeated.")
		end_battle(true)
		
		

func end_battle(player_won: bool):
	# Freeze the timeline completely
	is_waiting_for_input = true 
	set_process(false) 
	
	#test
	combat1.stop()
	combat2.stop()
	combat3.stop()
	combatrain.stop()
	combatplaceholder.stop()
	
	#test
	AudioPlayer.play_music_level()

	if player_won == true:
		QuestManager.notify_enemies_defeated(enemy_team.size())
		EconomyManager.earn(50)

	await get_tree().create_timer(0.1).timeout

	NavigationManager.saved_player_position = NavigationManager.battle_return_position
	NavigationManager.go_to_level(NavigationManager.battle_return_level, null)


func set_button_interactable(is_player_turn: bool):
	# 🛡️ Safety check: If the button isn't linked yet, skip to prevent a crash
	if menu_button == null: 
		return
		
	if active_unit in player_team:
		# 🔓 SHOW EVERYTHING
		menu_button.visible = true
		menu_button.mouse_filter = Control.MOUSE_FILTER_STOP 
		menu_button.propagate_call("set_visible", [true])
		menu_button.propagate_call("set_mouse_filter", [Control.MOUSE_FILTER_STOP])
	else:
		# 🔒 HIDE EVERYTHING
		menu_button.visible = false
		menu_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu_button.propagate_call("set_visible", [false])
		menu_button.propagate_call("set_mouse_filter", [Control.MOUSE_FILTER_IGNORE])
	
func generate_background():	
	var generate_background_num = randi_range(0, 1)	
	if generate_background_num == 0:
		battle_background.texture = preload("res://assets/backgrounds/combat_background_jungle.png")
	if generate_background_num == 1:
		battle_background.texture = preload("res://assets/backgrounds/combat_background_som.png")
	


func _ready():
	AudioPlayer.stop_music() #test
	generate_background()
	generate_enemies()
	var p1 = Unit.new("Lissandra", 100, 14, 0, 5, "player", 0, false, 0)
	var p2 = Unit.new("Chris", 50, 15, 0, 10, "player", 1, false, 0)
	var p3 = Unit.new("Mike", 100, 16, 0, 20, "player", 2, false, 0)
	var p4 = Unit.new("Truck", 100, 17, 0, 20, "player", 3, false, 0)
		
	var e1 = Unit.new("Goblin A", 40, 50, 0, 10, "enemy", 0, false, 0)
	var e2 = Unit.new("Goblin B", 100, 300, 0, 50, "enemy", 1, false, 0)
	var e3 = Unit.new("Goblin C", 250, 65, 0, 2, "enemy", 2, false, 0)
	var e4 = Unit.new("Goblin D", 250, 65, 10, 2, "enemy", 3, false, 0)
	
	#(name, hp, strength, turn_bar, speed, tag, glabel, blocking, blockturn):
	
	player_team = [p1, p2, p3, p4]
	enemy_team = [e1, e2, e3, e4]
	combined_team = [p1, p2, p3, p4, e1, e2, e3, e4]
	
	# 🔗 CONNECT THE ALARMS: Tell each track to run "on_song_finished" when they end
	combat1.finished.connect(on_song_finished)
	combat2.finished.connect(on_song_finished)
	combat3.finished.connect(on_song_finished)
	combatrain.finished.connect(on_song_finished)
	combatplaceholder.finished.connect(on_song_finished)
	
	# Start the very first random song!
	play_random_battle_music()


# 🎲 Your existing random music function




	
	print("--- SUCCESS! ---")
	print("BattleSystem has successfully spawned ", combined_team.size(), " combatants!")
	update_label()
	
func generate_enemies():
	for i in enemy_texture:
		var generate_enemies = randi_range(0, 3)
		if generate_enemies == 0:
			i.texture = preload("res://assets/sprites/enemies/jungle_creature_1.png")
		if generate_enemies == 1:
			i.texture = preload("res://assets/sprites/enemies/jungle_creature_floater.png")
		if generate_enemies == 2:
			i.texture = preload("res://assets/sprites/enemies/som_basic.png")
		if generate_enemies == 3:
			i.texture = preload("res://assets/sprites/enemies/som_beast.png")


func play_random_battle_music():
	combat1.stop()
	combat2.stop()
	combat3.stop()
	combatrain.stop()
	combatplaceholder.stop()

	#change sound volume
	var music = randi_range(0, 4)
	if music == 0: 
		combat1.volume_db = -20
		combat1.play()
	elif music == 1: 
		combat2.volume_db = -20
		combat2.play()
	elif music == 2: 
		combat3.volume_db = -20
		combat3.play()
	elif music == 3: 
		combatrain.volume_db = -20
		combatrain.play()
	elif music == 4: 
		combatplaceholder.volume_db = -20
		combatplaceholder.play()


# 🔄 THE AUTOMATIC TRIGGER: This runs the exact second ANY playing track finishes!
func on_song_finished():
	print("Song ended! Rolling a new random track...")
	play_random_battle_music()		




func _on_button_pressed() -> void:
	
	if active_unit == null or active_unit in enemy_team:
		print("Cannot attack! No character has taken their turn yet because the speed loop hasn't started.")
		return
	if active_target == null:
		print("Please select a target first by clicking an enemy!")
		return	
	var attacker = active_unit #actually add the logic for the speed system tomorror
	var target = active_target
	target.take_dmg(attacker.strength)
	update_label()
	check_battle_status()
	print(attacker.name + " attacks " + target.name + "!")
	
	print(attacker.name + " does  " + str(attacker.strength) + " damage!")
	if active_target.hp <= 0:
		active_target.turn_bar -= 10000000000000
		if target.tag == "enemy":
			enemy_texture[target.glabel].visible = false
			enemy_labels[target.glabel].visible = false
			print(target.name, " has been defeated and hidden!")
		
	if is_inside_tree():
		if is_waiting_for_input == true: # If check_battle_status didn't freeze the game
			clear_all_indicators()
			active_unit = null
			is_waiting_for_input = false
	set_button_interactable(false)


func _on_button_3_pressed() -> void:
	if active_unit == null or active_unit in enemy_team:
		print("not allowed")
		return
	active_unit.blocking = true
	active_unit.blockturn += 3
	print("Blocking")


func _on_e_1_hitbox_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		active_target = enemy_team[0]
		print("selected enemy 1")


func _on_e_1_hitbox_2_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		active_target = enemy_team[1]
		print("selected enemy 2")

func _on_e_1_hitbox_3_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		active_target = enemy_team[2]
		print("selected enemy 3")


func _on_e_1_hitbox_4_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		active_target = enemy_team[3]
		print("selected enemy 4")
