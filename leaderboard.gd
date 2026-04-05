extends RefCounted
class_name Leaderboard

const SAVE_PATH := "user://leaderboard.save"
const MAX_ENTRIES := 10
const DEFAULT_NAME := "Player"
const DEFAULT_SCORES := [
	{"name": "Batman43", "score": 300000},
	{"name": "HiganБахБах", "score": 285000},
	{"name": "Nuke37", "score": 216000},
	{"name": "Блокиратор", "score": 198500},
	{"name": "Зелёная Зая", "score": 181000},
	{"name": "Михаил Шнумахер", "score": 156500},
	{"name": "HellHori", "score": 120000},
	{"name": "Рекви3байта", "score": 110000},
	{"name": "Jonathan_Spectrum", "score": 100000},
	{"name": "Pozit1vchick", "score": 50000}
]

# Возвращает встроенный топ рекордов по умолчанию.
static func _default_scores() -> Array:
	var scores: Array = []
	for entry in DEFAULT_SCORES:
		scores.append({
			"name": str(entry.get("name", DEFAULT_NAME)),
			"score": int(entry.get("score", 0)),
			"recorded_at": "Legendary era"
		})
	return scores

# Загружает таблицу рекордов из сохранения или из стандартных данных.
static func load_scores() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_scores()

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return _default_scores()

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return _default_scores()

	var scores: Array = []
	for entry in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var player_name = str(entry.get("name", DEFAULT_NAME))
		var score_value = int(entry.get("score", 0))
		var recorded_at = str(entry.get("recorded_at", ""))
		scores.append({
			"name": player_name,
			"score": score_value,
			"recorded_at": recorded_at
		})

	if scores.is_empty():
		return _default_scores()

	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)

	if scores.size() > MAX_ENTRIES:
		scores.resize(MAX_ENTRIES)

	return scores

# Проверяет, попадает ли переданный счет в текущий топ.
static func qualifies_for_top(score: int) -> bool:
	var scores := load_scores()
	if scores.size() < MAX_ENTRIES:
		return true
	return score > int(scores[MAX_ENTRIES - 1].get("score", 0))

# Сохраняет список рекордов в файл.
static func save_scores(scores: Array) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(scores))

# Сбрасывает рекорды к начальному списку.
static func reset_scores() -> void:
	save_scores(_default_scores())

# Добавляет новый рекорд, сортирует таблицу и сохраняет ее.
static func submit_score(score: int, player_name: String = DEFAULT_NAME) -> Array:
	var scores := load_scores()
	scores.append({
		"name": player_name,
		"score": score,
		"recorded_at": Time.get_datetime_string_from_system(false, true)
	})
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)

	if scores.size() > MAX_ENTRIES:
		scores.resize(MAX_ENTRIES)

	save_scores(scores)
	return scores
