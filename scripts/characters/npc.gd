extends CharacterBody2D


@export var dialogue_id: String = ""
@export var has_shop: bool = false
@export var shop_id: String = ""
@export var sprite_frames: SpriteFrames
@export var idle_sequence: Array[String] = ["down"]
@export var idle_flip_interval: float = 10


var _current_idle: String = "down"
var _sequence_index: int = 0
var _idle_timer: Timer
var _player_nearby: bool = false
var _in_interaction: bool = false
var _interaction_ended_tween: SceneTreeTimer = null


func _ready() -> void:
	if sprite_frames:
		$AnimatedSprite2D.sprite_frames = sprite_frames
	DialogueManager.dialogue_finished.connect(_on_interaction_ended)
	ShopManager.shop_closed.connect(_on_interaction_ended)

	_idle_timer = Timer.new()
	add_child(_idle_timer)
	_idle_timer.wait_time = idle_flip_interval
	_idle_timer.timeout.connect(_on_idle_timer_timeout)
	_play_current_idle()
	_idle_timer.start()


func _play_current_idle() -> void:
	var anim: String = idle_sequence[_sequence_index]
	_current_idle = anim
	if anim.ends_with("left"):
		$AnimatedSprite2D.flip_h = true
		$AnimatedSprite2D.play("right")
	else:
		$AnimatedSprite2D.flip_h = false
		$AnimatedSprite2D.play(anim)


func _on_idle_timer_timeout() -> void:
	if idle_sequence.size() <= 1:
		return
	if _in_interaction:
		return
	_sequence_index = (_sequence_index + 1) % idle_sequence.size()
	_play_current_idle()


func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby:
		if event.is_action_pressed("interact"):
			_interact()


func _interact() -> void:
	_in_interaction = true
	_idle_timer.stop()
	# cancel any pending interaction ended delay
	if _interaction_ended_tween != null:
		_interaction_ended_tween = null
	
	_face_player()
	# if this npc has a shop, open it, otherwise start dialogue
	# TODO might want to change this logic if we want dialogue before shop open
	if has_shop and shop_id != "":
		ShopManager.open_shop(shop_id)
	elif dialogue_id != "":
		DialogueManager.start_dialogue(dialogue_id)


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		$InteractionPrompt.show()


func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		$InteractionPrompt.hide()


func _on_interaction_ended() -> void:
	_idle_timer.stop()
	_sequence_index = 0
	_interaction_ended_tween = get_tree().create_timer(3.0)
	await _interaction_ended_tween.timeout
	if _interaction_ended_tween == null:
		return
	_in_interaction = false
	_play_current_idle()
	_idle_timer.start()


func _face_player() -> void:
	_idle_timer.stop()
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var diff = player.global_position - global_position

	if abs(diff.x) > abs(diff.y):
		# player is mostly to the left or right
		$AnimatedSprite2D.flip_h = diff.x < 0
		$AnimatedSprite2D.play("right")
	else:
		# player is mostly above or below
		$AnimatedSprite2D.flip_h = false
		if diff.y < 0:
			$AnimatedSprite2D.play("up")
		else:
			$AnimatedSprite2D.play("down")

	$AnimatedSprite2D.stop()
