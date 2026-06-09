extends Node2D
## TestScene — temporary scene for testing systems before the overworld is built.
## Delete this once Jeremelle's overworld is in place.
##
## Controls:
##   T           → start the test NPC dialogue
##   Space/Enter → advance dialogue or skip typewriter
##   B           → open the test shop
##   Esc         → close the shop


func _ready() -> void:
	print("=== Red Dominion — System Test ===")
	print("T = dialogue | B = shop")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			if not DialogueManager.is_active():
				DialogueManager.start_dialogue("test_npc_intro")
		elif event.keycode == KEY_B:
			if not ShopManager.is_active():
				ShopManager.open_shop("dustplains_trader")
