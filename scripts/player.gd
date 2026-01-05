extends CharacterBody2D

const GRAVITY = 1200.0
var JUMP_FORCE = 1000.0
const MIN_HORIZONTAL_RATIO = 0.05
const MAX_HORIZONTAL_RATIO = 0.3
const FALL_MULTIPLIER = 2.5

var charge_time = 0.0
var max_charge_time = 1.0
var is_charging = false
var jump_direction = 1  # 1 for right, -1 for left

var can_jump = false
var is_dead = false
var current_score = 0
var was_on_floor = false
var current_animation = ""
var previous_velocity = Vector2.ZERO
var highest_position = 0.0
var last_score_position = 0.0
var highest_position_ever = 0.0
var platform_score_at_last_xp = 0

var can_double_jump = false
var double_jump_available = false

@onready var audio_player = $AudioStreamPlayer
@onready var animation_player = $AnimationPlayer
@onready var jump_arrow = $JumpArrow

signal score_changed(score)
signal died(final_score)

var game_active = false
var starting_position_y: float = 0.0

func _ready():
	can_jump = false
	velocity = Vector2.ZERO
	starting_position_y = global_position.y
	highest_position = global_position.y
	last_score_position = global_position.y
	highest_position_ever = global_position.y
	platform_score_at_last_xp = 0
	floor_stop_on_slope = false
	floor_constant_speed = true
	floor_snap_length = 10.0
	floor_max_angle = 0.785398

func _physics_process(delta):
	if is_dead or not game_active:
		return

	previous_velocity = velocity

	_apply_enemy_forces()

	if global_position.y < highest_position:
		highest_position = global_position.y

	if global_position.y < highest_position_ever:
		highest_position_ever = global_position.y

		var distance_climbed = last_score_position - highest_position_ever
		if distance_climbed >= 50.0:
			var points_to_add = int(distance_climbed / 50.0)
			print("PLAYER: Adding ", points_to_add, " points. Distance climbed: ", distance_climbed)
			for i in range(points_to_add):
				add_score()
			last_score_position = highest_position_ever

	if not is_on_floor():
		if velocity.y > 0:
			velocity.y += GRAVITY * FALL_MULTIPLIER * delta
		else:
			velocity.y += GRAVITY * delta

	if is_on_ceiling():
		velocity.y = 100  # Push down immediately

	var on_floor = is_on_floor()

	if on_floor:
		can_jump = true
		velocity.x = 0  # Stop horizontal movement
		velocity.y = 0  # Stop vertical movement
		rotation = 0  # Keep upright

		if can_double_jump:
			double_jump_available = true

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
			var max_offset = 300.0  # Max distance from player for full angle
			var horizontal_ratio = clamp(mouse_offset / max_offset, -1.0, 1.0)

			var max_rotation = deg_to_rad(45)
			if jump_arrow:
				jump_arrow.rotation = horizontal_ratio * max_rotation

		if Input.is_action_just_released("jump") and is_charging:
			do_jump()
			is_charging = false
			if jump_arrow:
				jump_arrow.visible = false

		if Input.is_action_just_pressed("jump") and not can_jump and can_double_jump and double_jump_available:
			do_double_jump()

	if abs(rotation) > 0.5:
		die()

	move_and_slide()

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is StaticBody2D and (collider.name == "LeftWall" or collider.name == "RightWall"):
			var normal = collision.get_normal()

			var push_force = 500.0  # Adjust this value for stronger/weaker push
			velocity.x = normal.x * push_force

			velocity.y = velocity.y * 0.9

			print("PLAYER: Bounced off ", collider.name, " with push velocity: ", velocity.x)

func play_animation(anim_name: String):
	if current_animation != anim_name:
		current_animation = anim_name
		animation_player.play(anim_name)

func do_jump():
	var jump_power = JUMP_FORCE  # Constant jump power

	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_2d()
	var player_screen_pos = camera.global_position - global_position
	var player_x = get_viewport().get_visible_rect().size.x / 2 - player_screen_pos.x
	var mouse_offset = mouse_pos.x - player_x
	var max_offset = 300.0  # Max distance from player for full angle
	var horizontal_ratio = clamp(mouse_offset / max_offset, -1.0, 1.0)

	var angle_factor = abs(horizontal_ratio) * 0.5  # Scale to 0-0.5 range
	var horizontal = horizontal_ratio * jump_power * angle_factor
	var vertical = -jump_power * (1.0 - angle_factor * 0.3)  # Mostly vertical

	velocity = Vector2(horizontal, vertical)
	can_jump = false

	var powerup_component = get_node("PowerupComponent")
	if powerup_component:
		powerup_component.consume_jump_boost()

	if audio_player:
		var jump_sound = load("res://assets/audio/jump.wav")
		if jump_sound:
			audio_player.stream = jump_sound
			audio_player.play()

func do_double_jump():
	var jump_power = JUMP_FORCE * 0.8

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
	double_jump_available = false
	print("PLAYER: Double jumping with direction!")

	var powerup_component = get_node("PowerupComponent")
	if powerup_component:
		powerup_component.consume_double_jump()

	if audio_player:
		var jump_sound = load("res://assets/audio/jump.wav")
		if jump_sound:
			audio_player.stream = jump_sound
			audio_player.play()

func add_score():
	current_score += 1
	print("PLAYER: Score updated to ", current_score)
	score_changed.emit(current_score)
	EventBus.score_changed.emit(current_score)

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
	highest_position_ever = global_position.y
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

func _apply_enemy_forces() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var total_force = Vector2.ZERO

	for enemy in enemies:
		if enemy.has_method("get_magnet_force"):
			total_force += enemy.get_magnet_force()

	if total_force.length() > 0:
		velocity += total_force * get_physics_process_delta_time()
