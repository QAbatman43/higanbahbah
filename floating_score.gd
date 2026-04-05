extends Label

const BONES_FONT = preload("res://fronts/firebugrus_lat.otf")
const GAME_TEXT_COLOR := Color8(235, 74, 28)

var rise_distance := 36.0
var lifetime := 0.5

# Настраивает текст и цвет всплывающего значения очков.
func setup(value_text: String, _value_color: Color) -> void:
	text = value_text
	add_theme_font_override("font", BONES_FONT)
	add_theme_font_size_override("font_size", 34)
	add_theme_color_override("font_color", GAME_TEXT_COLOR)
	add_theme_constant_override("outline_size", 4)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# Запускает короткую анимацию подъема и затухания текста.
func _ready() -> void:
	top_level = true
	scale = Vector2.ONE
	modulate.a = 1.0
	var tween = create_tween()
	tween.parallel().tween_property(self, "global_position:y", global_position.y - rise_distance, lifetime)
	tween.parallel().tween_property(self, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)
