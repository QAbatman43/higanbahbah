extends Control

const GameSettings = preload("res://game_settings.gd")
const Leaderboard = preload("res://leaderboard.gd")
const BUTTON_SHAKE_OFFSET := 3.0
const BUTTON_SHAKE_SPEED := 26.0

@onready var volume_slider: HSlider = $Margin/Panel/VBox/VolumeSlider
@onready var volume_value_label: Label = $Margin/Panel/VBox/VolumeValueRow/VolumeValueText
@onready var music_slider: HSlider = $Margin/Panel/VBox/MusicSlider
@onready var music_value_label: Label = $Margin/Panel/VBox/MusicValueRow/MusicValueText
@onready var reset_status_label: Label = $Margin/Panel/VBox/ResetStatusLabel
@onready var back_button: Button = $Margin/Panel/VBox/BackButton
@onready var back_button_label: Label = $Margin/Panel/VBox/BackButton/BackButtonLabel
@onready var reset_leaderboard_button: Button = $Margin/Panel/VBox/ResetLeaderboardButton
@onready var reset_leaderboard_button_label: Label = $Margin/Panel/VBox/ResetLeaderboardButton/ResetLeaderboardButtonLabel

var button_label_base_offsets: Dictionary = {}
var hovered_button_labels: Dictionary = {}

func _ready() -> void:
	_load_current_settings()
	_setup_static_button_hover_shake()
	volume_slider.value_changed.connect(_on_volume_changed)
	music_slider.value_changed.connect(_on_music_changed)

func _process(_delta: float) -> void:
	_update_button_hover_shake()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_reset_leaderboard_button_pressed() -> void:
	Leaderboard.reset_scores()
	reset_status_label.text = "Таблица лидеров сброшена."

func _load_current_settings() -> void:
	var settings := GameSettings.load_settings()
	var effects_volume := float(settings.get("effects_volume", GameSettings.DEFAULT_EFFECTS_VOLUME))
	var music_volume := float(settings.get("music_volume", GameSettings.DEFAULT_MUSIC_VOLUME))
	volume_slider.value = effects_volume * 100.0
	music_slider.value = music_volume * 100.0
	_update_volume_label(volume_slider.value)
	_update_music_label(music_slider.value)
	GameSettings.apply_settings(settings)
	reset_status_label.text = ""

func _on_volume_changed(value: float) -> void:
	_update_volume_label(value)
	var settings := GameSettings.load_settings()
	var music_volume := float(settings.get("music_volume", GameSettings.DEFAULT_MUSIC_VOLUME))
	GameSettings.update_and_save(value / 100.0, music_volume, GameSettings.DEFAULT_RESOLUTION_INDEX)

func _on_music_changed(value: float) -> void:
	_update_music_label(value)
	var settings := GameSettings.load_settings()
	var effects_volume := float(settings.get("effects_volume", GameSettings.DEFAULT_EFFECTS_VOLUME))
	GameSettings.update_and_save(effects_volume, value / 100.0, GameSettings.DEFAULT_RESOLUTION_INDEX)

func _update_volume_label(value: float) -> void:
	volume_value_label.text = str(int(round(value)))

func _update_music_label(value: float) -> void:
	music_value_label.text = str(int(round(value)))

func _setup_static_button_hover_shake() -> void:
	_register_button_label(back_button, back_button_label)
	_register_button_label(reset_leaderboard_button, reset_leaderboard_button_label)
	back_button.mouse_entered.connect(_on_button_mouse_entered.bind(back_button, back_button_label))
	back_button.mouse_exited.connect(_on_button_mouse_exited.bind(back_button_label))
	reset_leaderboard_button.mouse_entered.connect(_on_button_mouse_entered.bind(reset_leaderboard_button, reset_leaderboard_button_label))
	reset_leaderboard_button.mouse_exited.connect(_on_button_mouse_exited.bind(reset_leaderboard_button_label))

func _register_button_label(button: Button, label: Label) -> void:
	if button == null or label == null:
		return
	if button_label_base_offsets.has(label):
		return
	button_label_base_offsets[label] = {
		"left": label.offset_left,
		"right": label.offset_right,
		"top": label.offset_top,
		"bottom": label.offset_bottom,
	}

func _on_button_mouse_entered(button: Button, label: Label) -> void:
	if button == null or label == null or button.disabled:
		return
	hovered_button_labels[label] = true

func _on_button_mouse_exited(label: Label) -> void:
	if label == null:
		return
	hovered_button_labels.erase(label)
	_restore_button_label_offsets(label)

func _update_button_hover_shake() -> void:
	if hovered_button_labels.is_empty():
		return
	var time_value: float = Time.get_ticks_msec() / 1000.0
	for label_variant in hovered_button_labels.keys():
		var label := label_variant as Label
		if label == null:
			continue
		var x_offset: float = sin(time_value * BUTTON_SHAKE_SPEED) * BUTTON_SHAKE_OFFSET
		var y_offset: float = cos(time_value * (BUTTON_SHAKE_SPEED - 4.0)) * BUTTON_SHAKE_OFFSET
		_apply_button_label_offset(label, Vector2(x_offset, y_offset))

func _restore_button_label_offsets(label: Label) -> void:
	var base_offsets: Dictionary = button_label_base_offsets.get(label, {})
	if base_offsets.is_empty():
		return
	label.offset_left = float(base_offsets.get("left", label.offset_left))
	label.offset_right = float(base_offsets.get("right", label.offset_right))
	label.offset_top = float(base_offsets.get("top", label.offset_top))
	label.offset_bottom = float(base_offsets.get("bottom", label.offset_bottom))

func _apply_button_label_offset(label: Label, offset: Vector2) -> void:
	var base_offsets: Dictionary = button_label_base_offsets.get(label, {})
	if base_offsets.is_empty():
		return
	label.offset_left = float(base_offsets.get("left", label.offset_left)) + offset.x
	label.offset_right = float(base_offsets.get("right", label.offset_right)) + offset.x
	label.offset_top = float(base_offsets.get("top", label.offset_top)) + offset.y
	label.offset_bottom = float(base_offsets.get("bottom", label.offset_bottom)) + offset.y
