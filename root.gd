extends Node2D

const GameSettings = preload("res://game_settings.gd")
const BombExplosionScene = preload("res://bomb_explosion.tscn")
const FloatingScoreScene = preload("res://floating_score.gd")
const SPRITE_OUTLINE_SHADER = preload("res://sprite_outline_solid.gdshader")

const BASE_VIEWPORT_SIZE := Vector2(800, 600)
const HIGAN_THROW_FRAMES: Array[Texture2D] = [
	preload("res://Images/higan_throw/хиган_шут00.png"),
	preload("res://Images/higan_throw/хиган_шут01.png"),
	preload("res://Images/higan_throw/хиган_шут02.png"),
	preload("res://Images/higan_throw/хиган_шут03.png")
]
const HIGAN_THROW_ANIMATION_NAME := &"throw"
const HIGAN_THROW_ANIMATION_FPS := 16.0
const HIGAN_SPAWN_BLOCK_PADDING := 50.0
const UFO_SCORE_BONUS := 2500
const UFO_FIRST_THRESHOLD := 5000
const UFO_BASE_FLIGHT_DURATION := 2.0
const UFO_MIN_FLIGHT_DURATION := 0.4
const UFO_SPAWN_DELAY_MIN := 10.0
const UFO_SPAWN_DELAY_MAX := 15.0
const SNOW_FLAP_SEGMENT_MIN := 50.0
const SNOW_FLAP_SEGMENT_MAX := 200.0
const SNOW_VERTICAL_LIMIT_FROM_TOP := 250.0
const SNOW_VERTICAL_SPEED_MIN := 260.0
const SNOW_VERTICAL_SPEED_MAX := 420.0
const DOUBLE_ENEMY_SCORE_THRESHOLD := 4000
const DOUBLE_ENEMY_CHANCE := 0.5
const ARROW_SPEED := 1999.0
const SHOOT_COOLDOWN := 0.1
const COMBO_STEP := 5
const COMBO_TIMEOUT := 4.0
const BONUS_TIME_KILL_STEP := 50
const BONUS_TIME_SECONDS := 15
const ENEMY_OUTLINE_COLOR := Color8(235, 24, 24)
const ALLY_OUTLINE_COLOR := Color8(38, 210, 72)
const OUTLINE_SCALE_MULTIPLIER := 1.18
const OUTLINE_Z_OFFSET := -1
const PAUSE_BUTTON_SHAKE_OFFSET := 3.0
const PAUSE_BUTTON_SHAKE_SPEED := 26.0

const ENEMY_SCORE_COLOR := Color(1.0, 0.85, 0.2, 1.0)
const ALLY_SCORE_COLOR := Color(0.46, 0.08, 0.12, 1.0)
const UFO_SCORE_COLOR := Color(0.67, 0.34, 0.95, 1.0)
const COMBO_BASE_COLOR := Color(0.997744, 0.98514646, 0.9836703, 1.0)
const COMBO_YELLOW_COLOR := Color(1.0, 0.9, 0.24, 1.0)
const COMBO_RED_COLOR := Color(1.0, 0.26, 0.18, 1.0)
const COMBO_VIOLET_COLOR := Color(0.76, 0.42, 1.0, 1.0)
const COMBO_CYAN_COLOR := Color(0.3, 0.92, 1.0, 1.0)
const COMBO_OUTLINE_BASE_COLOR := Color(0.2, 0.05, 0.02, 1.0)
const COMBO_OUTLINE_HOT_COLOR := Color(0.45, 0.12, 0.04, 1.0)

const ENEMY_SCORES := {
	"Varan": 50,
	"Shnume": 100,
	"Ruben": 150,
	"Rekvi": 200,
	"Tostar": 250
}

const ALLY_SCORES := {
	"Nyamura": -250,
	"Alisque": -500
}

const ALLY_NODE_PATHS := {
	"Nyamura": {
		"sprite": "Sprite2DNyamura",
		"collision": "CollisionShape2DNyamura"
	},
	"Alisque": {
		"sprite": "Sprite2DAlisque",
		"collision": "CollisionShape2DAlisque"
	}
}

const ENEMY_NODE_PATHS := {
	"Shnume": {
		"sprite": "Sprite2DShnume",
		"collision": "CollisionShape2DShnume"
	},
	"Rekvi": {
		"sprite": "Sprite2DRekvi",
		"collision": "CollisionShape2DRekvi"
	},
	"Tostar": {
		"sprite": "Sprite2DTostar",
		"collision": "CollisionShape2DTostar"
	},
	"Varan": {
		"sprite": "Sprite2DVaran",
		"collision": "CollisionShape2DVaran"
	},
	"Ruben": {
		"sprite": "Sprite2DRuben",
		"collision": "CollisionShape2DRuben"
	},
	"Snow": {
		"sprite": "Sprite2DSnow",
		"collision": "CollisionShape2DSnow"
	}
}

@onready var aim: Sprite2D = $Aim
@onready var background_sprite: Sprite2D = $Background
@onready var bow: Node2D = $Bow
@onready var higan_throw_frame: ReferenceRect = $Bow/HiganThrowFrame
@onready var higan_throw_animation: AnimatedSprite2D = $Bow/HiganThrowAnimation
@onready var shot_flash: Polygon2D = $Bow/ShotFlash
@onready var shot_flash_core: Polygon2D = $Bow/ShotFlashCore
@onready var click_sound: AudioStreamPlayer2D = $Background/ZvukStrely2
@onready var music: AudioStreamPlayer = $Background/HiganBombaMusic
@onready var snow_sound: AudioStreamPlayer2D = $Background/SnowSound
@onready var combo_break_sound: AudioStreamPlayer2D = $Background/ComboBreakSound
@onready var bomb_explosion_sound: AudioStreamPlayer2D = $Background/BombExplosionSound
@onready var arrow_scene = preload("res://arrow.tscn")

@onready var hit_sound_players = {
	"Shnume": $Background/ShnumeSound,
	"Rekvi": $Background/RekviSound,
	"Tostar": $Background/ManSound,
	"Varan": $Background/VaranSound,
	"Ruben": $Background/RubenSound
}

@onready var ally_hit_sound_players = {
	"Nyamura": $Background/NyamuraHitSound,
	"Alisque": $Background/AlisqueHitSound
}

@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var timer_label: Label = $CanvasLayer/TimerLabel
@onready var combo_label: Label = $CanvasLayer/ComboLabel
@onready var pause_overlay: ColorRect = $CanvasLayer/PauseOverlay
@onready var resume_button: Button = $CanvasLayer/PauseOverlay/PausePanel/PauseVBox/ResumeButton
@onready var back_to_menu_button: Button = $CanvasLayer/PauseOverlay/PausePanel/PauseVBox/BackToMenuButton
@onready var resume_button_label: Label = $CanvasLayer/PauseOverlay/PausePanel/PauseVBox/ResumeButton/ResumeButtonLabel
@onready var back_to_menu_button_label: Label = $CanvasLayer/PauseOverlay/PausePanel/PauseVBox/BackToMenuButton/BackToMenuButtonLabel
@onready var pause_effects_slider: HSlider = $CanvasLayer/PauseOverlay/PausePanel/PauseVBox/PauseEffectsSlider
@onready var pause_effects_value_label: Label = $CanvasLayer/PauseOverlay/PausePanel/PauseVBox/PauseEffectsValue
@onready var pause_music_slider: HSlider = $CanvasLayer/PauseOverlay/PausePanel/PauseVBox/PauseMusicSlider
@onready var pause_music_value_label: Label = $CanvasLayer/PauseOverlay/PausePanel/PauseVBox/PauseMusicValue

@onready var enemies = [
	$enemies/Shnume,
	$enemies/Rekvi,
	$enemies/Tostar,
	$enemies/Varan,
	$enemies/Ruben
]

@onready var allies = [
	$allies/Nyamura,
	$allies/Alisque
]

@onready var snow: Area2D = $enemies/Snow

var score := 0
var time_left := 135
var next_ufo_score_threshold := UFO_FIRST_THRESHOLD
var queued_ufo_flight_durations: Array = []
var ufo_active := false
var ufo_start_position := Vector2.ZERO
var ufo_end_position := Vector2.ZERO
var ufo_flight_progress := 0.0
var current_ufo_flight_duration := UFO_BASE_FLIGHT_DURATION
var next_ufo_spawn_time := 0.0
var snow_top_limit_y := 0.0
var snow_bottom_limit_y := 0.0
var snow_vertical_direction := 1.0
var snow_vertical_segment_remaining := 0.0
var snow_vertical_speed := 0.0
var current_effects_volume := GameSettings.DEFAULT_EFFECTS_VOLUME
var next_shot_time := 0.0
var bow_base_position := Vector2.ZERO
var bow_base_scale := Vector2.ZERO
var bow_recoil_offset := Vector2.ZERO
var combo_hits := 0
var combo_last_hit_time := -1.0
var enemies_killed := 0
var pause_button_label_base_offsets: Dictionary = {}
var hovered_pause_button_labels: Dictionary = {}

# Применяет сохраненную громкость музыки поверх базового volume_db, выставленного в сцене.
func _apply_music_volume_from_settings(settings: Dictionary) -> void:
	if music == null:
		return

	var base_volume_db := float(music.get_meta("base_volume_db", music.volume_db))
	var music_volume := float(settings.get("music_volume", GameSettings.DEFAULT_MUSIC_VOLUME))
	music.volume_db = GameSettings.get_music_player_volume_db(base_volume_db, music_volume)

# Применяет сохраненную громкость эффектов поверх базового volume_db, выставленного в сцене.
# Значение 0.5 считается нейтральным: все эффекты играют ровно с громкостью из инспектора.
func _apply_effects_volume_from_settings(settings: Dictionary) -> void:
	current_effects_volume = float(settings.get("effects_volume", GameSettings.DEFAULT_EFFECTS_VOLUME))

	var sfx_players: Array[AudioStreamPlayer2D] = [
		click_sound,
		snow_sound,
		combo_break_sound,
		bomb_explosion_sound
	]

	for player in hit_sound_players.values():
		sfx_players.append(player)
	for player in ally_hit_sound_players.values():
		sfx_players.append(player)

	for player in sfx_players:
		if player == null:
			continue
		var base_volume_db := float(player.get_meta("base_volume_db", player.volume_db))
		player.volume_db = GameSettings.get_sfx_player_volume_db(base_volume_db, current_effects_volume)

func _load_pause_volume_settings() -> void:
	var settings := GameSettings.load_settings()
	var effects_volume := float(settings.get("effects_volume", GameSettings.DEFAULT_EFFECTS_VOLUME))
	var music_volume := float(settings.get("music_volume", GameSettings.DEFAULT_MUSIC_VOLUME))
	pause_effects_slider.value = effects_volume * 100.0
	pause_music_slider.value = music_volume * 100.0
	_update_pause_effects_label(pause_effects_slider.value)
	_update_pause_music_label(pause_music_slider.value)

func _on_pause_effects_changed(value: float) -> void:
	_update_pause_effects_label(value)
	var settings := GameSettings.load_settings()
	var music_volume := float(settings.get("music_volume", GameSettings.DEFAULT_MUSIC_VOLUME))
	var updated_settings := settings.duplicate()
	updated_settings["effects_volume"] = value / 100.0
	updated_settings["music_volume"] = music_volume
	GameSettings.update_and_save(value / 100.0, music_volume, GameSettings.DEFAULT_RESOLUTION_INDEX)
	_apply_effects_volume_from_settings(updated_settings)

func _on_pause_music_changed(value: float) -> void:
	_update_pause_music_label(value)
	var settings := GameSettings.load_settings()
	var effects_volume := float(settings.get("effects_volume", GameSettings.DEFAULT_EFFECTS_VOLUME))
	var updated_settings := settings.duplicate()
	updated_settings["effects_volume"] = effects_volume
	updated_settings["music_volume"] = value / 100.0
	GameSettings.update_and_save(effects_volume, value / 100.0, GameSettings.DEFAULT_RESOLUTION_INDEX)
	_apply_music_volume_from_settings(updated_settings)

func _update_pause_effects_label(value: float) -> void:
	pause_effects_value_label.text = str(int(round(value)))

func _update_pause_music_label(value: float) -> void:
	pause_music_value_label.text = str(int(round(value)))

# Сохраняет исходную громкость звуков удара для дальнейших вариаций.
func _store_sound_base_volumes() -> void:
	for player in hit_sound_players.values():
		player.set_meta("base_volume_db", player.volume_db)
	for player in ally_hit_sound_players.values():
		player.set_meta("base_volume_db", player.volume_db)
	snow_sound.set_meta("base_volume_db", snow_sound.volume_db)
	combo_break_sound.set_meta("base_volume_db", combo_break_sound.volume_db)
	bomb_explosion_sound.set_meta("base_volume_db", bomb_explosion_sound.volume_db)
	music.set_meta("base_volume_db", music.volume_db)

# Проигрывает дополнительный звук взрыва бомбы в точке попадания.
func _play_bomb_explosion_sound(at_position: Vector2) -> void:
	if bomb_explosion_sound == null or bomb_explosion_sound.stream == null:
		return

	var explosion_player := AudioStreamPlayer2D.new()
	explosion_player.stream = bomb_explosion_sound.stream
	explosion_player.bus = bomb_explosion_sound.bus
	var base_volume_db := float(bomb_explosion_sound.get_meta("base_volume_db", bomb_explosion_sound.volume_db))
	explosion_player.volume_db = GameSettings.get_sfx_player_volume_db(base_volume_db, current_effects_volume)
	explosion_player.pitch_scale = randf_range(0.98, 1.03)
	explosion_player.global_position = at_position
	add_child(explosion_player)
	explosion_player.finished.connect(explosion_player.queue_free)
	explosion_player.play()

# Проигрывает звук попадания с вариацией тона и дополнительным слоем для плотности.
func _play_impact_sound(player: AudioStreamPlayer2D, volume_boost: float, pitch_min: float, pitch_max: float, add_layer: bool) -> void:
	if player == null:
		return

	var base_volume := float(player.get_meta("base_volume_db", player.volume_db))
	var effective_base_volume := GameSettings.get_sfx_player_volume_db(base_volume, current_effects_volume)
	player.stop()
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.volume_db = effective_base_volume + volume_boost
	player.play()

	if not add_layer or player.stream == null:
		return

	var layer := AudioStreamPlayer2D.new()
	layer.stream = player.stream
	layer.bus = player.bus
	layer.volume_db = effective_base_volume + volume_boost - 4.0
	layer.pitch_scale = player.pitch_scale * randf_range(0.9, 0.96)
	layer.global_position = player.global_position
	add_child(layer)
	layer.finished.connect(layer.queue_free)
	layer.play()

# Подготавливает игровую сцену, подключает сигналы и запускает игровые циклы.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var settings := GameSettings.load_settings()
	GameSettings.apply_settings(settings)
	_fit_background_to_base_viewport()
	_store_sound_base_volumes()
	_apply_effects_volume_from_settings(settings)
	_apply_music_volume_from_settings(settings)
	music.play()
	update_timer()
	start_timer()

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	aim.modulate = Color(1.0, 1.0, 1.0, 1.0)
	bow_base_position = bow.position
	bow_base_scale = bow.scale
	_setup_higan_throw_animation()
	shot_flash.scale = Vector2.ONE
	shot_flash.modulate.a = 0.0
	shot_flash_core.scale = Vector2.ONE
	shot_flash_core.modulate.a = 0.0
	combo_label.visible = false

	randomize()
	_schedule_next_ufo_spawn_time()

	for enemy_node in enemies:
		_store_sprite_base_scale(_get_enemy_sprite(enemy_node))
		_ensure_sprite_outline(_get_enemy_sprite(enemy_node), ENEMY_OUTLINE_COLOR)
		_sync_enemy_hitbox(enemy_node)
		enemy_node.input_pickable = true
		enemy_node.set_meta("pending_hit", false)
		enemy_node.input_event.connect(_on_enemy_clicked.bind(enemy_node))

	_store_sprite_base_scale(_get_enemy_sprite(snow))
	_ensure_sprite_outline(_get_enemy_sprite(snow), ENEMY_OUTLINE_COLOR)
	_sync_enemy_hitbox(snow)
	snow.hide()
	snow.input_pickable = true
	snow.input_event.connect(_on_ufo_clicked)

	for ally in allies:
		ally.hide()
		ally.input_pickable = true
		_store_sprite_base_scale(_get_ally_sprite(ally))
		_ensure_sprite_outline(_get_ally_sprite(ally), ALLY_OUTLINE_COLOR)
		_sync_ally_hitbox(ally)
		ally.input_event.connect(_on_ally_clicked.bind(ally))

	pause_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	resume_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	back_to_menu_button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_effects_slider.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_music_slider.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_overlay.visible = false
	resume_button.pressed.connect(_on_resume_button_pressed)
	back_to_menu_button.pressed.connect(_on_back_to_menu_button_pressed)
	pause_effects_slider.value_changed.connect(_on_pause_effects_changed)
	pause_music_slider.value_changed.connect(_on_pause_music_changed)
	_load_pause_volume_settings()
	_setup_pause_button_hover_shake()

# Вписывает игровой фон целиком в базовый размер сцены без обрезки краев.
func _fit_background_to_base_viewport() -> void:
	if background_sprite == null or background_sprite.texture == null:
		return

	var texture_size: Vector2 = background_sprite.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var scale_x: float = BASE_VIEWPORT_SIZE.x / texture_size.x
	var scale_y: float = BASE_VIEWPORT_SIZE.y / texture_size.y
	var cover_scale: float = max(scale_x, scale_y)
	background_sprite.centered = true
	background_sprite.position = BASE_VIEWPORT_SIZE * 0.5
	background_sprite.scale = Vector2.ONE * cover_scale

	change_enemy()
	change_ally()

# Назначает следующее допустимое время появления НЛО через случайный интервал.
func _schedule_next_ufo_spawn_time() -> void:
	next_ufo_spawn_time = _get_current_time_seconds() + randf_range(UFO_SPAWN_DELAY_MIN, UFO_SPAWN_DELAY_MAX)

# Возвращает текущее время в секундах для тайминга появления НЛО.
func _get_current_time_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0

# Обновляет прицел, поворот лука и анимацию НЛО каждый кадр.
func _process(delta: float) -> void:
	if get_tree().paused:
		_update_pause_button_hover_shake()
		return

	update_score()
	_update_ufo(delta)
	_update_combo_visual(delta)
	_update_combo_timeout()

	var mouse_pos = get_viewport().get_mouse_position()
	aim.global_position = mouse_pos
	bow.position = bow_base_position + bow_recoil_offset

# Обрабатывает паузу и выстрел левой кнопкой мыши.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_toggle_pause()
		return

	if get_tree().paused:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var now = Time.get_ticks_msec() / 1000.0
		if now < next_shot_time:
			return
		next_shot_time = now + SHOOT_COOLDOWN
		var click_target_type := _classify_click_target(event.position)
		shoot()
		click_sound.play()
		_play_bow_shot_feedback()
		if click_target_type == "empty":
			_break_combo()

# Создает стрелу в центре лука и отправляет ее к точке клика.
func shoot() -> void:
	var arrow = arrow_scene.instantiate()
	var mouse_pos = get_viewport().get_mouse_position()
	aim.global_position = mouse_pos
	arrow.global_position = bow.global_position
	arrow.speed = ARROW_SPEED
	arrow.target_position = mouse_pos
	get_tree().current_scene.add_child(arrow)

# Собирает одноразовую анимацию броска Хиган из PNG-кадров внутри проекта.
func _setup_higan_throw_animation() -> void:
	if higan_throw_animation == null:
		return
	if HIGAN_THROW_FRAMES.is_empty():
		return

	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation(HIGAN_THROW_ANIMATION_NAME)
	sprite_frames.set_animation_loop(HIGAN_THROW_ANIMATION_NAME, false)
	sprite_frames.set_animation_speed(HIGAN_THROW_ANIMATION_NAME, HIGAN_THROW_ANIMATION_FPS)

	for texture in HIGAN_THROW_FRAMES:
		if texture != null:
			sprite_frames.add_frame(HIGAN_THROW_ANIMATION_NAME, texture)

	if sprite_frames.get_frame_count(HIGAN_THROW_ANIMATION_NAME) == 0:
		return

	higan_throw_animation.sprite_frames = sprite_frames
	higan_throw_animation.animation = HIGAN_THROW_ANIMATION_NAME
	_sync_higan_throw_animation_to_frame()
	higan_throw_animation.stop()
	higan_throw_animation.frame = 0
	if not higan_throw_animation.animation_finished.is_connected(_on_higan_throw_animation_finished):
		higan_throw_animation.animation_finished.connect(_on_higan_throw_animation_finished)

# Подгоняет анимацию Хиган под рамку на сцене, чтобы ее было удобно настроить вручную.
func _sync_higan_throw_animation_to_frame() -> void:
	if higan_throw_frame == null or higan_throw_animation == null or higan_throw_animation.sprite_frames == null:
		return
	if higan_throw_animation.sprite_frames.get_frame_count(HIGAN_THROW_ANIMATION_NAME) == 0:
		return

	var first_frame := higan_throw_animation.sprite_frames.get_frame_texture(HIGAN_THROW_ANIMATION_NAME, 0)
	if first_frame == null:
		return

	var source_size: Vector2 = first_frame.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return

	var target_size: Vector2 = higan_throw_frame.size
	var scale_factor: float = min(target_size.x / source_size.x, target_size.y / source_size.y)
	higan_throw_animation.scale = Vector2.ONE * scale_factor
	higan_throw_animation.position = higan_throw_frame.position + (target_size / 2.0)

# Проигрывает короткий откат лука и вспышку при выстреле.
func _play_bow_shot_feedback() -> void:
	var recoil_direction = (bow.global_position - aim.global_position).normalized()
	bow_recoil_offset = recoil_direction * 12.0
	bow.scale = Vector2(bow_base_scale.x * 0.94, bow_base_scale.y * 1.04)
	if higan_throw_animation != null and higan_throw_animation.sprite_frames != null:
		higan_throw_animation.stop()
		higan_throw_animation.frame = 0
		higan_throw_animation.play(HIGAN_THROW_ANIMATION_NAME)

	shot_flash.visible = true
	shot_flash.modulate = Color(1.0, 0.97, 0.72, 1.0)
	shot_flash.scale = Vector2(1.6, 1.2)
	shot_flash_core.visible = true
	shot_flash_core.modulate = Color(1.0, 1.0, 0.94, 1.0)
	shot_flash_core.scale = Vector2(1.35, 1.0)

	var bow_tween = create_tween()
	bow_tween.set_parallel(true)
	bow_tween.tween_property(self, "bow_recoil_offset", Vector2.ZERO, 0.1)
	bow_tween.tween_property(bow, "scale", bow_base_scale, 0.1)

	var flash_tween = create_tween()
	flash_tween.set_parallel(true)
	flash_tween.tween_property(shot_flash, "scale", Vector2(2.6, 0.85), 0.1)
	flash_tween.tween_property(shot_flash, "modulate:a", 0.0, 0.1)
	flash_tween.tween_callback(func() -> void:
		shot_flash.visible = false
		shot_flash.scale = Vector2.ONE
	)

	var core_flash_tween = create_tween()
	core_flash_tween.set_parallel(true)
	core_flash_tween.tween_property(shot_flash_core, "scale", Vector2(2.2, 0.7), 0.06)
	core_flash_tween.tween_property(shot_flash_core, "modulate:a", 0.0, 0.06)
	core_flash_tween.tween_callback(func() -> void:
		shot_flash_core.visible = false
		shot_flash_core.scale = Vector2.ONE
	)

# Возвращает Хиган в стартовую позу после завершения анимации броска.
func _on_higan_throw_animation_finished() -> void:
	if higan_throw_animation == null:
		return
	higan_throw_animation.stop()
	higan_throw_animation.frame = 0

# Возвращает спрайт выбранного союзника по имени узла.
func _get_ally_sprite(ally: Area2D) -> Sprite2D:
	return ally.get_node(ALLY_NODE_PATHS[ally.name]["sprite"])

# Возвращает коллизию выбранного союзника по имени узла.
func _get_ally_collision_shape(ally: Area2D) -> CollisionShape2D:
	return ally.get_node(ALLY_NODE_PATHS[ally.name]["collision"])

# Возвращает спрайт выбранного врага по имени узла.
func _get_enemy_sprite(enemy_node: Area2D) -> Sprite2D:
	return enemy_node.get_node(ENEMY_NODE_PATHS[enemy_node.name]["sprite"])

# Возвращает коллизию выбранного врага по имени узла.
func _get_enemy_collision_shape(enemy_node: Area2D) -> CollisionShape2D:
	return enemy_node.get_node(ENEMY_NODE_PATHS[enemy_node.name]["collision"])

# Сохраняет базовый scale спрайта из сцены, чтобы случайный множитель не ломал ручной размер.
func _store_sprite_base_scale(sprite: Sprite2D) -> void:
	if sprite == null:
		return
	sprite.set_meta("base_scale", sprite.scale)

func _setup_pause_button_hover_shake() -> void:
	_register_pause_button_label(resume_button_label)
	_register_pause_button_label(back_to_menu_button_label)
	resume_button.mouse_entered.connect(_on_pause_button_mouse_entered.bind(resume_button, resume_button_label))
	resume_button.mouse_exited.connect(_on_pause_button_mouse_exited.bind(resume_button_label))
	back_to_menu_button.mouse_entered.connect(_on_pause_button_mouse_entered.bind(back_to_menu_button, back_to_menu_button_label))
	back_to_menu_button.mouse_exited.connect(_on_pause_button_mouse_exited.bind(back_to_menu_button_label))

func _register_pause_button_label(label: Label) -> void:
	if label == null or pause_button_label_base_offsets.has(label):
		return

	pause_button_label_base_offsets[label] = {
		"left": label.offset_left,
		"right": label.offset_right,
		"top": label.offset_top,
		"bottom": label.offset_bottom
	}

func _on_pause_button_mouse_entered(button: Button, label: Label) -> void:
	if button == null or label == null or button.disabled:
		return
	hovered_pause_button_labels[label] = true

func _on_pause_button_mouse_exited(label: Label) -> void:
	if label == null:
		return
	hovered_pause_button_labels.erase(label)
	_restore_pause_button_label_offsets(label)

func _update_pause_button_hover_shake() -> void:
	if hovered_pause_button_labels.is_empty():
		return

	var time_value: float = Time.get_ticks_msec() / 1000.0
	for label_variant in hovered_pause_button_labels.keys():
		var label := label_variant as Label
		if label == null:
			continue
		var x_offset: float = sin(time_value * PAUSE_BUTTON_SHAKE_SPEED) * PAUSE_BUTTON_SHAKE_OFFSET
		var y_offset: float = cos(time_value * (PAUSE_BUTTON_SHAKE_SPEED - 4.0)) * PAUSE_BUTTON_SHAKE_OFFSET
		_apply_pause_button_label_offset(label, Vector2(x_offset, y_offset))

func _restore_pause_button_label_offsets(label: Label) -> void:
	var base_offsets: Dictionary = pause_button_label_base_offsets.get(label, {})
	if base_offsets.is_empty():
		return

	label.offset_left = float(base_offsets.get("left", label.offset_left))
	label.offset_right = float(base_offsets.get("right", label.offset_right))
	label.offset_top = float(base_offsets.get("top", label.offset_top))
	label.offset_bottom = float(base_offsets.get("bottom", label.offset_bottom))

func _apply_pause_button_label_offset(label: Label, offset: Vector2) -> void:
	var base_offsets: Dictionary = pause_button_label_base_offsets.get(label, {})
	if base_offsets.is_empty():
		return

	label.offset_left = float(base_offsets.get("left", label.offset_left)) + offset.x
	label.offset_right = float(base_offsets.get("right", label.offset_right)) + offset.x
	label.offset_top = float(base_offsets.get("top", label.offset_top)) + offset.y
	label.offset_bottom = float(base_offsets.get("bottom", label.offset_bottom)) + offset.y

func _ensure_sprite_outline(sprite: Sprite2D, outline_color: Color) -> void:
	if sprite == null or sprite.texture == null:
		return

	var parent := sprite.get_parent()
	if parent == null:
		return

	var outline := parent.get_node_or_null("%sOutline" % sprite.name) as Sprite2D
	if outline == null:
		outline = Sprite2D.new()
		outline.name = "%sOutline" % sprite.name
		outline.texture = sprite.texture
		outline.centered = sprite.centered
		outline.offset = sprite.offset
		outline.hframes = sprite.hframes
		outline.vframes = sprite.vframes
		outline.frame = sprite.frame
		outline.frame_coords = sprite.frame_coords
		outline.z_index = sprite.z_index + OUTLINE_Z_OFFSET
		outline.z_as_relative = sprite.z_as_relative
		outline.show_behind_parent = true
		var material := ShaderMaterial.new()
		material.shader = SPRITE_OUTLINE_SHADER
		material.set_shader_parameter("solid_color", outline_color)
		outline.material = material
		parent.add_child(outline)
		parent.move_child(outline, sprite.get_index())

	_sync_sprite_outline(sprite)

func _sync_sprite_outline(sprite: Sprite2D) -> void:
	if sprite == null:
		return

	var parent := sprite.get_parent()
	if parent == null:
		return

	var outline := parent.get_node_or_null("%sOutline" % sprite.name) as Sprite2D
	if outline == null:
		return

	outline.texture = sprite.texture
	outline.position = sprite.position
	outline.rotation = sprite.rotation
	outline.scale = sprite.scale * OUTLINE_SCALE_MULTIPLIER
	outline.flip_h = sprite.flip_h
	outline.flip_v = sprite.flip_v
	outline.visible = sprite.visible
	outline.modulate = Color.WHITE

# Подгоняет хитбокс союзника под текущий размер его спрайта.
func _sync_ally_hitbox(ally: Area2D) -> void:
	var sprite := _get_ally_sprite(ally)
	var collision_shape := _get_ally_collision_shape(ally)
	if sprite == null or collision_shape == null:
		return

	sprite.position = Vector2.ZERO
	collision_shape.position = Vector2.ZERO
	_sync_sprite_outline(sprite)

	if collision_shape.shape is RectangleShape2D and sprite.texture != null:
		var rectangle_shape := collision_shape.shape as RectangleShape2D
		rectangle_shape.extents = (sprite.texture.get_size() * sprite.scale) / 2.0

# Подгоняет хитбокс врага под текущий размер его спрайта.
func _sync_enemy_hitbox(enemy_node: Area2D) -> void:
	var sprite := _get_enemy_sprite(enemy_node)
	var collision_shape := _get_enemy_collision_shape(enemy_node)
	if sprite == null or collision_shape == null:
		return

	sprite.position = Vector2.ZERO
	collision_shape.position = Vector2.ZERO
	_sync_sprite_outline(sprite)

	if collision_shape.shape is RectangleShape2D and sprite.texture != null:
		var rectangle_shape := collision_shape.shape as RectangleShape2D
		rectangle_shape.extents = (sprite.texture.get_size() * sprite.scale) / 2.0

# Показывает одного или двух случайных врагов и расставляет их по экрану.
func _spawn_random_enemy() -> void:
	for enemy_node in enemies:
		enemy_node.hide()
		enemy_node.set_meta("pending_hit", false)

	var enemy_count := 1
	if score >= DOUBLE_ENEMY_SCORE_THRESHOLD and randf() < DOUBLE_ENEMY_CHANCE:
		enemy_count = 2

	var available_enemies: Array = enemies.duplicate()
	available_enemies.shuffle()
	var occupied_positions: Array = []

	for i in range(min(enemy_count, available_enemies.size())):
		var enemy_node: Area2D = available_enemies[i]
		var sprite := _get_enemy_sprite(enemy_node)
		enemy_node.show()

		var random_scale = randf_range(0.5, 1.5)
		var base_scale: Vector2 = sprite.get_meta("base_scale", sprite.scale)
		sprite.scale = base_scale * random_scale
		_sync_enemy_hitbox(enemy_node)

		var sprite_size = sprite.texture.get_size() * sprite.scale
		var half_size = sprite_size / 2.0
		var chosen_position := Vector2.ZERO
		var found_position := false

		for _attempt in range(12):
			var candidate = Vector2(
				randf_range(half_size.x, BASE_VIEWPORT_SIZE.x - half_size.x),
				randf_range(half_size.y, BASE_VIEWPORT_SIZE.y - half_size.y)
			)
			var overlaps_existing := false

			for occupied_position in occupied_positions:
				if candidate.distance_to(occupied_position) < max(sprite_size.x, sprite_size.y):
					overlaps_existing = true
					break

			if _is_spawn_blocked_by_higan(candidate, sprite_size):
				overlaps_existing = true

			if not overlaps_existing:
				chosen_position = candidate
				found_position = true
				break

		if not found_position:
			for _fallback_attempt in range(12):
				var fallback_candidate := Vector2(
					randf_range(half_size.x, BASE_VIEWPORT_SIZE.x - half_size.x),
					randf_range(half_size.y, BASE_VIEWPORT_SIZE.y - half_size.y)
				)
				if not _is_spawn_blocked_by_higan(fallback_candidate, sprite_size):
					chosen_position = fallback_candidate
					found_position = true
					break

		if not found_position:
			chosen_position = Vector2(
				clampf(half_size.x + HIGAN_SPAWN_BLOCK_PADDING, half_size.x, BASE_VIEWPORT_SIZE.x - half_size.x),
				clampf(BASE_VIEWPORT_SIZE.y * 0.35, half_size.y, BASE_VIEWPORT_SIZE.y - half_size.y)
			)

		enemy_node.global_position = chosen_position
		occupied_positions.append(chosen_position)

# Показывает случайного союзника в случайной точке экрана.
func spawn_ally() -> Area2D:
	for ally in allies:
		ally.hide()

	var ally: Area2D = allies.pick_random()
	var sprite: Sprite2D = _get_ally_sprite(ally)
	var random_scale = randf_range(0.3, 1.5)
	var base_scale: Vector2 = sprite.get_meta("base_scale", sprite.scale)
	sprite.scale = base_scale * random_scale
	_sync_ally_hitbox(ally)

	var sprite_size: Vector2 = sprite.texture.get_size() * sprite.scale
	var half_size: Vector2 = sprite_size / 2.0
	var chosen_position: Vector2 = Vector2.ZERO
	var found_position: bool = false

	for _attempt in range(12):
		var candidate: Vector2 = Vector2(
			randf_range(half_size.x, BASE_VIEWPORT_SIZE.x - half_size.x),
			randf_range(half_size.y, BASE_VIEWPORT_SIZE.y - half_size.y)
		)
		if not _is_spawn_blocked_by_higan(candidate, sprite_size):
			chosen_position = candidate
			found_position = true
			break

	if not found_position:
		chosen_position = Vector2(
			clampf(half_size.x + HIGAN_SPAWN_BLOCK_PADDING, half_size.x, BASE_VIEWPORT_SIZE.x - half_size.x),
			clampf(BASE_VIEWPORT_SIZE.y * 0.7, half_size.y, BASE_VIEWPORT_SIZE.y - half_size.y)
		)

	ally.global_position = chosen_position
	ally.show()
	return ally

func _get_higan_spawn_block_rect() -> Rect2:
	if higan_throw_frame == null:
		return Rect2()

	var block_rect := higan_throw_frame.get_global_rect()
	return block_rect.grow(HIGAN_SPAWN_BLOCK_PADDING)

func _is_spawn_blocked_by_higan(candidate_position: Vector2, sprite_size: Vector2) -> bool:
	var block_rect := _get_higan_spawn_block_rect()
	if block_rect.size.x <= 0.0 or block_rect.size.y <= 0.0:
		return false

	var sprite_rect := Rect2(candidate_position - (sprite_size / 2.0), sprite_size)
	return sprite_rect.intersects(block_rect)

# Создает эффект кровавого всплеска в точке попадания.
func _spawn_blood_splash(at_position: Vector2) -> void:
	var bomb_explosion = BombExplosionScene.instantiate()
	bomb_explosion.global_position = at_position
	add_child(bomb_explosion)

# Показывает всплывающий текст с количеством полученных очков.
func _spawn_floating_score(value: int, at_position: Vector2, value_color: Color) -> void:
	var floating_score = FloatingScoreScene.new()
	var prefix = "+"
	if value < 0:
		prefix = ""
	floating_score.setup("%s%d" % [prefix, value], value_color)
	floating_score.global_position = at_position + Vector2(-50.0, -24.0)
	add_child(floating_score)

# Определяет, попал ли клик по врагу, союзнику, НЛО или в пустоту.
func _classify_click_target(screen_position: Vector2) -> String:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = screen_position
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var results := get_world_2d().direct_space_state.intersect_point(query)

	for result in results:
		var collider = result.get("collider")
		if collider == null:
			continue
		if collider == snow:
			return "snow"
		if collider in enemies:
			return "enemy"
		if collider in allies:
			return "ally"

	return "empty"

# Возвращает текущий множитель серии попаданий.
func _get_combo_multiplier() -> int:
	return 1 + int(combo_hits / COMBO_STEP)

# Обновляет надпись с текущим множителем комбо.
func _update_combo_label() -> void:
	var multiplier = _get_combo_multiplier()
	combo_label.visible = multiplier > 1
	if combo_label.visible:
		combo_label.text = "COMBO: X%d" % multiplier
		combo_label.scale = Vector2.ONE
		_apply_combo_visual(multiplier, 0.0)

# Увеличивает серию попаданий по врагам и обновляет комбо.
func _register_combo_hit() -> void:
	combo_hits += 1
	combo_last_hit_time = Time.get_ticks_msec() / 1000.0
	_update_combo_label()

# Сбрасывает серию попаданий и проигрывает звук ошибки.
func _break_combo(play_sound: bool = true) -> void:
	if combo_hits <= 0:
		return
	combo_hits = 0
	combo_last_hit_time = -1.0
	_update_combo_label()
	if play_sound:
		_play_impact_sound(combo_break_sound, 0.0, 0.98, 1.02, false)

# Сбрасывает комбо, если игрок слишком долго не попадал по врагам.
func _update_combo_timeout() -> void:
	if combo_hits <= 0 or combo_last_hit_time < 0.0:
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	if now - combo_last_hit_time >= COMBO_TIMEOUT:
		_break_combo()

# Возвращает цвет надписи комбо для текущего множителя.
func _get_combo_color(multiplier: int, time_seconds: float) -> Color:
	if multiplier >= 15:
		var hue := fmod(time_seconds * 0.35, 1.0)
		return Color.from_hsv(hue, 0.75, 1.0, 1.0)
	if multiplier >= 12:
		return COMBO_CYAN_COLOR
	if multiplier >= 9:
		return COMBO_VIOLET_COLOR
	if multiplier >= 6:
		return COMBO_RED_COLOR
	if multiplier >= 3:
		return COMBO_YELLOW_COLOR
	return COMBO_BASE_COLOR

# Применяет цвет и обводку к надписи комбо с учетом силы серии.
func _apply_combo_visual(multiplier: int, pulse: float) -> void:
	var combo_color := _get_combo_color(multiplier, Time.get_ticks_msec() / 1000.0)
	var outline_mix: float = clamp(float(multiplier - 1) / 14.0, 0.0, 1.0)
	var outline_color := COMBO_OUTLINE_BASE_COLOR.lerp(COMBO_OUTLINE_HOT_COLOR, outline_mix)
	combo_label.add_theme_color_override("font_color", combo_color.lightened(pulse * 0.18))
	combo_label.add_theme_color_override("font_outline_color", outline_color)

# Анимирует надпись комбо: пульс, смену цвета и перелив на высоких множителях.
func _update_combo_visual(_delta: float) -> void:
	if not combo_label.visible:
		return

	var multiplier := _get_combo_multiplier()
	var time_seconds := Time.get_ticks_msec() / 1000.0
	var pulse := (sin(time_seconds * 8.0) + 1.0) * 0.5
	var scale_boost := 0.02

	if multiplier >= 3:
		scale_boost = 0.04
	if multiplier >= 6:
		scale_boost = 0.055
	if multiplier >= 9:
		scale_boost = 0.07
	if multiplier >= 12:
		scale_boost = 0.085
	if multiplier >= 15:
		scale_boost = 0.11

	combo_label.scale = Vector2.ONE * (1.0 + pulse * scale_boost)
	_apply_combo_visual(multiplier, pulse)

# Проверяет, есть ли враги с ожидающим попаданием стрелы.
func _has_pending_enemy_hits() -> bool:
	for enemy_node in enemies:
		if enemy_node.has_meta("pending_hit") and enemy_node.get_meta("pending_hit"):
			return true
	return false

# Добавляет бонусное время за каждые 50 убитых врагов.
func _register_enemy_kill() -> void:
	enemies_killed += 1
	if enemies_killed % BONUS_TIME_KILL_STEP == 0:
		time_left += BONUS_TIME_SECONDS
		update_timer()

# Завершает попадание по врагу, начисляет очки и убирает цель.
func _resolve_enemy_hit(enemy_node: Area2D, impact_position: Vector2) -> void:
	if not is_instance_valid(enemy_node):
		return

	enemy_node.set_meta("pending_hit", false)
	if not enemy_node.visible:
		return
	click_sound.stop()

	_register_combo_hit()
	var enemy_score = int(ENEMY_SCORES.get(enemy_node.name, 0))
	var awarded_score = enemy_score * _get_combo_multiplier()
	score += awarded_score
	score_label.text = str(score)

	var player = hit_sound_players.get(enemy_node.name)
	if player:
		_play_impact_sound(player, 5.0, 0.9, 1.04, true)
	_play_bomb_explosion_sound(impact_position)

	_register_enemy_kill()
	_spawn_blood_splash(impact_position)
	_spawn_floating_score(awarded_score, impact_position, ENEMY_SCORE_COLOR)
	enemy_node.hide()

# Помечает врага на попадание и считает задержку до прилета стрелы.
func _schedule_enemy_hit(enemy_node: Area2D, impact_position: Vector2) -> void:
	if enemy_node.has_meta("pending_hit") and enemy_node.get_meta("pending_hit"):
		return

	enemy_node.set_meta("pending_hit", true)
	var delay = bow.global_position.distance_to(impact_position) / ARROW_SPEED
	_resolve_enemy_hit_after_delay(enemy_node, impact_position, delay)

# Дожидается прилета стрелы и завершает попадание по врагу.
func _resolve_enemy_hit_after_delay(enemy_node: Area2D, impact_position: Vector2, delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	_resolve_enemy_hit(enemy_node, impact_position)

# Обновляет текст таймера в формате минут и секунд.
func update_timer() -> void:
	var minutes = time_left / 60
	var seconds = time_left % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

# Обновляет счет на экране и проверяет пороги появления НЛО.
func update_score() -> void:
	score_label.text = str(score)
	_queue_ufo_flights_if_needed()

# Запускает отсчет времени раунда до конца игры.
func start_timer() -> void:
	while time_left > 0:
		await get_tree().create_timer(1.0, false).timeout
		time_left -= 1
		update_timer()
	game_over()

# Завершает игру и передает итоговый счет на экран рекордов.
func game_over() -> void:
	get_tree().paused = false
	get_tree().set_meta("last_score", score)
	get_tree().set_meta("pending_score", score)
	get_tree().change_scene_to_file("res://leaderboard.tscn")

# Запускает бесконечный цикл появления врагов во время раунда.
func change_enemy() -> void:
	while true:
		while _has_pending_enemy_hits():
			await get_tree().create_timer(0.05, false).timeout
		_spawn_random_enemy()
		var wait_time = randf_range(0.7, 1.5)
		await get_tree().create_timer(wait_time, false).timeout

# Запускает бесконечный цикл случайного появления союзников.
func change_ally() -> void:
	while true:
		var spawn_wait_time = randf_range(10.0, 15.0)
		await get_tree().create_timer(spawn_wait_time, false).timeout
		var ally := spawn_ally()
		var visible_time = randf_range(2.0, 3.0)
		await get_tree().create_timer(visible_time, false).timeout
		if ally != null:
			ally.hide()

# Добавляет в очередь новые вылеты НЛО после достижения нужного счета.
func _queue_ufo_flights_if_needed() -> void:
	while score >= next_ufo_score_threshold:
		queued_ufo_flight_durations.append(_get_ufo_flight_duration_for_threshold(next_ufo_score_threshold))
		next_ufo_score_threshold = _get_next_ufo_threshold(next_ufo_score_threshold)

# Возвращает следующий порог появления НЛО после текущего.
func _get_next_ufo_threshold(current_threshold: int) -> int:
	match current_threshold:
		5000:
			return 10000
		10000:
			return 20000
		20000:
			return 40000
		40000:
			return 80000
		_:
			return current_threshold + 100000

# Возвращает длительность пролета НЛО для конкретного порога счета.
func _get_ufo_flight_duration_for_threshold(threshold: int) -> float:
	match threshold:
		5000:
			return 2.0
		10000:
			return 1.8
		20000:
			return 1.6
		40000:
			return 1.4
		_:
			var extra_steps: int = max(int((threshold - 80000) / 100000), 0)
			return max(1.2 - float(extra_steps) * 0.2, UFO_MIN_FLIGHT_DURATION)

# Запускает полет НЛО из одного верхнего угла в другой.
func _start_ufo_flight() -> void:
	if ufo_active or queued_ufo_flight_durations.is_empty():
		return

	var sprite := _get_enemy_sprite(snow)
	var sprite_size = sprite.texture.get_size() * sprite.scale
	var half_size = sprite_size / 2.0
	var top_y = half_size.y + 24.0
	var bottom_y = BASE_VIEWPORT_SIZE.y - half_size.y - 24.0
	var left_x = half_size.x + 24.0
	var right_x = BASE_VIEWPORT_SIZE.x - half_size.x - 24.0
	var start_from_left := randf() < 0.5
	snow_top_limit_y = top_y
	snow_bottom_limit_y = min(top_y + SNOW_VERTICAL_LIMIT_FROM_TOP, bottom_y)
	snow_vertical_direction = -1.0 if randf() < 0.5 else 1.0
	snow_vertical_segment_remaining = randf_range(SNOW_FLAP_SEGMENT_MIN, SNOW_FLAP_SEGMENT_MAX)
	snow_vertical_speed = randf_range(SNOW_VERTICAL_SPEED_MIN, SNOW_VERTICAL_SPEED_MAX)

	if start_from_left:
		ufo_start_position.x = left_x
		ufo_end_position.x = right_x
	else:
		ufo_start_position.x = right_x
		ufo_end_position.x = left_x

	var start_y := randf_range(snow_top_limit_y, snow_bottom_limit_y)
	ufo_start_position.y = start_y
	ufo_end_position.y = start_y

	# Оставляем Snow как есть при полете слева направо и зеркалим при полете справа налево.
	sprite.flip_h = not start_from_left
	_sync_sprite_outline(sprite)

	snow.global_position = ufo_start_position
	ufo_flight_progress = 0.0
	current_ufo_flight_duration = float(queued_ufo_flight_durations.pop_front())
	ufo_active = true
	_schedule_next_ufo_spawn_time()
	snow.show()
	snow_sound.play()

# Останавливает полет НЛО и скрывает его со сцены.
func _hide_ufo() -> void:
	ufo_active = false
	snow.hide()
	snow_sound.stop()

# Обновляет положение НЛО во время его перелета через экран.
func _update_ufo(delta: float) -> void:
	if not ufo_active:
		if not queued_ufo_flight_durations.is_empty() and _get_current_time_seconds() >= next_ufo_spawn_time:
			_start_ufo_flight()
		return

	ufo_flight_progress += delta / current_ufo_flight_duration
	var weight: float = min(ufo_flight_progress, 1.0)
	var x_position: float = lerp(ufo_start_position.x, ufo_end_position.x, weight)
	var vertical_step: float = snow_vertical_direction * snow_vertical_speed * delta
	var y_position: float = snow.global_position.y + vertical_step
	snow_vertical_segment_remaining -= abs(vertical_step)

	if y_position <= snow_top_limit_y:
		y_position = snow_top_limit_y
		snow_vertical_direction = 1.0
		snow_vertical_segment_remaining = randf_range(SNOW_FLAP_SEGMENT_MIN, SNOW_FLAP_SEGMENT_MAX)
	elif y_position >= snow_bottom_limit_y:
		y_position = snow_bottom_limit_y
		snow_vertical_direction = -1.0
		snow_vertical_segment_remaining = randf_range(SNOW_FLAP_SEGMENT_MIN, SNOW_FLAP_SEGMENT_MAX)
	elif snow_vertical_segment_remaining <= 0.0:
		snow_vertical_direction *= -1.0
		snow_vertical_segment_remaining = randf_range(SNOW_FLAP_SEGMENT_MIN, SNOW_FLAP_SEGMENT_MAX)

	snow.global_position = Vector2(x_position, y_position)

	if ufo_flight_progress >= 1.0:
		_hide_ufo()

# Обрабатывает клик по врагу и запускает отложенное попадание стрелы.
func _on_enemy_clicked(_viewport, event: InputEvent, _shape_idx: int, enemy_node: Area2D) -> void:
	if event is InputEventMouseButton and event.pressed:
		_schedule_enemy_hit(enemy_node, event.position)

# Обрабатывает клик по союзнику и снимает очки с игрока.
func _on_ally_clicked(_viewport, event: InputEvent, _shape_idx: int, ally: Area2D) -> void:
	if event is InputEventMouseButton and event.pressed:
		_schedule_ally_hit(ally, event.position)

# Обрабатывает попадание по НЛО и выдает бонусные очки.
func _on_ufo_clicked(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and ufo_active:
		click_sound.stop()
		_register_combo_hit()
		var awarded_score = UFO_SCORE_BONUS * _get_combo_multiplier()
		score += awarded_score
		score_label.text = str(score)
		_play_impact_sound(snow_sound, -2.0, 0.95, 1.05, true)
		_spawn_floating_score(awarded_score, event.position, UFO_SCORE_COLOR)
		_hide_ufo()

# Завершает попадание по союзнику после долета бомбы и применяет штраф.
func _resolve_ally_hit(ally: Area2D, impact_position: Vector2) -> void:
	if not is_instance_valid(ally):
		return

	ally.set_meta("pending_hit", false)
	if not ally.visible:
		return
	click_sound.stop()

	_break_combo()
	var ally_score = int(ALLY_SCORES.get(ally.name, 0))
	score += ally_score
	score_label.text = str(score)

	var player = ally_hit_sound_players.get(ally.name)
	if player:
		_play_impact_sound(player, 3.5, 0.92, 1.02, false)
	_play_bomb_explosion_sound(impact_position)

	_spawn_blood_splash(impact_position)
	_spawn_floating_score(ally_score, impact_position, ALLY_SCORE_COLOR)
	ally.hide()

# Помечает союзника на попадание и считает задержку до прилета бомбы.
func _schedule_ally_hit(ally: Area2D, impact_position: Vector2) -> void:
	if ally.has_meta("pending_hit") and ally.get_meta("pending_hit"):
		return

	ally.set_meta("pending_hit", true)
	var delay: float = bow.global_position.distance_to(impact_position) / ARROW_SPEED
	_resolve_ally_hit_after_delay(ally, impact_position, delay)

# Дожидается прилета бомбы и завершает попадание по союзнику.
func _resolve_ally_hit_after_delay(ally: Area2D, impact_position: Vector2, delay: float) -> void:
	await get_tree().create_timer(delay, false).timeout
	_resolve_ally_hit(ally, impact_position)

# Переключает состояние паузы и режим курсора мыши.
func _toggle_pause() -> void:
	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	pause_overlay.visible = is_paused
	music.stream_paused = is_paused

	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

# Снимает паузу и возвращает игрока в матч.
func _on_resume_button_pressed() -> void:
	if not get_tree().paused:
		return
	_toggle_pause()

# Выходит из матча в главное меню из паузного окна.
func _on_back_to_menu_button_pressed() -> void:
	get_tree().paused = false
	pause_overlay.visible = false
	music.stream_paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://main_menu.tscn")
