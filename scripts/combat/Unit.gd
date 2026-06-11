class_name Unit
extends RefCounted 


var name: String
var hp: int
var strength: int  
var turn_bar: float
var speed: int
var tag: String
var glabel: int
var blocking: bool
var blockturn: int

func _init(name, hp, strength, turn_bar, speed, tag, glabel, blocking, blockturn): 
	self.name = name
	self.hp = hp
	self.strength = strength
	self.turn_bar = turn_bar
	self.speed = speed
	self.tag = tag
	self.glabel = glabel
	self.blocking = blocking
	self.blocking = blockturn

func take_dmg(amount):
	self.hp -= amount
	print(name, " took damage. HP: ", hp)

func healed(amount):
	self.hp += amount
	print(name, " was healed. HP: ", hp)
