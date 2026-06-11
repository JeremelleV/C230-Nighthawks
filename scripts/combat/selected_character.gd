extends Node

# This variable stores the enemy or player you clicked
var selected_character = null 

func select(character):
	selected_character = character
	print("You selected: ", selected_character.name)
