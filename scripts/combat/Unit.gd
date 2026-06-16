class_name Unit
extends RefCounted


var name: String
var hp: int
var max_hp: int
var mp: int = 0
var max_mp: int = 0
var strength: int
var turn_bar: float
var speed: int
var tag: String
var glabel: int
var blocking: bool
var blockturn: int


func _init(p_name, p_hp, p_strength, p_turn_bar, p_speed, p_tag, p_glabel, p_blocking, p_blockturn):
	name      = p_name
	hp        = p_hp
	max_hp    = p_hp
	strength  = p_strength
	turn_bar  = p_turn_bar
	speed     = p_speed
	tag       = p_tag
	glabel    = p_glabel
	blocking  = p_blocking
	blockturn = p_blockturn


func take_dmg(amount: int) -> void:
	hp = max(0, hp - amount)


func healed(amount: int) -> void:
	hp = min(max_hp, hp + amount)
