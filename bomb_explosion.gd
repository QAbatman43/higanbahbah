extends Node2D

const EXPLOSION_ANIMATION_NAME := &"explode"
const EXPLOSION_FPS := 18.0
const EXPLOSION_FRAMES: Array[Texture2D] = [
	preload("res://Images/bomb_explosion/boom00.png"),
	preload("res://Images/bomb_explosion/boom01.png"),
	preload("res://Images/bomb_explosion/boom02.png"),
	preload("res://Images/bomb_explosion/boom03.png"),
	preload("res://Images/bomb_explosion/boom04.png"),
	preload("res://Images/bomb_explosion/boom05.png"),
	preload("res://Images/bomb_explosion/boom06.png"),
	preload("res://Images/bomb_explosion/boom07.png")
]

@onready var explosion_sprite: AnimatedSprite2D = $Explosion

func _ready() -> void:
	_setup_animation()
	if explosion_sprite.sprite_frames == null:
		queue_free()
		return
	if explosion_sprite.sprite_frames.get_frame_count(EXPLOSION_ANIMATION_NAME) == 0:
		queue_free()
		return

	explosion_sprite.play(EXPLOSION_ANIMATION_NAME)
	if not explosion_sprite.animation_finished.is_connected(_on_animation_finished):
		explosion_sprite.animation_finished.connect(_on_animation_finished)

func _setup_animation() -> void:
	if explosion_sprite == null:
		return
	if EXPLOSION_FRAMES.is_empty():
		return

	var sprite_frames := SpriteFrames.new()
	sprite_frames.add_animation(EXPLOSION_ANIMATION_NAME)
	sprite_frames.set_animation_loop(EXPLOSION_ANIMATION_NAME, false)
	sprite_frames.set_animation_speed(EXPLOSION_ANIMATION_NAME, EXPLOSION_FPS)

	for texture in EXPLOSION_FRAMES:
		if texture != null:
			sprite_frames.add_frame(EXPLOSION_ANIMATION_NAME, texture)

	explosion_sprite.sprite_frames = sprite_frames
	explosion_sprite.animation = EXPLOSION_ANIMATION_NAME
	explosion_sprite.frame = 0

func _on_animation_finished() -> void:
	queue_free()
