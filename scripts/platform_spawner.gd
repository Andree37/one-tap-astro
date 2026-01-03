extends Node2D

class_name PlatformSpawner

@export_group("Spawn Timing")
@export var min_spawn_time: float = 0.8
@export var max_spawn_time: float = 1.5
@export var initial_spawn_delay: float = 0.1

@export_group("Platform Movement")
@export var platform_speed: float = 80.0
@export var platform_lifetime: float = 10.0

@export_group("Spawn Position")
@export var spawn_distance_ahead: float = 300.0
@export var spawn_x_range: float = 240.0

@export_group("Platform Spacing")
@export var min_horizontal_gap: float = 50.0
@export var min_vertical_gap: float = 200.0
@export var player_horizontal_clearance: float = 100.0
@export var player_vertical_clearance: float = 150.0

@export_group("Platform Scenes")
@export var normal_platform_scene: PackedScene
@export var bounce_platform_scene: PackedScene

@export_group("Difficulty")
@export var enable_difficulty_scaling: bool = true

var difficulty_manager: DifficultyManager

var spawn_timer: float = 0.0
var next_spawn_time: float = 0.0
var active_platforms: Array[Node2D] = []
var camera: Camera2D = null
var player: CharacterBody2D = null
var is_spawning: bool = false
var spawn_paused: bool = false

func _ready() -> void:
	next_spawn_time = initial_spawn_delay
	is_spawning = false

	camera = get_viewport().get_camera_2d()
	player = get_tree().get_first_node_in_group("player")
	difficulty_manager = get_parent().get_node("DifficultyManager")

	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)

	difficulty_manager.speed_increased.connect(_on_speed_increased)

func _process(delta: float) -> void:
	if not is_spawning or spawn_paused:
		return

	spawn_timer += delta

	if spawn_timer >= next_spawn_time:
		spawn_platform()
		spawn_timer = 0.0
		update_spawn_time()

func update_spawn_time() -> void:
	if enable_difficulty_scaling:
		var spawn_range = difficulty_manager.get_spawn_time_range()
		next_spawn_time = randf_range(spawn_range.x, spawn_range.y)
	else:
		next_spawn_time = randf_range(min_spawn_time, max_spawn_time)

func spawn_platform() -> void:
	var spawn_pos = _find_valid_spawn_position()
	if spawn_pos == Vector2.ZERO:
		return

	var platform_scene = _choose_platform_scene()
	var platform = platform_scene.instantiate()
	get_parent().add_child(platform)

	platform.global_position = spawn_pos

	var current_speed = platform_speed
	if enable_difficulty_scaling:
		current_speed = difficulty_manager.get_platform_speed()

	if platform.has_method("set_speed"):
		platform.set_speed(current_speed)
	else:
		platform.speed = current_speed

	active_platforms.append(platform)
	_setup_platform_lifetime(platform)

	if enable_difficulty_scaling:
		print("SPAWNER: Checking if should spawn powerup...")
		if difficulty_manager.should_spawn_powerup_platform():
			print("SPAWNER: YES, spawning powerup on platform!")
			spawn_powerup_on_platform(platform)
		else:
			print("SPAWNER: NO powerup this time")

func _choose_platform_scene() -> PackedScene:
	return normal_platform_scene

func _choose_random_special_scene() -> PackedScene:
	if bounce_platform_scene:
		return bounce_platform_scene

	return normal_platform_scene



func spawn_powerup_on_platform(platform: Node2D) -> void:
	var powerup_scene = load("res://scenes/powerup_pickup.tscn")
	if not powerup_scene:
		print("SPAWNER ERROR: Failed to load powerup_pickup.tscn!")
		return

	var powerup = powerup_scene.instantiate()
	if not powerup:
		print("SPAWNER ERROR: Failed to instantiate powerup!")
		return

	var powerup_types = [0, 1, 2, 3]
	powerup.powerup_type = powerup_types[randi() % powerup_types.size()]

	powerup.position = Vector2(0, -80)
	platform.add_child(powerup)

	print("SPAWNER: Spawned powerup pickup on platform at position ", powerup.global_position, " type: ", powerup.powerup_type)

func _find_valid_spawn_position() -> Vector2:
	const MAX_ATTEMPTS: int = 20
	const PLATFORM_WIDTH: float = 152.0
	const PLATFORM_HEIGHT: float = 54.0

	var spawn_y = camera.global_position.y - spawn_distance_ahead
	var screen_center_x = camera.global_position.x

	for attempt in range(MAX_ATTEMPTS):
		var random_x_offset = randf_range(-spawn_x_range, spawn_x_range)
		var test_pos = Vector2(screen_center_x + random_x_offset, spawn_y)

		var horizontal_dist = abs(test_pos.x - player.global_position.x)
		var vertical_dist = abs(test_pos.y - player.global_position.y)

		if horizontal_dist < player_horizontal_clearance and vertical_dist < player_vertical_clearance:
			continue

		var valid = true
		for existing_platform in active_platforms:
			if not is_instance_valid(existing_platform):
				continue

			var existing_pos = existing_platform.global_position
			var h_dist = abs(test_pos.x - existing_pos.x)
			var v_dist = abs(test_pos.y - existing_pos.y)

			var overlaps_h = h_dist < (PLATFORM_WIDTH + min_horizontal_gap)
			var overlaps_v = v_dist < (PLATFORM_HEIGHT + min_vertical_gap)

			if overlaps_h and overlaps_v:
				valid = false
				break

		if valid:
			return test_pos

	return Vector2.ZERO

func _setup_platform_lifetime(platform: Node2D) -> void:
	var timer = get_tree().create_timer(platform_lifetime)
	timer.timeout.connect(func():
		_destroy_platform(platform)
	)

func _destroy_platform(platform: Node2D) -> void:
	if not is_instance_valid(platform):
		return

	active_platforms.erase(platform)
	platform.queue_free()

func start_spawning() -> void:
	is_spawning = true
	spawn_timer = 0.0
	next_spawn_time = initial_spawn_delay

func stop_spawning() -> void:
	is_spawning = false

func clear_all_platforms() -> void:
	for platform in active_platforms.duplicate():
		_destroy_platform(platform)
	active_platforms.clear()

func _on_game_started() -> void:
	start_spawning()

func _on_game_over(_final_score: int) -> void:
	stop_spawning()

func _on_speed_increased(new_speed: float) -> void:
	platform_speed = new_speed

	for platform in active_platforms:
		if is_instance_valid(platform):
			if platform.has_method("set_speed"):
				platform.set_speed(new_speed)
			else:
				platform.speed = new_speed

func pause_spawning_for(duration: float) -> void:
	spawn_paused = true
	print("SPAWNER: Pausing spawning for ", duration, " seconds")

	get_tree().create_timer(duration).timeout.connect(func():
		spawn_paused = false
		print("SPAWNER: Resuming spawning")
	)
