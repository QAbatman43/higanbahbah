extends RefCounted
class_name GameSettings

const SAVE_PATH := "user://settings.save"
const DEFAULT_RESOLUTION_INDEX := 0
const DEFAULT_EFFECTS_VOLUME := 0.8
const DEFAULT_MUSIC_VOLUME := 0.8
const FIXED_WINDOW_SIZE := Vector2i(800, 600)
const SFX_BUS_NAME := "SFX"
const MUSIC_BUS_NAME := "Music"
const RESOLUTIONS := [
	Vector2i(800, 600),
	Vector2i(1024, 768),
	Vector2i(1280, 1024),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

# Загружает настройки игры или возвращает значения по умолчанию.
static func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {
			"effects_volume": DEFAULT_EFFECTS_VOLUME,
			"music_volume": DEFAULT_MUSIC_VOLUME,
			"resolution_index": DEFAULT_RESOLUTION_INDEX
		}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {
			"effects_volume": DEFAULT_EFFECTS_VOLUME,
			"music_volume": DEFAULT_MUSIC_VOLUME,
			"resolution_index": DEFAULT_RESOLUTION_INDEX
		}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {
			"effects_volume": DEFAULT_EFFECTS_VOLUME,
			"music_volume": DEFAULT_MUSIC_VOLUME,
			"resolution_index": DEFAULT_RESOLUTION_INDEX
		}

	return {
		"effects_volume": float(parsed.get("effects_volume", DEFAULT_EFFECTS_VOLUME)),
		"music_volume": float(parsed.get("music_volume", DEFAULT_MUSIC_VOLUME)),
		"resolution_index": clampi(int(parsed.get("resolution_index", DEFAULT_RESOLUTION_INDEX)), 0, RESOLUTIONS.size() - 1)
	}

# Сохраняет настройки игры в файл.
static func save_settings(settings: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(settings))

# Применяет сохраненные настройки громкости и разрешения.
static func apply_settings(settings: Dictionary) -> void:
	_ensure_audio_buses()
	_apply_fixed_window_size()

# Обновляет, применяет и сохраняет настройки одним вызовом.
static func update_and_save(effects_volume: float, music_volume: float, resolution_index: int) -> void:
	var settings := {
		"effects_volume": clampf(effects_volume, 0.0, 1.0),
		"music_volume": clampf(music_volume, 0.0, 1.0),
		"resolution_index": DEFAULT_RESOLUTION_INDEX
	}
	apply_settings(settings)
	save_settings(settings)

# Создает отдельные шины для эффектов и музыки, если их еще нет.
static func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index(SFX_BUS_NAME) == -1:
		var insert_index = min(1, AudioServer.bus_count)
		AudioServer.add_bus(insert_index)
		AudioServer.set_bus_name(insert_index, SFX_BUS_NAME)
	if AudioServer.get_bus_index(MUSIC_BUS_NAME) == -1:
		var insert_index = min(2, AudioServer.bus_count)
		AudioServer.add_bus(insert_index)
		AudioServer.set_bus_name(insert_index, MUSIC_BUS_NAME)

# Настраивает громкость выбранной аудио-шины.
static func _apply_bus_volume(bus_name: String, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	if volume <= 0.001:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))

# Возвращает итоговую громкость музыкального плеера поверх базового volume_db из сцены.
# Значение 0.5 считается нейтральным: музыка играет ровно с базной громкостью.
static func get_music_player_volume_db(base_volume_db: float, music_volume: float) -> float:
	var clamped_volume := clampf(music_volume, 0.0, 1.0)
	if clamped_volume <= 0.001:
		return -80.0

	return base_volume_db + linear_to_db(clamped_volume / 0.5)

# Возвращает итоговую громкость для игрового звука поверх базового volume_db из сцены.
# Значение 0.5 считается нейтральным: звук играет ровно с базовой громкостью из инспектора.
static func get_sfx_player_volume_db(base_volume_db: float, effects_volume: float) -> float:
	var clamped_volume := clampf(effects_volume, 0.0, 1.0)
	if clamped_volume <= 0.001:
		return -80.0

	return base_volume_db + linear_to_db(clamped_volume / 0.5)

# Меняет размер окна игры и ставит его по центру экрана.
static func _apply_fixed_window_size() -> void:
	if DisplayServer.get_name() == "headless":
		return

	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.mode = Window.MODE_WINDOWED
		tree.root.min_size = FIXED_WINDOW_SIZE
		tree.root.size = FIXED_WINDOW_SIZE
		tree.root.max_size = FIXED_WINDOW_SIZE
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, true)
	var current_screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(current_screen)
	DisplayServer.window_set_position((screen_size - FIXED_WINDOW_SIZE) / 2)
