extends Control

const Leaderboard = preload("res://leaderboard.gd")
const LEADERBOARD_BACKGROUND_PATH := "res://Images/higan_leaderboard.png"
const LEADERBOARD_ROWS := 10
const BUTTON_SHAKE_OFFSET := 3.0
const BUTTON_SHAKE_SPEED := 26.0

@onready var last_score_label: Label = $Window/Margin/VBox/LastScoreLabel
@onready var entries_label: Label = $Window/Margin/VBox/EntriesLabel
@onready var result_message_label: Label = $Window/Margin/VBox/ResultMessageLabel
@onready var name_prompt_label: Label = $Window/Margin/VBox/NamePromptLabel
@onready var name_input: LineEdit = $Window/Margin/VBox/NameInput
@onready var save_button: Button = $Window/Margin/VBox/SaveButton
@onready var save_button_label: Label = $Window/Margin/VBox/SaveButton/SaveButtonLabel
@onready var back_button: Button = $Window/Margin/VBox/BackButton
@onready var back_button_label: Label = $Window/Margin/VBox/BackButton/BackButtonLabel
@onready var background_art: TextureRect = $Window/BackgroundArt
@onready var leaderboard_window: PanelContainer = $Window

var pending_score: int = -1
var button_label_base_offsets: Dictionary = {}
var hovered_button_labels: Dictionary = {}

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_load_background()
	_init_pending_score()
	_refresh_scores()
	_apply_panel_window_size()
	get_viewport().size_changed.connect(_apply_panel_window_size)
	save_button.pressed.connect(_on_save_button_pressed)
	name_input.text_submitted.connect(_on_name_submitted)
	_setup_button_hover_shake()

func _process(_delta: float) -> void:
	_update_button_hover_shake()

func _setup_button_hover_shake() -> void:
	_register_button_label(save_button_label)
	_register_button_label(back_button_label)
	save_button.mouse_entered.connect(_on_button_mouse_entered.bind(save_button_label))
	save_button.mouse_exited.connect(_on_button_mouse_exited.bind(save_button_label))
	back_button.mouse_entered.connect(_on_button_mouse_entered.bind(back_button_label))
	back_button.mouse_exited.connect(_on_button_mouse_exited.bind(back_button_label))

func _register_button_label(label: Label) -> void:
	if label == null or button_label_base_offsets.has(label):
		return
	button_label_base_offsets[label] = {
		"left": label.offset_left,
		"top": label.offset_top,
		"right": label.offset_right,
		"bottom": label.offset_bottom
	}

func _on_button_mouse_entered(label: Label) -> void:
	if label == null:
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

	var time_seconds: float = Time.get_ticks_msec() / 1000.0
	var x_offset: float = sin(time_seconds * BUTTON_SHAKE_SPEED) * BUTTON_SHAKE_OFFSET
	var y_offset: float = cos(time_seconds * (BUTTON_SHAKE_SPEED * 0.87)) * (BUTTON_SHAKE_OFFSET * 0.55)
	for label_variant in hovered_button_labels.keys():
		var label := label_variant as Label
		if label == null:
			continue
		_apply_button_label_offset(label, Vector2(x_offset, y_offset))

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

func _on_back_button_pressed() -> void:
	if get_tree().has_meta("pending_score"):
		get_tree().remove_meta("pending_score")
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _load_background() -> void:
	var image := Image.load_from_file(LEADERBOARD_BACKGROUND_PATH)
	if image == null or image.is_empty():
		return
	background_art.texture = ImageTexture.create_from_image(image)

func _refresh_scores() -> void:
	var scores := Leaderboard.load_scores()
	var lines: PackedStringArray = []

	for index in mini(scores.size(), LEADERBOARD_ROWS):
		var entry: Dictionary = scores[index]
		var player_name := str(entry.get("name", "Player"))
		lines.append("%d. %s - %d" % [index + 1, player_name, int(entry.get("score", 0))])

	entries_label.text = "\n".join(lines)
	last_score_label.text = "Топ 10 лучших гренадеров"
	_update_name_prompt()

func _apply_panel_window_size() -> void:
	leaderboard_window.set_anchors_preset(Control.PRESET_FULL_RECT)
	leaderboard_window.offset_left = 0
	leaderboard_window.offset_top = 0
	leaderboard_window.offset_right = 0
	leaderboard_window.offset_bottom = 0

func _init_pending_score() -> void:
	if not get_tree().has_meta("pending_score"):
		return
	pending_score = int(get_tree().get_meta("pending_score"))

func _update_name_prompt() -> void:
	var should_show_prompt = pending_score >= 0 and Leaderboard.qualifies_for_top(pending_score)
	var should_show_retry_message = pending_score >= 0 and not should_show_prompt
	name_prompt_label.visible = should_show_prompt
	name_input.visible = should_show_prompt
	save_button.visible = should_show_prompt
	result_message_label.visible = should_show_retry_message
	if should_show_prompt:
		name_prompt_label.text = "Новый топ-10! Введи имя:"
		name_input.grab_focus()
		name_input.select_all()
	elif should_show_retry_message:
		result_message_label.text = "ВАШ СЧЕТ %d, ВЫ НЕ В ТОП 10, ПОПРОБУЙТЕ СНОВА" % pending_score
	else:
		result_message_label.text = ""

func _on_save_button_pressed() -> void:
	_save_pending_score()

func _on_name_submitted(_submitted_text: String) -> void:
	_save_pending_score()

func _save_pending_score() -> void:
	if pending_score < 0:
		return

	var saved_score := pending_score
	var player_name := name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = Leaderboard.DEFAULT_NAME

	Leaderboard.submit_score(saved_score, player_name)
	pending_score = -1
	if get_tree().has_meta("pending_score"):
		get_tree().remove_meta("pending_score")
	if get_tree().has_meta("last_score"):
		get_tree().remove_meta("last_score")
	last_score_label.text = "Сохранено: %s - %d" % [player_name, saved_score]
	name_input.text = ""
	result_message_label.visible = false
	result_message_label.text = ""
	_refresh_scores()
