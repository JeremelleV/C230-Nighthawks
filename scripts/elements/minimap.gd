extends Node2D

@onready var viewport = $minimap_viewport
@onready var camera = $minimap_viewport/minimap_camera
@onready var display = $CanvasLayer/Panel/minimap_display

@export var zoom_level: float = 0.1

func _ready() -> void:
	viewport.world_2d = get_tree().root.world_2d
	display.texture = viewport.get_texture()
	camera.zoom = Vector2(zoom_level, zoom_level)

func set_follow_target(target: Node2D) -> void:
	camera.set_follow_target(target)

func _process(_delta: float) -> void:
	pass
