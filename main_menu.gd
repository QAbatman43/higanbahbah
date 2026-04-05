extends Control

const Leaderboard = preload("res://leaderboard.gd")
const LEADERBOARD_BACKGROUND_PATH := "C:/Users/wwwgo/OneDrive/Изображения/kiss-Photoroom.png"
const LEADERBOARD_ROWS := 10

@onready var score_button: Button = $VBoxContainer/ScoreButton
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var menu_buttons: VBoxContainer = $VBoxContainer

var leaderboard_panel: PanelContainer
var leaderboard_overlay: Control
var leaderboard_title: Label
var leaderboard_last_score: Label
var leaderboard_entries: Label
var last_score: int = -1

# Запускает игровую сцену из главного меню.
func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://root.tscn")

# Закрывает игру по кнопке выхода.
func _on_exit_button_pressed():
	get_tree().quit()

# Собирает встроенную панель рекордов и показывает прошлый результат.
func _ready() -> void:
	score_button.pressed.connect(_on_score_button_pressed)
	build_leaderboard_panel()

	if get_tree().has_meta("last_score"):
		last_score = int(get_tree().get_meta("last_score"))
		get_tree().remove_meta("last_score")
		set_leaderboard_visible(true)

	refresh_leaderboard()

# Открывает и закрывает встроенную таблицу рекордов.
func _on_score_button_pressed() -> void:
	set_leaderboard_visible(not leaderboard_overlay.visible)
	if leaderboard_overlay.visible:
		refresh_leaderboard()

# Переключает видимость панели рекордов и кнопок меню.
func set_leaderboard_visible(is_visible: bool) -> void:
	leaderboard_overlay.visible = is_visible
	menu_buttons.visible = not is_visible

# Создает модальное окно рекордов внутри главного меню.
func build_leaderboard_panel() -> void:
	leaderboard_overlay = Control.new()
	leaderboard_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	leaderboard_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	leaderboard_overlay.visible = false
	add_child(leaderboard_overlay)

	var overlay_scrim := ColorRect.new()
	overlay_scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_scrim.color = Color(0, 0, 0, 0.35)
	leaderboard_overlay.add_child(overlay_scrim)

	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	leaderboard_overlay.add_child(center_container)

	leaderboard_panel = PanelContainer.new()
	leaderboard_panel.custom_minimum_size = Vector2(500, 600)
	leaderboard_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center_container.add_child(leaderboard_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.11, 0.06, 0.05, 0.9)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.98, 0.55, 0.24, 1.0)
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_right = 18
	panel_style.corner_radius_bottom_left = 18
	leaderboard_panel.add_theme_stylebox_override("panel", panel_style)

	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 6
	background.offset_top = 6
	background.offset_right = -6
	background.offset_bottom = -6
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.modulate = Color(1, 1, 1, 0.3)
	background.texture = _load_leaderboard_background()
	leaderboard_panel.add_child(background)

	var scrim := ColorRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.08, 0.04, 0.03, 0.72)
	leaderboard_panel.add_child(scrim)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 22
	content.offset_top = 20
	content.offset_right = -22
	content.offset_bottom = -18
	content.add_theme_constant_override("separation", 8)
	leaderboard_panel.add_child(content)

	leaderboard_title = Label.new()
	leaderboard_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaderboard_title.add_theme_font_override("font", start_button.get_theme_font("font"))
	leaderboard_title.add_theme_font_size_override("font_size", 32)
	leaderboard_title.text = "Leaderboard"
	content.add_child(leaderboard_title)

	leaderboard_last_score = Label.new()
	leaderboard_last_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaderboard_last_score.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leaderboard_last_score.add_theme_font_override("font", start_button.get_theme_font("font"))
	leaderboard_last_score.add_theme_font_size_override("font_size", 18)
	content.add_child(leaderboard_last_score)

	leaderboard_entries = Label.new()
	leaderboard_entries.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	leaderboard_entries.autowrap_mode = TextServer.AUTOWRAP_OFF
	leaderboard_entries.add_theme_font_override("font", start_button.get_theme_font("font"))
	leaderboard_entries.add_theme_font_size_override("font_size", 18)
	leaderboard_entries.custom_minimum_size = Vector2(0, 300)
	content.add_child(leaderboard_entries)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(0, 48)
	close_button.add_theme_font_override("font", start_button.get_theme_font("font"))
	close_button.add_theme_font_size_override("font_size", 24)
	close_button.pressed.connect(func() -> void:
		set_leaderboard_visible(false)
	)
	content.add_child(close_button)

# Загружает картинку для фона встроенной панели рекордов.
func _load_leaderboard_background() -> Texture2D:
	var image := Image.load_from_file(LEADERBOARD_BACKGROUND_PATH)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

# Обновляет содержимое встроенного списка рекордов.
func refresh_leaderboard() -> void:
	var scores := Leaderboard.load_scores()
	var lines: PackedStringArray = []

	for index in mini(scores.size(), LEADERBOARD_ROWS):
		var entry: Dictionary = scores[index]
		var player_name = str(entry.get("name", "Player"))
		var padded_name = player_name.rpad(18, " ")
		lines.append("%2d. %s%d" % [index + 1, padded_name, int(entry.get("score", 0))])

	if lines.is_empty():
		leaderboard_entries.text = "No records yet.\nPlay one round to create the first score."
	else:
		leaderboard_entries.text = "\n".join(lines)

	if last_score >= 0:
		leaderboard_last_score.text = "Last run: %d pts" % last_score
	else:
		leaderboard_last_score.text = "Best results are saved automatically."
