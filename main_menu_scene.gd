extends Control

const GameSettings = preload("res://game_settings.gd")
const HIGAN_ANIMATION_NAME := &"idle"
const HIGAN_ANIMATION_FPS := 12.0
const HIGAN_ANIMATION_INTERVAL_MIN_SECONDS := 20.0
const HIGAN_ANIMATION_INTERVAL_MAX_SECONDS := 60.0
const MENU_BUTTON_SHAKE_OFFSET := 3.0
const MENU_BUTTON_SHAKE_SPEED := 26.0
const HIGAN_MENU_FRAMES: Array[Texture2D] = [
	preload("res://Images/higan_frames/видое с хиган_001.png"),
	preload("res://Images/higan_frames/видое с хиган_003.png"),
	preload("res://Images/higan_frames/видое с хиган_006.png"),
	preload("res://Images/higan_frames/видое с хиган_007.png"),	preload("res://Images/higan_frames/видое с хиган_010.png"),
	preload("res://Images/higan_frames/видое с хиган_011.png"),
	preload("res://Images/higan_frames/видое с хиган_012.png"),
	preload("res://Images/higan_frames/видое с хиган_013.png"),
	preload("res://Images/higan_frames/видое с хиган_014.png"),
	preload("res://Images/higan_frames/видое с хиган_015.png"),
	preload("res://Images/higan_frames/видое с хиган_016.png"),
	preload("res://Images/higan_frames/видое с хиган_023.png"),
	preload("res://Images/higan_frames/видое с хиган_024.png"),
	preload("res://Images/higan_frames/видое с хиган_025.png"),
	preload("res://Images/higan_frames/видое с хиган_026.png"),
	preload("res://Images/higan_frames/видое с хиган_034.png"),
	preload("res://Images/higan_frames/видое с хиган_035.png"),
	preload("res://Images/higan_frames/видое с хиган_036.png"),
	preload("res://Images/higan_frames/видое с хиган_037.png"),
	preload("res://Images/higan_frames/видое с хиган_038.png"),
	preload("res://Images/higan_frames/видое с хиган_039.png"),
	preload("res://Images/higan_frames/видое с хиган_045.png"),
	preload("res://Images/higan_frames/видое с хиган_046.png"),
	preload("res://Images/higan_frames/видое с хиган_047.png"),
	preload("res://Images/higan_frames/видое с хиган_049.png"),
	preload("res://Images/higan_frames/видое с хиган_050.png"),
	preload("res://Images/higan_frames/видое с хиган_051.png")
]

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var score_button: Button = $VBoxContainer/ScoreButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var start_button_label: Label = $VBoxContainer/StartButton/StartButtonLabel
@onready var score_button_label: Label = $VBoxContainer/ScoreButton/ScoreButtonLabel
@onready var options_button_label: Label = $VBoxContainer/OptionsButton/OptionsButtonLabel
@onready var exit_button_label: Label = $VBoxContainer/ExitButton/ExitButtonLabel
@onready var higan_menu_frame: ReferenceRect = $HiganMenuFrame
@onready var higan_menu_animation: AnimatedSprite2D = $HiganMenuAnimation

var button_label_map: Dictionary = {}
var button_label_base_offsets: Dictionary = {}
var hovered_button_labels: Dictionary = {}

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://root.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _ready() -> void:
	GameSettings.apply_settings(GameSettings.load_settings())
	randomize()
	score_button.pressed.connect(_on_score_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	_setup_button_hover_shake()
	_setup_higan_animation()
	_sync_higan_animation_to_frame()
	_show_higan_first_frame()
	_start_higan_animation_cycle()

func _process(_delta: float) -> void:
	_update_button_hover_shake()

func _setup_button_hover_shake() -> void:
	button_label_map = {
		start_button: start_button_label,
		score_button: score_button_label,
		options_button: options_button_label,
		exit_button: exit_button_label
	}

	for button_variant in button_label_map.keys():
		var button: Button = button_variant
		var label: Label = button_label_map[button]
		button_label_base_offsets[label] = {
			"left": label.offset_left,
			"top": label.offset_top,
			"right": label.offset_right,
			"bottom": label.offset_bottom
		}
		hovered_button_labels[label] = false
		if not button.mouse_entered.is_connected(_on_menu_button_mouse_entered.bind(label)):
			button.mouse_entered.connect(_on_menu_button_mouse_entered.bind(label))
		if not button.mouse_exited.is_connected(_on_menu_button_mouse_exited.bind(label)):
			button.mouse_exited.connect(_on_menu_button_mouse_exited.bind(label))

func _on_menu_button_mouse_entered(label: Label) -> void:
	hovered_button_labels[label] = true

func _on_menu_button_mouse_exited(label: Label) -> void:
	hovered_button_labels[label] = false
	_restore_button_label_offsets(label)

func _update_button_hover_shake() -> void:
	var time_seconds: float = Time.get_ticks_msec() / 1000.0

	for label_variant in hovered_button_labels.keys():
		var label: Label = label_variant
		if bool(hovered_button_labels[label]):
			var x_offset: float = sin(time_seconds * MENU_BUTTON_SHAKE_SPEED) * MENU_BUTTON_SHAKE_OFFSET
			var y_offset: float = cos(time_seconds * (MENU_BUTTON_SHAKE_SPEED * 0.87)) * (MENU_BUTTON_SHAKE_OFFSET * 0.55)
			_apply_button_label_offset(label, Vector2(x_offset, y_offset))
		else:
			_restore_button_label_offsets(label)

func _restore_button_label_offsets(label: Label) -> void:
	var base_offsets: Dictionary = button_label_base_offsets.get(label, {})
	if base_offsets.is_empty():
		return

	label.offset_left = float(base_offsets["left"])
	label.offset_top = float(base_offsets["top"])
	label.offset_right = float(base_offsets["right"])
	label.offset_bottom = float(base_offsets["bottom"])

func _apply_button_label_offset(label: Label, offset: Vector2) -> void:
	var base_offsets: Dictionary = button_label_base_offsets.get(label, {})
	if base_offsets.is_empty():
		return

	label.offset_left = float(base_offsets["left"]) + offset.x
	label.offset_top = float(base_offsets["top"]) + offset.y
	label.offset_right = float(base_offsets["right"]) + offset.x
	label.offset_bottom = float(base_offsets["bottom"]) + offset.y

func _on_score_button_pressed() -> void:
	get_tree().change_scene_to_file("res://leaderboard.tscn")

func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file("res://options.tscn")

func _setup_higan_animation() -> void:
	if higan_menu_animation == null:
		return
	if HIGAN_MENU_FRAMES.is_empty():
		return

	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation(HIGAN_ANIMATION_NAME)
	sprite_frames.set_animation_loop(HIGAN_ANIMATION_NAME, false)
	sprite_frames.set_animation_speed(HIGAN_ANIMATION_NAME, HIGAN_ANIMATION_FPS)

	for texture in HIGAN_MENU_FRAMES:
		if texture != null:
			sprite_frames.add_frame(HIGAN_ANIMATION_NAME, texture)

	if sprite_frames.get_frame_count(HIGAN_ANIMATION_NAME) == 0:
		return

	higan_menu_animation.sprite_frames = sprite_frames
	higan_menu_animation.animation = HIGAN_ANIMATION_NAME
	_sync_higan_animation_to_frame()
	_show_higan_first_frame()

func _sync_higan_animation_to_frame() -> void:
	if higan_menu_frame == null or higan_menu_animation == null or higan_menu_animation.sprite_frames == null:
		return
	if higan_menu_animation.sprite_frames.get_frame_count(HIGAN_ANIMATION_NAME) == 0:
		return

	var first_frame := higan_menu_animation.sprite_frames.get_frame_texture(HIGAN_ANIMATION_NAME, 0)
	if first_frame == null:
		return

	var source_size: Vector2 = first_frame.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return

	var target_size: Vector2 = higan_menu_frame.size
	var scale_x: float = target_size.x / source_size.x
	var scale_y: float = target_size.y / source_size.y
	higan_menu_animation.scale = Vector2(scale_x, scale_y)
	higan_menu_animation.position = higan_menu_frame.position + (target_size / 2.0)

func _show_higan_first_frame() -> void:
	if higan_menu_animation == null:
		return

	higan_menu_animation.stop()
	higan_menu_animation.frame = 0

func _start_higan_animation_cycle() -> void:
	_run_higan_animation_cycle()

func _run_higan_animation_cycle() -> void:
	while is_inside_tree():
		var wait_seconds: float = randf_range(HIGAN_ANIMATION_INTERVAL_MIN_SECONDS, HIGAN_ANIMATION_INTERVAL_MAX_SECONDS)
		await get_tree().create_timer(wait_seconds).timeout
		if not is_inside_tree() or higan_menu_animation == null or higan_menu_animation.sprite_frames == null:
			return
		if higan_menu_animation.sprite_frames.get_frame_count(HIGAN_ANIMATION_NAME) == 0:
			return

		higan_menu_animation.play(HIGAN_ANIMATION_NAME)
		await higan_menu_animation.animation_finished
		if not is_inside_tree():
			return
		_show_higan_first_frame()
