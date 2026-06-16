extends Node2D

# ─── Layout ───────────────────────────────────────────────────────────────────
const SCREEN_W := 1920.0
const SCREEN_H := 1080.0

# World-space anchor positions (centre of each sprite)
# Staggered diagonally so sprites overlap naturally like the GDD screenshot
# 2×2 staggered formation, spread to fill each half of the screen
const PLAYER_POS: Array = [
	Vector2(360, 850),   # P1 Athena   — front-left
	Vector2(610, 720),   # P2 Zeus     — back-right
	Vector2(180, 710),   # P3 Hermes   — back-left
	Vector2(560, 890),   # P4 Poseidon — front-right
]
const ENEMY_POS: Array = [
	Vector2(1150, 850),  # E1 Crawler  — front-left
	Vector2(1370, 680),  # E2 Floater  — back-center (floats high)
	Vector2(1630, 730),  # E3 Brute    — back-right
	Vector2(1400, 890),  # E4 Stalker  — front-right
]

# Uniform sizes — every player equal, every enemy equal
const PLAYER_SPRITE_SIZE := Vector2(540, 680)
const ENEMY_SPRITE_SIZE  := Vector2(470, 470)
const PLAYER_SPRITE_SIZES = [
	PLAYER_SPRITE_SIZE, PLAYER_SPRITE_SIZE, PLAYER_SPRITE_SIZE, PLAYER_SPRITE_SIZE,
]
const ENEMY_SPRITE_SIZES = [
	ENEMY_SPRITE_SIZE, ENEMY_SPRITE_SIZE, ENEMY_SPRITE_SIZE, ENEMY_SPRITE_SIZE,
]

const PORTRAIT_PX  := 80
const HP_BAR_W     := 240
const HP_BAR_H     := 18

# Colour palette (mirrors UIStyle.gd)
const C_TOP_BAR    := Color(0.06, 0.05, 0.05, 0.92)
const C_BORDER     := Color(0.49, 0.13, 0.13, 1.00)
const C_PANEL_BG   := Color(0.10, 0.08, 0.08, 0.93)
const C_HP_FILL    := Color(0.18, 0.72, 0.22, 1.00)
const C_HP_BG      := Color(0.16, 0.16, 0.16, 1.00)
const C_TEXT       := Color(0.94, 0.91, 0.88, 1.00)
const C_MUTED      := Color(0.66, 0.56, 0.50, 1.00)
const C_GOLD       := Color(0.95, 0.82, 0.38, 1.00)
const C_DMG_WHITE  := Color(1.00, 1.00, 1.00, 1.00)
const C_DMG_RED    := Color(1.00, 0.25, 0.15, 1.00)
const C_HEAL_GREEN := Color(0.18, 0.90, 0.30, 1.00)
const C_GLOW_TURN  := Color(1.00, 0.90, 0.20, 0.42)
const C_GLOW_ENEMY := Color(1.00, 0.85, 0.10, 0.30)

# Asset paths
const PLAYER_TEXTURES = [
	"res://assets/sprites/characters/Mars_Athena.png",
	"res://assets/sprites/characters/Mars_Zeus.png",
	"res://assets/sprites/characters/Mars_Hermes.png",
	"res://assets/sprites/characters/Mars_Poseidon.png",
]
const ENEMY_TEXTURES = [
	"res://assets/sprites/enemies/Mars_crawler.png",
	"res://assets/sprites/enemies/Mars_floater.png",
	"res://assets/sprites/enemies/Mars_Brute.png",
	"res://assets/sprites/enemies/Mars_stalker.png",
]
const BG_TEXTURES = [
	"res://assets/backgrounds/combat_background_outdoors.png",
]

# Effect sprite sheets (hframes × vframes shown in comments)
const FX_MELEE_SHEET := "res://assets/sprites/effects/Mars_Animation_MeleeSlash.png" # 2×2
const FX_PULSE_SHEET := "res://assets/sprites/effects/Mars_Animation_Pulse.png"      # 4×1
const FX_ENEMY_SHEET := "res://assets/sprites/effects/Mars_Animation_EnemyAttack.png"# 4×1
const FX_HEAL_SHEET  := "res://assets/sprites/effects/Mars_Animation_Healing.png"    # 4×1

# ─── Combat state ─────────────────────────────────────────────────────────────
var player_team:   Array[Unit] = []
var enemy_team:    Array[Unit] = []
var combined_team: Array[Unit] = []
var is_waiting_for_input := false
var active_unit:   Unit = null
var active_target: Unit = null

# ─── UI nodes (populated in _ready) ──────────────────────────────────────────
var _hud: CanvasLayer
var _player_hp_bars:    Array[ProgressBar] = []
var _player_turn_glows: Array[ColorRect]   = []
var _player_sprites:    Array[TextureRect] = []
var _enemy_sprites:     Array[TextureRect] = []
var _enemy_turn_glows:  Array[ColorRect]   = []
var _action_panel: Panel
var _action_buttons: Array[Button] = []
var _status_label: Label

# Turn / target indicator arrows (replace the old yellow boxes)
var _active_arrow: Polygon2D
var _target_arrow: Polygon2D
var _active_arrow_base_y := 0.0
var _target_arrow_base_y := 0.0
var _ind_time := 0.0

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_init_units()
	_build_background()
	_build_enemy_sprites()
	_build_player_sprites()
	_build_hud()
	_build_action_menu()
	_build_indicators()
	_start_music()
	_refresh_hud()
	print("BattleSystem ready — %d combatants" % combined_team.size())


# ─── Unit initialisation ──────────────────────────────────────────────────────
func _init_units() -> void:
	# Players start with a turn-bar head start so a hero acts first
	var p1 := Unit.new("Athena",   100, 14, 50,  5, "player", 0, false, 0)
	var p2 := Unit.new("Zeus",      80, 12, 50, 12, "player", 1, false, 0)
	var p3 := Unit.new("Hermes",   120, 18, 50,  8, "player", 2, false, 0)
	var p4 := Unit.new("Poseidon",  90, 15, 50, 10, "player", 3, false, 0)

	var e1 := Unit.new("Crawler",   50,  8, 0, 10, "enemy", 0, false, 0)
	var e2 := Unit.new("Floater",   60, 12, 0, 15, "enemy", 1, false, 0)
	var e3 := Unit.new("Brute",    120, 20, 0,  4, "enemy", 2, false, 0)
	var e4 := Unit.new("Stalker",   80, 14, 0,  9, "enemy", 3, false, 0)

	player_team   = [p1, p2, p3, p4]
	enemy_team    = [e1, e2, e3, e4]
	combined_team = [p1, p2, p3, p4, e1, e2, e3, e4]


# ─── Background ───────────────────────────────────────────────────────────────
func _build_background() -> void:
	var bg := TextureRect.new()
	bg.texture = load(BG_TEXTURES[randi() % BG_TEXTURES.size()])
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = Vector2(SCREEN_W, SCREEN_H)
	bg.position = Vector2.ZERO
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


# ─── Enemy sprites ────────────────────────────────────────────────────────────
func _build_enemy_sprites() -> void:
	for i in 4:
		var esz: Vector2 = ENEMY_SPRITE_SIZES[i] as Vector2

		var sprite := TextureRect.new()
		sprite.texture = load(ENEMY_TEXTURES[i])
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.size = esz
		sprite.position = ENEMY_POS[i] - esz * 0.5
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sprite)
		_enemy_sprites.append(sprite)


# ─── Player sprites ───────────────────────────────────────────────────────────
func _build_player_sprites() -> void:
	for i in 4:
		var psz: Vector2 = PLAYER_SPRITE_SIZES[i] as Vector2
		var sprite := TextureRect.new()
		sprite.texture = load(PLAYER_TEXTURES[i])
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.size = psz
		sprite.position = PLAYER_POS[i] - psz * 0.5
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sprite)
		_player_sprites.append(sprite)


# ─── HUD (top bar + portrait cards) ──────────────────────────────────────────
func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 10
	add_child(_hud)

	# Portrait cards overlay directly on the battlefield (no opaque top bar)
	var hbox := HBoxContainer.new()
	hbox.position = Vector2(18, 12)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 22)
	_hud.add_child(hbox)

	for i in 4:
		hbox.add_child(_make_player_card(i))

	# Status / target label (bottom of screen)
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_color_override("font_color", C_GOLD)
	_status_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_status_label.add_theme_constant_override("outline_size", 8)
	_status_label.add_theme_font_size_override("font_size", 24)
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_label.size = Vector2(SCREEN_W, 40)
	_status_label.position = Vector2(0, 122)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_child(_status_label)


func _make_player_card(i: int) -> Control:
	# Translucent plate so the HP reads over the battlefield art
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate_style := StyleBoxFlat.new()
	plate_style.bg_color = Color(0.05, 0.04, 0.04, 0.55)
	plate_style.set_corner_radius_all(8)
	plate_style.content_margin_left = 8
	plate_style.content_margin_right = 10
	plate_style.content_margin_top = 6
	plate_style.content_margin_bottom = 6
	plate.add_theme_stylebox_override("panel", plate_style)

	var card := HBoxContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_constant_override("separation", 10)

	# Portrait frame
	var frame := Panel.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.08, 0.07, 0.07, 1.0)
	frame_style.border_color = C_BORDER
	frame_style.set_border_width_all(2)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.custom_minimum_size = Vector2(PORTRAIT_PX + 4, PORTRAIT_PX + 4)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var portrait := TextureRect.new()
	portrait.texture = load(PLAYER_TEXTURES[i])
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(portrait)

	# Yellow glow overlay shown on this unit's turn
	var glow := ColorRect.new()
	glow.color = C_GLOW_TURN
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.visible = false
	frame.add_child(glow)
	_player_turn_glows.append(glow)

	card.add_child(frame)

	# Right column: name on top, then "HP" + bar side by side
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(HP_BAR_W, 0)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)

	var name_lbl := Label.new()
	name_lbl.text = player_team[i].name
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	name_lbl.add_theme_constant_override("outline_size", 5)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	# HP label + bar on one horizontal row
	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_theme_constant_override("separation", 6)

	var hp_tag := Label.new()
	hp_tag.text = "HP"
	hp_tag.add_theme_color_override("font_color", C_MUTED)
	hp_tag.add_theme_font_size_override("font_size", 13)
	hp_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_child(hp_tag)

	var hp_bar := ProgressBar.new()
	hp_bar.max_value = player_team[i].max_hp
	hp_bar.value     = player_team[i].hp
	hp_bar.custom_minimum_size = Vector2(HP_BAR_W - 30, HP_BAR_H)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.show_percentage = false
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fill_s := StyleBoxFlat.new()
	fill_s.bg_color = C_HP_FILL
	fill_s.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("fill", fill_s)

	var bg_s := StyleBoxFlat.new()
	bg_s.bg_color = C_HP_BG
	bg_s.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("background", bg_s)

	hp_row.add_child(hp_bar)
	_player_hp_bars.append(hp_bar)
	vbox.add_child(hp_row)

	card.add_child(vbox)
	plate.add_child(card)
	return plate


# ─── Action menu (bottom-right, player turn only) ────────────────────────────
func _build_action_menu() -> void:
	_action_panel = Panel.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = C_PANEL_BG
	ps.border_color = C_BORDER
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(6)
	_action_panel.add_theme_stylebox_override("panel", ps)
	_action_panel.size     = Vector2(384, 172)
	_action_panel.position = Vector2(SCREEN_W - 404, SCREEN_H - 192)
	_action_panel.visible  = false

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   14)
	margin.add_theme_constant_override("margin_right",  14)
	margin.add_theme_constant_override("margin_top",    12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_action_panel.add_child(margin)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	margin.add_child(grid)

	var btn_attack := Button.new()
	btn_attack.text = "Attack"
	btn_attack.custom_minimum_size = Vector2(162, 58)
	UIStyle.style_button(btn_attack)
	btn_attack.pressed.connect(_on_action_attack)
	grid.add_child(btn_attack)
	_action_buttons.append(btn_attack)

	var btn_block := Button.new()
	btn_block.text = "Block"
	btn_block.custom_minimum_size = Vector2(162, 58)
	UIStyle.style_button(btn_block)
	btn_block.pressed.connect(_on_action_block)
	grid.add_child(btn_block)
	_action_buttons.append(btn_block)

	var btn_special := Button.new()
	btn_special.text = "Special"
	btn_special.custom_minimum_size = Vector2(162, 58)
	UIStyle.style_button(btn_special)
	btn_special.pressed.connect(_on_action_special)
	grid.add_child(btn_special)
	_action_buttons.append(btn_special)

	var btn_item := Button.new()
	btn_item.text = "Heal"
	btn_item.custom_minimum_size = Vector2(162, 58)
	UIStyle.style_button(btn_item)
	btn_item.pressed.connect(_on_action_item)
	grid.add_child(btn_item)
	_action_buttons.append(btn_item)

	_hud.add_child(_action_panel)


# ─── Turn / target arrows ─────────────────────────────────────────────────────
func _build_indicators() -> void:
	var tri := PackedVector2Array([Vector2(-24, -34), Vector2(24, -34), Vector2(0, 0)])
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
	var base_y := sprite.position.y - 6.0
	arrow.position = Vector2(sprite.position.x + sprite.size.x * 0.5, base_y)
	arrow.visible = true
	if arrow == _active_arrow:
		_active_arrow_base_y = base_y
	else:
		_target_arrow_base_y = base_y


func _animate_indicators(delta: float) -> void:
	_ind_time += delta
	var bob: float = sin(_ind_time * 5.0) * 7.0
	if _active_arrow != null and _active_arrow.visible:
		_active_arrow.position.y = _active_arrow_base_y + bob
	if _target_arrow != null and _target_arrow.visible:
		_target_arrow.position.y = _target_arrow_base_y + bob


# ─── Game-feel: quick lunge toward foe, red hit-flash ─────────────────────────
func _lunge(sprite: TextureRect, offset: Vector2) -> void:
	var orig := sprite.position
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


# ─── Process: advance turn bars ───────────────────────────────────────────────
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
	# Auto-target the first living enemy so Attack always works; clicking re-targets
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
		var heal := 15
		unit.healed(heal)
		var ecenter := _enemy_sprites[unit.glabel].position + _enemy_sprites[unit.glabel].size * 0.5
		_spawn_number(ecenter, "+%d" % heal, C_HEAL_GREEN)
		_play_effect(FX_HEAL_SHEET, 4, 1, 4, ecenter, 300)
		await get_tree().create_timer(0.5).timeout
	else:
		var living: Array = player_team.filter(func(p: Unit): return p.hp > 0)
		if living.is_empty():
			_end_battle(false)
			return
		var target: Unit = living[randi() % living.size()] as Unit
		var tsprite := _player_sprites[target.glabel]

		# Telegraph: show who is being attacked BEFORE the hit lands
		_point_arrow(_target_arrow, tsprite)
		_status_label.text = "%s attacks %s!" % [unit.name, target.name]
		await get_tree().create_timer(0.5).timeout

		_lunge(_enemy_sprites[unit.glabel], Vector2(-80, 0))
		var dmg := unit.strength / 2 if target.blocking else unit.strength
		target.take_dmg(dmg)
		var pcenter := tsprite.position + tsprite.size * 0.5
		_spawn_number(pcenter, str(dmg), C_DMG_WHITE)
		_play_effect(FX_ENEMY_SHEET, 4, 1, 4, pcenter, 320)
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
	var dmg := active_unit.strength
	var tgt_sprite := _enemy_sprites[active_target.glabel]
	_lunge(_player_sprites[active_unit.glabel], Vector2(90, 0))
	active_target.take_dmg(dmg)
	var ecenter := tgt_sprite.position + tgt_sprite.size * 0.5
	_spawn_number(ecenter, str(dmg), C_DMG_WHITE)
	_play_effect(FX_MELEE_SHEET, 2, 2, 4, ecenter, 360)
	if active_target.hp <= 0:
		_on_enemy_killed(active_target)
	else:
		_flash(tgt_sprite)
	_after_player_action()


func _on_action_block() -> void:
	if active_unit == null: return
	active_unit.blocking  = true
	active_unit.blockturn = 2
	_status_label.text = "%s braces for impact!" % active_unit.name
	_after_player_action()


func _on_action_special() -> void:
	if not _check_needs_target(): return
	var dmg := int(active_unit.strength * 1.6)
	var tgt_sprite := _enemy_sprites[active_target.glabel]
	_lunge(_player_sprites[active_unit.glabel], Vector2(90, 0))
	active_target.take_dmg(dmg)
	var ecenter := tgt_sprite.position + tgt_sprite.size * 0.5
	_spawn_number(ecenter, "%d!" % dmg, C_DMG_RED)
	_play_effect(FX_PULSE_SHEET, 4, 1, 4, ecenter, 380)
	if active_target.hp <= 0:
		_on_enemy_killed(active_target)
	else:
		_flash(tgt_sprite)
	_after_player_action()


func _on_action_item() -> void:
	if active_unit == null: return
	var heal: int = mini(30, active_unit.max_hp - active_unit.hp)
	active_unit.healed(heal)
	_status_label.text = "%s heals %d HP!" % [active_unit.name, heal]
	var pcenter := _player_sprites[active_unit.glabel].position + _player_sprites[active_unit.glabel].size * 0.5
	_spawn_number(pcenter, "+%d" % heal, C_HEAL_GREEN)
	_play_effect(FX_HEAL_SHEET, 4, 1, 4, pcenter, 320)
	_after_player_action()


func _check_needs_target() -> bool:
	if active_unit == null:
		return false
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


# ─── Enemy targeting via mouse click (handled via _unhandled_input) ───────────
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton
			and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if active_unit == null or active_unit.tag != "player":
		return

	var mouse_pos := get_global_mouse_position()
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


# ─── Effect animation (plays a sprite-sheet then frees itself) ───────────────
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
	var s: float = display_h / frame_h
	spr.scale = Vector2(s, s)
	add_child(spr)

	var tw := create_tween()
	tw.tween_method(
			func(f: float): spr.frame = clampi(int(f), 0, frame_count - 1),
			0.0, float(frame_count), 0.45)
	tw.tween_callback(spr.queue_free)


# ─── Floating damage / heal numbers ──────────────────────────────────────────
func _spawn_number(world_pos: Vector2, text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = world_pos + Vector2(-18, -24)
	add_child(lbl)

	var tw := create_tween().set_parallel(true)
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -72), 0.88)
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

	var msg  := "VICTORY!" if player_won else "DEFEAT!"
	var color := C_GOLD   if player_won else C_DMG_RED

	if player_won:
		QuestManager.notify_enemies_defeated(enemy_team.size())
		EconomyManager.earn(50)

	var result := Label.new()
	result.text = msg
	result.add_theme_color_override("font_color", color)
	result.add_theme_font_size_override("font_size", 88)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.position = Vector2(SCREEN_W * 0.5 - 200, SCREEN_H * 0.5 - 55)
	_hud.add_child(result)

	if not player_won:
		await get_tree().create_timer(2.5).timeout
		get_tree().quit()
