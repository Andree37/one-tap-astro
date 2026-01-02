extends CharacterBody2D

const GRAVITY = 1200.0
const JUMP_FORCE = 1000.0
const MIN_HORIZONTAL_RATIO = 0.05
const MAX_HORIZONTAL_RATIO = 0.3
const FALL_MULTIPLIER = 2.5

var charge_time = 0.0
var max_charge_time = 1.0
var is_charging = false
var jump_direction = 1

var can_jump = false
var is_dead = false
var current_score = 0
var was_on_floor = false
var current_animation = ""
var previous_velocity = Vector2.ZERO
var highest_position = 0.0
var last_score_position = 0.0

@onready var audio_player = $AudioStreamPlayer
@onready var animation_player = $AnimationPlayer
@onready var jump_arrow = $JumpArrow

signal score_changed(score)
signal died(final_score)

var game_active = false

func _ready():
	can_jump = false
	velocity = Vector2.ZERO
	highest_position = global_position.y
	last_score_position = global_position.y
	floor_stop_on_slope = false
	floor_constant_speed = true
	floor_snap_length = 10.0
	floor_max_angle = 0.785398

func _physics_process(delta):
	if is_dead or not game_active:
		return

	previous_velocity = velocity

	if global_position.y < highest_position:
		highest_position = global_position.y

		var distance_climbed = last_score_position - highest_position
		if distance_climbed >= 50.0:
			var points_to_add = int(distance_climbed / 50.0)
			for i in range(points_to_add):
				add_score()
			last_score_position = highest_position

	if not is_on_floor():
		if velocity.y > 0:
			velocity.y += GRAVITY * FALL_MULTIPLIER * delta
		else:
			velocity.y += GRAVITY * delta

	if is_on_ceiling():
		velocity.y = 100

	var on_floor = is_on_floor()

	if on_floor:
		can_jump = true
		velocity.x = 0
		velocity.y = 0
		rotation = 0

		if not was_on_floor:
			if animation_player and not is_charging:
				play_animation("idle")
		elif animation_player and not is_charging and current_animation != "idle":
			play_animation("idle")
	else:
		can_jump = false
		if was_on_floor and animation_player:
			play_animation("jump")

	was_on_floor = on_floor

	if game_active:
		if Input.is_action_pressed("jump") and can_jump and not is_charging:
			is_charging = true
			charge_time = 0.0
			if animation_player:
				play_animation("crouch")
			if jump_arrow:
				jump_arrow.visible = true

		if Input.is_action_pressed("jump") and is_charging:
			velocity = Vector2.ZERO

			var mouse_pos = get_viewport().get_mouse_position()
			var camera = get_viewport().get_camera_2d()
			var player_screen_pos = camera.global_position - global_position
			var player_x = get_viewport().get_visible_rect().size.x / 2 - player_screen_pos.x

			var mouse_offset = mouse_pos.x - player_x
			var max_offset = 300.0
			var horizontal_ratio = clamp(mouse_offset / max_offset, -1.0, 1.0)

			var max_rotation = deg_to_rad(45)
			if jump_arrow:
				jump_arrow.rotation = horizontal_ratio * max_rotation

		if Input.is_action_just_released("jump") and is_charging:
			do_jump()
			is_charging = false
			if jump_arrow:
				jump_arrow.visible = false

	if abs(rotation) > 0.5:
		die()

	move_and_slide()

func play_animation(anim_name: String):
	if current_animation != anim_name:
		current_animation = anim_name
		animation_player.play(anim_name)

func do_jump():
	var jump_power = JUMP_FORCE

	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_2d()
	var player_screen_pos = camera.global_position - global_position
	var player_x = get_viewport().get_visible_rect().size.x / 2 - player_screen_pos.x
	var mouse_offset = mouse_pos.x - player_x
	var max_offset = 300.0
	var horizontal_ratio = clamp(mouse_offset / max_offset, -1.0, 1.0)

	var angle_factor = abs(horizontal_ratio) * 0.5
	var horizontal = horizontal_ratio * jump_power * angle_factor
	var vertical = -jump_power * (1.0 - angle_factor * 0.3)

	velocity = Vector2(horizontal, vertical)
	can_jump = false

	if audio_player:
		var jump_sound = load("res://assets/audio/jump.wav")
		if jump_sound:
			audio_player.stream = jump_sound
			audio_player.play()

func add_score():
	current_score += 1
	score_changed.emit(current_score)

	if current_score > SaveGame.get_highscore():
		SaveGame.set_highscore(current_score)

	if audio_player:
		var point_sound = load("res://assets/audio/points.wav")
		if point_sound:
			audio_player.stream = point_sound
			audio_player.play()

func die():
	if is_dead:
		return

	is_dead = true
	highest_position = global_position.y
	last_score_position = global_position.y

	if animation_player:
		play_animation("dead")

	if audio_player:
		var death_sound = load("res://assets/audio/dead.mp3")
		if death_sound:
			audio_player.stream = death_sound
			audio_player.play()

	SaveGame.increment_deaths()

	await get_tree().create_timer(0.5).timeout
	died.emit(current_score)
