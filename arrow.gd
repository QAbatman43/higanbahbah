extends Sprite2D

var speed := 1999.0
var target_position := Vector2.ZERO

# Подготавливает стрелу к полету и сразу направляет ее на цель.
func _ready() -> void:
	top_level = true
	var direction = target_position - global_position
	if direction.length() > 0.0:
		rotation = direction.angle() + deg_to_rad(90)

# Двигает стрелу к точке клика и удаляет ее после попадания.
func _process(delta: float) -> void:
	var to_target = target_position - global_position
	var distance_to_target = to_target.length()
	if distance_to_target <= 0.001:
		queue_free()
		return

	var direction = to_target / distance_to_target
	var move_distance = speed * delta
	if move_distance >= distance_to_target:
		global_position = target_position
		queue_free()
		return

	global_position += direction * move_distance
	rotation = direction.angle() + deg_to_rad(90)
