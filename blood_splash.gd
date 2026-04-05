extends Node2D

const DROPLET_COUNT := 10

var lifetime := 0.3
var droplets: Array[Dictionary] = []

# Создает набор случайных кровавых капель и запускает их исчезновение.
func _ready() -> void:
	randomize()
	for i in range(DROPLET_COUNT):
		droplets.append({
			"offset": Vector2(randf_range(-28.0, 28.0), randf_range(-22.0, 22.0)),
			"radius": randf_range(4.0, 12.0),
			"color": Color(0.55 + randf_range(0.0, 0.2), randf_range(0.0, 0.06), randf_range(0.0, 0.06), 0.9)
		})

	queue_redraw()
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(1.25, 1.25), lifetime)
	tween.parallel().tween_property(self, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)

# Рисует кровавый всплеск из нескольких кругов.
func _draw() -> void:
	for droplet in droplets:
		draw_circle(droplet["offset"], droplet["radius"], droplet["color"])
