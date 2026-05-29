extends CharacterBody2D

class_name Player

enum State {
	RUN,
	UP,
	DOWN
}

@export_category("Stats")
@export var speed: int = 400

var is_first_spawn: bool = true
var state: State = State.DOWN
var move_direction: Vector2 = Vector2.ZERO
var spawn_walk_timer: float = 0.0
const SPAWN_WALK_DURATION: float = 0.3

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var animation_player: AnimationPlayer = $AnimationPlayer


# animation always starts off
func _ready() -> void:
	animation_tree.set_active(false)
	NavigationManager.on_trigger_player_spawn.connect(_on_spawn)


func _on_spawn(position: Vector2, direction: String):
	global_position = position

	# set state and flip based on incoming direction
	match direction:
		"up":
			state = State.UP
			move_direction = Vector2.UP
		"down":
			state = State.DOWN
			move_direction = Vector2.DOWN
		"left":
			state = State.RUN
			$Sprite2D.flip_h = true
			move_direction = Vector2.LEFT
		"right":
			state = State.RUN
			$Sprite2D.flip_h = false
			move_direction = Vector2.RIGHT

	if is_first_spawn:
		is_first_spawn = false
		move_direction = Vector2.ZERO
		update_animation()
		return

	# short walk-in on spawn
	spawn_walk_timer = SPAWN_WALK_DURATION
	animation_tree.set_active(true)
	animation_playback.travel(_get_anim_for_state())


# called 60x per second by default
func _physics_process(delta: float) -> void:
	if spawn_walk_timer > 0.0:
		spawn_walk_timer -= delta
		var motion: Vector2 = move_direction.normalized() * speed
		set_velocity(motion)
		move_and_slide()
		if spawn_walk_timer <= 0.0:
			# walk-in done, freeze
			move_direction = Vector2.ZERO
			set_velocity(Vector2.ZERO)
			update_animation()
		return

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
