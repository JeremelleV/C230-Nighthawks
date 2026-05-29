extends CharacterBody2D

enum State {
	RUN,
	UP,
	DOWN
}

@export_category("Stats")
@export var speed: int = 400

var state: State = State.DOWN
var move_direction: Vector2 = Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var animation_player: AnimationPlayer = $AnimationPlayer


# animation is always active
func _ready() -> void:
	animation_tree.set_active(true)


# called 60x per second by default
func _physics_process(delta: float) -> void:
	movement_loop()


func movement_loop() -> void:
	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))

	var motion: Vector2 = move_direction.normalized() * speed
	set_velocity(motion)
	move_and_slide()

	update_state()
	handle_flip()
	update_animation()


func update_state() -> void:
	if move_direction == Vector2.ZERO:
		# keep state direction for idle freeze
		return

	# vertical animation prioritized over horizontal animation
	# (diagonal movement)
	if abs(move_direction.y) > abs(move_direction.x):
		if move_direction.y < 0:
			state = State.UP
		else:
			state = State.DOWN
	else:
		state = State.RUN


func handle_flip() -> void:
	# currently done in RUN (left/right)
	# (horizontal movement)
	# maybe TODO: assumes sprite animation going to the RIGHT
	if move_direction.x < -0.01:
		$Sprite2D.flip_h = true
	elif move_direction.x > 0.01:
		$Sprite2D.flip_h = false


func update_animation() -> void:
	if move_direction == Vector2.ZERO:
		# freeze on frame 0 of current direction animation
		animation_tree.set_active(false)
		var anim_name: String = _get_anim_for_state()
		animation_player.play(anim_name)
		animation_player.seek(0.0, true)
		animation_player.pause()
		return

	animation_tree.set_active(true)
	animation_playback.travel(_get_anim_for_state())


func _get_anim_for_state() -> String:
	match state:
		State.UP:
			return "up"
		State.DOWN:
			return "down"
		_:
			return "run"
