extends Camera2D

var follow_target: Node2D

func set_follow_target(target: Node2D) -> void:
	follow_target = target

func _process(_delta: float) -> void:
	if follow_target and is_instance_valid(follow_target):
		global_position = follow_target.global_position
