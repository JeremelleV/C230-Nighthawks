extends Node2D

#test
const SFX_ATTACK := "res://assets/audio/fist_attack.mp3"
const SFX_SPECIAL := "res://assets/audio/explode.mp3"
const SFX_HEAL := "res://assets/audio/heal.wav"
const SFX_BLOCK := "res://assets/audio/block.mp3"

# ─── Design reference (original art was made for this resolution) ─────────────
const REF_W := 1920.0
const REF_H := 1080.0

# Normalised positions (0‒1) derived from the original design.
# Multiply by actual viewport size at runtime to get screen coords.
const PLAYER_POS_N: Array = [
	Vector2(0.1875, 0.7870),  # P1 Athena   — front-left
	Vector2(0.3177, 0.6667),  # P2 Zeus     — back-right
	Vector2(0.0938, 0.6574),  # P3 Hermes   — back-left
	Vector2(0.2917, 0.8241),  # P4 Poseidon — front-right
]
const ENEMY_POS_N: Array = [
	Vector2(0.5990, 0.7870),  # E1 Crawler  — front-left
	Vector2(0.7135, 0.6296),  # E2 Floater  — back-center
	Vector2(0.8490, 0.6759),  # E3 Brute    — back-right
	Vector2(0.7292, 0.8241),  # E4 Stalker  — front-right
]

# Sprite sizes as fraction of screen height (preserves feel at any resolution)
const PLAYER_SPRITE_H_N := 0.4197   # was 0.6296, reduced by a third
const PLAYER_SPRITE_W_N := 0.1875   # was 0.2813, reduced by a third
const ENEMY_SPRITE_H_N  := 0.4352   # 470/1080
const ENEMY_SPRITE_W_N  := 0.2448   # 470/1920

# UI scale fractions (relative to ref)
const PORTRAIT_N   := 0.0741   # 80/1080
const HP_BAR_W_N   := 0.1250   # 240/1920
const HP_BAR_H_N   := 0.0167   # 18/1080

# Action panel fractions
const PANEL_W_N    := 0.2000   # 384/1920
const PANEL_H_N    := 0.1593   # 172/1080
const PANEL_PAD_R  := 0.0104   # gap from right edge
const PANEL_PAD_B  := 0.0093   # gap from bottom edge  (was 192/1080 ≈ 0.178 from top → flip)

# ─── Runtime layout (populated in _ready from actual viewport) ────────────────
var SW := 1366.0   # actual screen width
var SH := 768.0    # actual screen height

# Resolved world-space positions and sizes
var player_pos:        Array = []
var enemy_pos:         Array = []
var player_sprite_size: Vector2
var enemy_sprite_size:  Vector2
var portrait_px:       float
var hp_bar_w:          float
var hp_bar_h:          float

# ─── Colour palette ───────────────────────────────────────────────────────────
const C_BORDER     := Color(0.49, 0.13, 0.13, 1.00)
const C_PANEL_BG   := Color(0.10, 0.08, 0.08, 0.93)
const C_HP_FILL    := Color(0.18, 0.72, 0.22, 1.00)
const C_HP_BG      := Color(0.16, 0.16, 0.16, 1.00)
const C_MP_FILL    := Color(0.26, 0.52, 0.96, 1.00)
const C_TEXT       := Color(0.94, 0.91, 0.88, 1.00)
const C_MUTED      := Color(0.66, 0.56, 0.50, 1.00)
const C_GOLD       := Color(0.95, 0.82, 0.38, 1.00)
const C_DMG_WHITE  := Color(1.00, 1.00, 1.00, 1.00)
const C_DMG_RED    := Color(1.00, 0.25, 0.15, 1.00)
const C_HEAL_GREEN := Color(0.18, 0.90, 0.30, 1.00)
const C_GLOW_TURN  := Color(1.00, 0.90, 0.20, 0.42)

# MP costs
const MAX_MP          := 30
const SPECIAL_MP_COST := 12
const HEAL_MP_COST    := 8

# Asset paths
const PLAYER_TEXTURES = [
	#"res://assets/sprites/characters/Mars_Athena.png",
	#"res://assets/sprites/characters/Mars_Zeus.png",
	#"res://assets/sprites/characters/Mars_Hermes.png",
	#"res://assets/sprites/characters/Mars_Poseidon.png",
	"res://assets/sprites/characters/alien_partymember_1.png",
	"res://assets/sprites/characters/astronaut_1_player.png",
	"res://assets/sprites/characters/astronaut_2_partymember.png",
	"res://assets/sprites/characters/astronaut_3_partymember.png"
]
const ENEMY_TEXTURES = [
	#"res://assets/sprites/enemies/Mars_crawler.png",
	#"res://assets/sprites/enemies/Mars_floater.png",
	#"res://assets/sprites/enemies/Mars_Brute.png",
	#"res://assets/sprites/enemies/Mars_stalker.png",
	"res://assets/sprites/enemies/jungle_creature_1.png",
	"res://assets/sprites/enemies/jungle_creature_floater.png",
	"res://assets/sprites/enemies/som_basic.png",
	"res://assets/sprites/enemies/som_beast.png"
]
const BG_TEXTURES = [
	#"res://assets/backgrounds/combat_background_outdoors.png",
	"res://assets/backgrounds/combat_background_som.png",
	"res://assets/backgrounds/combat_background_jungle.png"
]
const FX_MELEE_SHEET := "res://assets/sprites/effects/Mars_Animation_MeleeSlash.png"
const FX_PULSE_SHEET := "res://assets/sprites/effects/Mars_Animation_Pulse.png"
const FX_ENEMY_SHEET := "res://assets/sprites/effects/Mars_Animation_EnemyAttack.png"
const FX_HEAL_SHEET  := "res://assets/sprites/effects/Mars_Animation_Healing.png"

# ─── Combat state ─────────────────────────────────────────────────────────────
var player_team:   Array[Unit] = []
var enemy_team:    Array[Unit] = []
var combined_team: Array[Unit] = []
var is_waiting_for_input := false
var active_unit:   Unit = null
var active_target: Unit = null

# ─── UI nodes ─────────────────────────────────────────────────────────────────
var _hud: CanvasLayer
var _player_hp_bars:    Array[ProgressBar] = []
var _player_mp_bars:    Array[ProgressBar] = []
var _player_turn_glows: Array[ColorRect]   = []
var _player_sprites:    Array[TextureRect] = []
var _enemy_sprites:     Array[TextureRect] = []
var _action_panel: Panel
var _action_buttons: Array[Button] = []
var _status_label: Label

var _active_arrow: Polygon2D
var _target_arrow: Polygon2D
var _active_arrow_base_y := 0.0
var _target_arrow_base_y := 0.0
var _ind_time := 0.0

#───audio──────────────────────────────────────────────────────────────────────
var _sfx_player: AudioStreamPlayer #test

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	#test
	_sfx_player = AudioStreamPlayer.new()
	add_child(_sfx_player)
	
	# Resolve actual viewport size first — everything else derives from this
	var vp := get_viewport_rect().size
	SW = vp.x
	SH = vp.y
	_resolve_layout()

	_init_units()
	_build_background()
	_build_enemy_sprites()
	_build_player_sprites()
	_build_hud()
	_build_action_menu()
	_build_indicators()
	_start_music()
	_refresh_hud()
	print("BattleSystem ready — %d combatants  (%dx%d)" % [combined_team.size(), int(SW), int(SH)])


# Compute all pixel values from the normalised fractions and actual viewport size
func _resolve_layout() -> void:
	player_sprite_size = Vector2(SW * PLAYER_SPRITE_W_N, SH * PLAYER_SPRITE_H_N)
	enemy_sprite_size  = Vector2(SW * ENEMY_SPRITE_W_N,  SH * ENEMY_SPRITE_H_N)
	portrait_px        = SH * PORTRAIT_N
	hp_bar_w           = SW * HP_BAR_W_N
	hp_bar_h           = SH * HP_BAR_H_N

	player_pos.clear()
	for n in PLAYER_POS_N:
		player_pos.append(Vector2(SW * n.x, SH * n.y))

	enemy_pos.clear()
	for n in ENEMY_POS_N:
		enemy_pos.append(Vector2(SW * n.x, SH * n.y))


# ─── Unit initialisation ──────────────────────────────────────────────────────
func _init_units() -> void:
	var p1 := Unit.new("Truck",   100, 14, 50,  5, "player", 0, false, 0)
	var p2 := Unit.new("Mike",      80, 12, 50, 12, "player", 1, false, 0)
	var p3 := Unit.new("Lissandra",   120, 18, 50,  8, "player", 2, false, 0)
	var p4 := Unit.new("Chris",  90, 15, 50, 10, "player", 3, false, 0)
	var e1 := Unit.new("Crawler",   50,  8, 0, 10, "enemy", 0, false, 0)
	var e2 := Unit.new("Floater",   60, 12, 0, 15, "enemy", 1, false, 0)
	var e3 := Unit.new("Brute",    120, 20, 0,  4, "enemy", 2, false, 0)
	var e4 := Unit.new("Stalker",   80, 14, 0,  9, "enemy", 3, false, 0)
	for p in [p1, p2, p3, p4]:
		p.max_mp = MAX_MP; p.mp = MAX_MP
	player_team   = [p1, p2, p3, p4]
	enemy_team    = [e1, e2, e3, e4]
	combined_team = [p1, p2, p3, p4, e1, e2, e3, e4]


# ─── Background — always fills the actual viewport ────────────────────────────
func _build_background() -> void:
	var bg := TextureRect.new()
	bg.texture = load(BG_TEXTURES[randi() % BG_TEXTURES.size()])
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = Vector2(SW, SH)
	bg.position = Vector2.ZERO
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


# ─── Enemy sprites ────────────────────────────────────────────────────────────
func _build_enemy_sprites() -> void:
	for i in 4:
		var sprite := TextureRect.new()
		sprite.texture = load(ENEMY_TEXTURES[i])
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.size = enemy_sprite_size
		sprite.position = enemy_pos[i] - enemy_sprite_size * 0.5
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sprite)
		_enemy_sprites.append(sprite)


# ─── Player sprites ───────────────────────────────────────────────────────────
func _build_player_sprites() -> void:
	for i in 4:
		var sprite := TextureRect.new()
		sprite.texture = load(PLAYER_TEXTURES[i])
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.size = player_sprite_size
		sprite.position = player_pos[i] - player_sprite_size * 0.5
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sprite)
		_player_sprites.append(sprite)


# ─── HUD ──────────────────────────────────────────────────────────────────────
func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 10
	add_child(_hud)

	var hbox := HBoxContainer.new()
	hbox.position = Vector2(12, 8)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", int(SW * 0.008))
	_hud.add_child(hbox)
	for i in 4:
		hbox.add_child(_make_player_card(i))

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_color_override("font_color", C_GOLD)
	_status_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_status_label.add_theme_constant_override("outline_size", 6)
	_status_label.add_theme_font_size_override("font_size", int(SH * 0.022))
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_label.size = Vector2(SW, SH * 0.037)
	_status_label.position = Vector2(0, portrait_px * 1.45)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_child(_status_label)


func _make_player_card(i: int) -> Control:
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate_style := StyleBoxFlat.new()
	plate_style.bg_color = Color(0.05, 0.04, 0.04, 0.55)
	plate_style.set_corner_radius_all(6)
	plate_style.content_margin_left   = 6
	plate_style.content_margin_right  = 7
	plate_style.content_margin_top    = 4
	plate_style.content_margin_bottom = 4
	plate.add_theme_stylebox_override("panel", plate_style)

	var card := HBoxContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_constant_override("separation", 7)

	var frame := Panel.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.08, 0.07, 0.07, 1.0)
	frame_style.border_color = C_BORDER
	frame_style.set_border_width_all(2)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.custom_minimum_size = Vector2(portrait_px + 4, portrait_px + 4)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var portrait := TextureRect.new()
	portrait.texture = load(PLAYER_TEXTURES[i])
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(portrait)

	var glow := ColorRect.new()
	glow.color = C_GLOW_TURN
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.visible = false
	frame.add_child(glow)
	_player_turn_glows.append(glow)
	card.add_child(frame)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(hp_bar_w, 0)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)

	var name_lbl := Label.new()
	name_lbl.text = player_team[i].name
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	name_lbl.add_theme_constant_override("outline_size", 4)
	name_lbl.add_theme_font_size_override("font_size", int(SH * 0.016))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	# HP row
	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_theme_constant_override("separation", 4)
	var hp_tag := Label.new()
	hp_tag.text = "HP"
	hp_tag.add_theme_color_override("font_color", C_MUTED)
	hp_tag.add_theme_font_size_override("font_size", int(SH * 0.013))
	hp_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_child(hp_tag)
	var hp_bar := ProgressBar.new()
	hp_bar.max_value = player_team[i].max_hp
	hp_bar.value     = player_team[i].hp
	hp_bar.custom_minimum_size = Vector2(hp_bar_w - 24, hp_bar_h)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.show_percentage = false
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill_s := StyleBoxFlat.new(); fill_s.bg_color = C_HP_FILL; fill_s.set_corner_radius_all(3)
	hp_bar.add_theme_stylebox_override("fill", fill_s)
	var bg_s := StyleBoxFlat.new(); bg_s.bg_color = C_HP_BG; bg_s.set_corner_radius_all(3)
	hp_bar.add_theme_stylebox_override("background", bg_s)
	hp_row.add_child(hp_bar)
	_player_hp_bars.append(hp_bar)
	vbox.add_child(hp_row)

	# MP row
	var mp_row := HBoxContainer.new()
	mp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp_row.add_theme_constant_override("separation", 4)
	var mp_tag := Label.new()
	mp_tag.text = "MP"
	mp_tag.add_theme_color_override("font_color", C_MUTED)
	mp_tag.add_theme_font_size_override("font_size", int(SH * 0.013))
	mp_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp_row.add_child(mp_tag)
	var mp_bar := ProgressBar.new()
	mp_bar.max_value = player_team[i].max_mp
	mp_bar.value     = player_team[i].mp
	mp_bar.custom_minimum_size = Vector2(hp_bar_w - 24, hp_bar_h)
	mp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mp_bar.show_percentage = false
	mp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mp_fill_s := StyleBoxFlat.new(); mp_fill_s.bg_color = C_MP_FILL; mp_fill_s.set_corner_radius_all(3)
	mp_bar.add_theme_stylebox_override("fill", mp_fill_s)
	var mp_bg_s := StyleBoxFlat.new(); mp_bg_s.bg_color = C_HP_BG; mp_bg_s.set_corner_radius_all(3)
	mp_bar.add_theme_stylebox_override("background", mp_bg_s)
	mp_row.add_child(mp_bar)
	_player_mp_bars.append(mp_bar)
	vbox.add_child(mp_row)

	card.add_child(vbox)
	plate.add_child(card)
	return plate


# ─── Action menu — anchored to bottom-right of actual viewport ────────────────
func _build_action_menu() -> void:
	_action_panel = Panel.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = C_PANEL_BG
	ps.border_color = C_BORDER
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(6)
	_action_panel.add_theme_stylebox_override("panel", ps)

	var pw := SW * PANEL_W_N
	var ph := SH * PANEL_H_N
	_action_panel.size     = Vector2(pw, ph)
	_action_panel.position = Vector2(SW - pw - SW * PANEL_PAD_R,
									  SH - ph - SH * PANEL_PAD_B)
	_action_panel.visible  = false

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_action_panel.add_child(margin)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 7)
	margin.add_child(grid)

	var btn_w := (pw * 0.5) - 14
	var btn_h := (ph * 0.5) - 12
	var labels   := ["Attack", "Block", "Special", "Heal"]
	var handlers := [_on_action_attack, _on_action_block, _on_action_special, _on_action_item]
	for idx in 4:
		var btn := Button.new()
		btn.text = labels[idx]
		btn.custom_minimum_size = Vector2(btn_w, btn_h)
		UIStyle.style_button(btn)
		btn.pressed.connect(handlers[idx])
		grid.add_child(btn)
		_action_buttons.append(btn)

	_hud.add_child(_action_panel)


# ─── Indicators ───────────────────────────────────────────────────────────────
func _build_indicators() -> void:
	var s := SH / REF_H   # uniform scale factor
	var tri := PackedVector2Array([
		Vector2(-24 * s, -34 * s), Vector2(24 * s, -34 * s), Vector2(0, 0)
	])
	_active_arrow = Polygon2D.new()
	_active_arrow.polygon = tri
	_active_arrow.color = C_GOLD
	_active_arrow.z_index = 60
	_active_arrow.visible = false
	add_child(_active_arrow)

	_target_arrow = Polygon2D.new()
	_target_arrow.polygon = tri
	_target_arrow.color = C_DMG_RED
	_target_arrow.z_index = 60
	_target_arrow.visible = false
	add_child(_target_arrow)


func _point_arrow(arrow: Polygon2D, sprite: TextureRect) -> void:
	var base_y := sprite.position.y - SH * 0.006
	arrow.position = Vector2(sprite.position.x + sprite.size.x * 0.5, base_y)
	arrow.visible = true
	if arrow == _active_arrow:
		_active_arrow_base_y = base_y
	else:
		_target_arrow_base_y = base_y


func _animate_indicators(delta: float) -> void:
	_ind_time += delta
	var bob: float = sin(_ind_time * 5.0) * (SH * 0.006)
	if _active_arrow != null and _active_arrow.visible:
		_active_arrow.position.y = _active_arrow_base_y + bob
	if _target_arrow != null and _target_arrow.visible:
		_target_arrow.position.y = _target_arrow_base_y + bob


# ─── Game feel ────────────────────────────────────────────────────────────────
func _lunge(sprite: TextureRect, direction: float) -> void:
	var orig := sprite.position
	var offset := Vector2(direction * SW * 0.047, 0)
	var tw := create_tween()
	tw.tween_property(sprite, "position", orig + offset, 0.12).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(sprite, "position", orig, 0.16).set_trans(Tween.TRANS_QUAD)


func _flash(sprite: TextureRect) -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1.5, 0.4, 0.4, 1.0), 0.05)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.18)


func _first_living_enemy() -> Unit:
	for e in enemy_team:
		if e.hp > 0:
			return e
	return null


# ─── Music ────────────────────────────────────────────────────────────────────
func _start_music() -> void:
	var player := AudioStreamPlayer.new()
	player.stream = load("res://assets/audio/combat.mp3")
	player.volume_db = -8.0
	player.autoplay = true
	add_child(player)


# ─── Process ──────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	_animate_indicators(delta)
	if is_waiting_for_input:
		return
	for unit in combined_team:
		if unit.hp <= 0:
			continue
		unit.turn_bar += unit.speed * delta
		if unit.turn_bar >= 100.0:
			unit.turn_bar -= 100.0
			is_waiting_for_input = true
			_execute_turn(unit)
			return


# ─── Turn dispatch ────────────────────────────────────────────────────────────
func _execute_turn(unit: Unit) -> void:
	active_unit = unit
	_clear_turn_glows()
	if unit.tag == "player":
		_player_turn_glows[unit.glabel].visible = true
		_point_arrow(_active_arrow, _player_sprites[unit.glabel])
		_do_player_turn(unit)
	else:
		_point_arrow(_active_arrow, _enemy_sprites[unit.glabel])
		_do_enemy_turn(unit)


func _do_player_turn(unit: Unit) -> void:
	_action_panel.visible = true
	active_target = _first_living_enemy()
	if active_target != null:
		_point_arrow(_target_arrow, _enemy_sprites[active_target.glabel])
	_status_label.text = "%s's turn  —  click an enemy to target, then choose an action." % unit.name
	if unit.blockturn > 0:
		unit.blockturn -= 1
		if unit.blockturn <= 0:
			unit.blocking = false


func _do_enemy_turn(unit: Unit) -> void:
	_action_panel.visible = false
	_status_label.text = "%s is preparing…" % unit.name
	await get_tree().create_timer(0.7).timeout
	if unit.hp <= 0:
		_finish_turn()
		return
	if randf() < 0.20:
		_status_label.text = "%s regenerates!" % unit.name
		_play_sfx(SFX_HEAL, 13.0) #test
		var heal := 15
		unit.healed(heal)
		var ecenter := _enemy_sprites[unit.glabel].position + _enemy_sprites[unit.glabel].size * 0.5
		_spawn_number(ecenter, "+%d" % heal, C_HEAL_GREEN)
		_play_effect(FX_HEAL_SHEET, 4, 1, 4, ecenter, SH * 0.278)
		await get_tree().create_timer(0.5).timeout
	else:
		var living: Array = player_team.filter(func(p: Unit): return p.hp > 0)
		if living.is_empty():
			_end_battle(false)
			return
		var target: Unit = living[randi() % living.size()] as Unit
		var tsprite := _player_sprites[target.glabel]
		_point_arrow(_target_arrow, tsprite)
		_status_label.text = "%s attacks %s!" % [unit.name, target.name]
		_play_sfx(SFX_ATTACK, 3.0) #test
		await get_tree().create_timer(0.5).timeout
		_lunge(_enemy_sprites[unit.glabel], -1.0)
		var dmg := unit.strength / 2 if target.blocking else unit.strength
		target.take_dmg(dmg)
		var pcenter := tsprite.position + tsprite.size * 0.5
		_spawn_number(pcenter, str(dmg), C_DMG_WHITE)
		_play_effect(FX_ENEMY_SHEET, 4, 1, 4, pcenter, SH * 0.296)
		if target.hp <= 0:
			target.turn_bar = -1e12
			tsprite.modulate = Color(0.3, 0.3, 0.3, 0.45)
		else:
			_flash(tsprite)
		await get_tree().create_timer(0.45).timeout
	_refresh_hud()
	_check_battle_end()
	_finish_turn()


# ─── Player actions ───────────────────────────────────────────────────────────
func _on_action_attack() -> void:
	if not _check_needs_target(): return
	_play_sfx(SFX_ATTACK, 3.0) #test
	var dmg := active_unit.strength
	var tgt_sprite := _enemy_sprites[active_target.glabel]
	_lunge(_player_sprites[active_unit.glabel], 1.0)
	active_target.take_dmg(active_unit.strength)
	var ecenter := tgt_sprite.position + tgt_sprite.size * 0.5
	_spawn_number(ecenter, str(active_unit.strength), C_DMG_WHITE)
	_play_effect(FX_MELEE_SHEET, 2, 2, 4, ecenter, SH * 0.333)
	if active_target.hp <= 0:
		_on_enemy_killed(active_target)
	else:
		_flash(tgt_sprite)
	_after_player_action()


func _on_action_block() -> void:
	if active_unit == null: return
	_play_sfx(SFX_BLOCK, 10.0) #test
	active_unit.blocking  = true
	active_unit.blockturn = 2
	_status_label.text = "%s braces for impact!" % active_unit.name
	_after_player_action()


func _on_action_special() -> void:
	if not _check_needs_target(): return
	if not _check_mp(SPECIAL_MP_COST): return
	_play_sfx(SFX_SPECIAL, 2.5) #test
	active_unit.mp -= SPECIAL_MP_COST
	var dmg := int(active_unit.strength * 1.6)
	var tgt_sprite := _enemy_sprites[active_target.glabel]
	_lunge(_player_sprites[active_unit.glabel], 1.0)
	active_target.take_dmg(dmg)
	var ecenter := tgt_sprite.position + tgt_sprite.size * 0.5
	_spawn_number(ecenter, "%d!" % dmg, C_DMG_RED)
	_play_effect(FX_PULSE_SHEET, 4, 1, 4, ecenter, SH * 0.352)
	if active_target.hp <= 0:
		_on_enemy_killed(active_target)
	else:
		_flash(tgt_sprite)
	_after_player_action()


func _on_action_item() -> void:
	if active_unit == null: return
	if not _check_mp(HEAL_MP_COST): return
	_play_sfx(SFX_HEAL, 13.0) #test
	active_unit.mp -= HEAL_MP_COST
	var heal: int = mini(30, active_unit.max_hp - active_unit.hp)
	active_unit.healed(heal)
	_status_label.text = "%s heals %d HP!" % [active_unit.name, heal]
	var pcenter := _player_sprites[active_unit.glabel].position + _player_sprites[active_unit.glabel].size * 0.5
	_spawn_number(pcenter, "+%d" % heal, C_HEAL_GREEN)
	_play_effect(FX_HEAL_SHEET, 4, 1, 4, pcenter, SH * 0.296)
	_after_player_action()


func _check_mp(cost: int) -> bool:
	if active_unit == null: return false
	if active_unit.mp < cost:
		_status_label.text = "%s doesn't have enough MP! (needs %d)" % [active_unit.name, cost]
		return false
	return true


func _check_needs_target() -> bool:
	if active_unit == null: return false
	if active_target == null or active_target.hp <= 0:
		_status_label.text = "Select a living enemy target first!"
		return false
	return true


func _on_enemy_killed(target: Unit) -> void:
	if target.hp <= 0:
		target.turn_bar = -1e12
		_enemy_sprites[target.glabel].modulate = Color(0.25, 0.25, 0.25, 0.4)


func _after_player_action() -> void:
	_refresh_hud()
	_check_battle_end()
	_finish_turn()


# ─── Enemy targeting ──────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton
			and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if active_unit == null or active_unit.tag != "player":
		return
	# Sprites are direct children of this Node2D with no parent scaling,
	# so viewport mouse position equals local position directly.
	var mouse_pos := get_viewport().get_mouse_position()
	for i in 4:
		if enemy_team[i].hp <= 0:
			continue
		var rect := Rect2(_enemy_sprites[i].position, _enemy_sprites[i].size)
		if rect.has_point(mouse_pos):
			active_target = enemy_team[i]
			_point_arrow(_target_arrow, _enemy_sprites[i])
			_status_label.text = "Target: %s  —  choose an action." % active_target.name
			get_viewport().set_input_as_handled()
			return


# ─── Helpers ──────────────────────────────────────────────────────────────────
func _clear_turn_glows() -> void:
	for g in _player_turn_glows: g.visible = false
	if _active_arrow != null: _active_arrow.visible = false
	if _target_arrow != null: _target_arrow.visible = false


func _finish_turn() -> void:
	_action_panel.visible = false
	_clear_turn_glows()
	active_unit   = null
	active_target = null
	is_waiting_for_input = false


func _refresh_hud() -> void:
	for i in player_team.size():
		var u := player_team[i]
		_player_hp_bars[i].max_value = u.max_hp
		_player_hp_bars[i].value     = maxi(0, u.hp)
		_player_mp_bars[i].max_value = u.max_mp
		_player_mp_bars[i].value     = maxi(0, u.mp)


# ─── Effect animation ─────────────────────────────────────────────────────────
func _play_effect(path: String, hframes: int, vframes: int, frame_count: int,
		center: Vector2, display_h: float) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		push_warning("Effect texture missing: %s" % path)
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.hframes = hframes
	spr.vframes = vframes
	spr.frame = 0
	spr.centered = true
	spr.position = center
	spr.z_index = 50
	var frame_h: float = float(tex.get_height()) / float(vframes)
	spr.scale = Vector2.ONE * (display_h / frame_h)
	add_child(spr)
	var tw := create_tween()
	tw.tween_method(func(f: float): spr.frame = clampi(int(f), 0, frame_count - 1),
			0.0, float(frame_count), 0.45)
	tw.tween_callback(spr.queue_free)


# ─── Floating numbers ─────────────────────────────────────────────────────────
func _spawn_number(world_pos: Vector2, text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", int(SH * 0.031))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = world_pos + Vector2(-13, -17)
	add_child(lbl)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -SH * 0.067), 0.88)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.88)
	tw.chain().tween_callback(lbl.queue_free)


# ─── Battle end ───────────────────────────────────────────────────────────────
func _check_battle_end() -> void:
	if player_team.all(func(p: Unit): return p.hp <= 0):
		_end_battle(false)
	elif enemy_team.all(func(e: Unit): return e.hp <= 0):
		_end_battle(true)


func _end_battle(player_won: bool) -> void:
	is_waiting_for_input = true
	set_process(false)
	_action_panel.visible = false
	_clear_turn_glows()
	var msg   := "VICTORY!" if player_won else "DEFEAT!"
	var color := C_GOLD    if player_won else C_DMG_RED
	if player_won:
		QuestManager.notify_enemies_defeated(enemy_team.size())
		EconomyManager.earn(50)
	var result := Label.new()
	result.text = msg
	result.add_theme_color_override("font_color", color)
	result.add_theme_font_size_override("font_size", int(SH * 0.081))
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.position = Vector2(SW * 0.5 - SW * 0.104, SH * 0.5 - SH * 0.051)
	_hud.add_child(result)

	await get_tree().create_timer(0.1).timeout

	NavigationManager.saved_player_position = NavigationManager.battle_return_position
	NavigationManager.go_to_level(NavigationManager.battle_return_level, null)

# ─── Audio management ───────────────────────────────────────────────────────────────

func _play_sfx(path: String, volume_db: float = -4.0) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("Missing SFX: %s" % path)
		return

	_sfx_player.stop()
	_sfx_player.stream = stream
	_sfx_player.volume_db = volume_db
	_sfx_player.play()
