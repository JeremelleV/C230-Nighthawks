class_name Unit
extends RefCounted 


var name: String
var hp: int
var strength: int  
var turn_bar: float
var spd: int
var tag: String


func _init(name, hp, strength, turn_bar, spd, tag): 
	self.name = name
	self.hp = hp
	self.strength = strength
	self.turn_bar = turn_bar
	self.spd = spd
	self.tag = tag


func take_dmg(amount):
	self.hp -= amount
	print(name, " took damage. HP: ", hp)

func healed(amount):
	self.hp += amount
	print(name, " was healed. HP: ", hp)
