extends Node2D
## TestScene — temporary scene for testing dialogue before the overworld is built.
## Delete this once Jeremelle's overworld is in place.
##
## Controls:
##   T           → start the test NPC dialogue
##   Space/Enter → advance dialogue or skip typewriter


func _ready() -> void:
	print("=== Red Dominion — Dialogue Test ===")
	print("Press T to start a test dialogue.")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			if not DialogueManager.is_active():
				DialogueManager.start_dialogue("test_npc_intro")
