extends CanvasLayer
## DialogueBox — the on-screen dialogue window.
##
## Purely visual/input — never holds game state.
## Listens to DialogueManager signals and redraws itself accordingly.
##
## Node tree (must match DialogueBox.tscn exactly for @onready to work):
##   DialogueBox (CanvasLayer)
##     Panel
##       HBoxContainer
##         Portrait (TextureRect)
##         VBoxContainer
##           SpeakerLabel (Label)
##           DialogueText (RichTextLabel)
##           ChoicesContainer (VBoxContainer)
##           ContinueHint (Label)


@onready var _panel: Panel                    = $Panel
@onready var _portrait: TextureRect           = $Panel/HBoxContainer/Portrait
@onready var _speaker_label: Label            = $Panel/HBoxContainer/VBoxContainer/SpeakerLabel
@onready var _dialogue_text: RichTextLabel    = $Panel/HBoxContainer/VBoxContainer/DialogueText
@onready var _choices_container: VBoxContainer = $Panel/HBoxContainer/VBoxContainer/ChoicesContainer
@onready var _continue_hint: Label            = $Panel/HBoxContainer/VBoxContainer/ContinueHint
@onready var dialogue: AudioStreamPlayer = $dailogue
var _has_played_type_sfx := false

const PORTRAIT_DIR = "res://assets/portraits/"
const CHARS_PER_SECOND: float = 40.0

# Panel height (bottom-anchored, grows upward): compact for plain lines,
# taller when choice buttons are shown so they never run off-screen.
const COMPACT_TOP: float    = -180.0
const CHOICE_BASE_TOP: float = -150.0
const PER_CHOICE_PX: float   = 52.0

var _full_text: String = ""
var _char_index: int = 0
var _pending_choices: Array = []
var _typewriter_timer: Timer


func _ready() -> void:
	DialogueManager.dialogue_started.connect(_on_started)
	DialogueManager.dialogue_finished.connect(_on_finished)
	DialogueManager.line_displayed.connect(_on_line)
	DialogueManager.choices_presented.connect(_on_choices)

	_typewriter_timer = Timer.new()
	_typewriter_timer.wait_time = 1.0 / CHARS_PER_SECOND
	_typewriter_timer.timeout.connect(_tick_typewriter)
	add_child(_typewriter_timer)

	_apply_theme()
	hide()
	
	if dialogue.playing:
		dialogue.stop()


func _apply_theme() -> void:
	UIStyle.style_panel($Panel)
	_speaker_label.add_theme_color_override("font_color", UIStyle.TEXT_SPEAKER)
	_dialogue_text.add_theme_color_override("default_color", UIStyle.TEXT)
	_continue_hint.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not event.is_action_pressed("ui_accept"):
		return
	if not _typewriter_timer.is_stopped():
		_finish_typewriter()
	elif _pending_choices.is_empty():
		DialogueManager.advance()
	get_viewport().set_input_as_handled()


# ── Signal Handlers ───────────────────────────────────────────────────────────

func _on_started(_id: String) -> void:
	_pending_choices = []
	_choices_container.visible = false
	_continue_hint.visible = false
	_panel.offset_top = COMPACT_TOP
	show()


func _on_finished() -> void:
	hide()


func _on_line(speaker: String, text: String, portrait_name: String) -> void:
	_pending_choices = []
	_choices_container.visible = false
	_continue_hint.visible = false
	_panel.offset_top = COMPACT_TOP
	_speaker_label.text = speaker
	_load_portrait(portrait_name)
	_start_typewriter(text)


func _on_choices(choices: Array) -> void:
	_pending_choices = choices
	if _typewriter_timer.is_stopped():
		_build_choice_buttons()


# ── Typewriter ────────────────────────────────────────────────────────────────

func _start_typewriter(text: String) -> void:
	_full_text = text
	_char_index = 0
	_dialogue_text.text = ""
	_has_played_type_sfx = false
	_typewriter_timer.start()


func _tick_typewriter() -> void:
	_char_index += 1
	
	if _char_index == 1 and not _has_played_type_sfx:
		_has_played_type_sfx = true
		if dialogue:
			dialogue.play()
			
	_dialogue_text.text = _full_text.left(_char_index)	
	
	if _char_index >= _full_text.length():
		_typewriter_timer.stop()
		_on_typewriter_done()


func _finish_typewriter() -> void:
	_typewriter_timer.stop()
	_dialogue_text.text = _full_text
	_char_index = _full_text.length()
	_on_typewriter_done()


func _on_typewriter_done() -> void:

	if not _pending_choices.is_empty():
		_build_choice_buttons()
	else:
		_continue_hint.visible = true


# ── Choices ───────────────────────────────────────────────────────────────────

func _build_choice_buttons() -> void:
	for child in _choices_container.get_children():
		child.queue_free()
	for i in _pending_choices.size():
		var btn := Button.new()
		btn.text = _pending_choices[i]["label"]
		UIStyle.style_button(btn)
		var idx := i
		btn.pressed.connect(func(): DialogueManager.make_choice(idx))
		_choices_container.add_child(btn)
	_choices_container.visible = true
	# Grow the panel upward so all options fit on-screen
	_panel.offset_top = CHOICE_BASE_TOP - PER_CHOICE_PX * _pending_choices.size()


# ── Portrait ──────────────────────────────────────────────────────────────────

func _load_portrait(portrait_name: String) -> void:
	if portrait_name == "":
		_portrait.texture = null
		return
	var path := PORTRAIT_DIR + portrait_name + ".png"
	if ResourceLoader.exists(path):
		_portrait.texture = load(path)
	else:
		_portrait.texture = null
