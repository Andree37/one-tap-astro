extends Node2D

class_name PlatformSpawnerV2

@export_group("Spawn Timing")
@export var min_spawn_time: float = 1.5
@export var max_spawn_time: float = 2.2
@export var initial_spawn_delay: float = 0.3

@export_group("Platform Movement")
@export var platform_speed: float = 80.0
@export var platform_lifetime: float = 10.0

@export_group("Spawn Position")
@export var spawn_distance_ahead: float = 250.0
@export var spawn_x_range: float = 240.0

@export_group("Platform Spacing")
@export var min_horizontal_gap: float = 50.0
@export var min_vertical_gap: float = 200.0
@export var player_horizontal_clearance: float = 100.0
@export var player_vertical_clearance: float = 150.0

@export_group("Platform Scenes")
@export var platform_scenes: Array[PackedScene] = []

@export_group("Object Pool")
@export var use_object_pool: bool = true
@export var pool_size: int = 20

var spawn_timer: float = 0.0
var next_spawn_time: float = 0.0
var active_platforms: Array[Node2D] = []
var camera: Camera2D = null
var player: CharacterBody2D = null
var is_spawning: bool = false
var platform_pools: Array[ObjectPool] = []

func _ready() -> void:
	next_spawn_time = initial_spawn_delay
	is_spawning = false

	camera = get_viewport().get_camera_2d()
	if not camera:
		push_error("PlatformSpawner: No camera found in scene!")

	player = get_tree().get_first_node_in_group(GameConstants.GROUP_PLAYER)
	if not player:
		push_warning("PlatformSpawner: No player found in scene!")

	if use_object_pool:
		_initialize_pools()

	if has_node("/root/EventBus"):
		EventBus.game_started.connect(_on_game_started)
		EventBus.game_over.connect(_on_game_over)

func _initialize_pools() -> void:
	if platform_scenes.is_empty():
		push_warning("PlatformSpawner: No platform scenes assigned!")
		return

	for i in range(platform_scenes.size()):
		var pool = ObjectPool.new()
		pool.name = "PlatformPool" + str(i)
		pool.pooled_scene = platform_scenes[i]
		pool.initial_size = max(1, pool_size / platform_scenes.size())
		pool.max_size = pool_size
		pool.auto_grow = true
		add_child(pool)
		platform_pools.append(pool)

func _process(delta: float) -> void:
	if not is_spawning:
		return

	spawn_timer += delta

	if spawn_timer >= next_spawn_time:
		spawn_platform()
		spawn_timer = 0.0
		next_spawn_time = randf_range(min_spawn_time, max_spawn_time)

func spawn_platform() -> void:
	if not camera:
		return

	var spawn_pos = _find_valid_spawn_position()
	if spawn_pos == Vector2.ZERO:
		return

	var platform: Node2D = null

	if use_object_pool and platform_pools.size() > 0:
		var pool_index = randi() % platform_pools.size()
		platform = platform_pools[pool_index].get_object() as Node2D

		if platform:
			if platform.get_parent() != get_parent():
				platform.reparent(get_parent())
	else:
		if platform_scenes.is_empty():
			return

		var random_index = randi() % platform_scenes.size()
		var platform_scene = platform_scenes[random_index]
		platform = platform_scene.instantiate()
		get_parent().add_child(platform)

	if not platform:
		return

	platform.global_position = spawn_pos

	if platform.has_method("set_speed"):
		platform.call("set_speed", platform_speed)
	elif "speed" in platform:
		platform.speed = platform_speed

	active_platforms.append(platform)

	if has_node("/root/EventBus"):
		EventBus.platform_spawned.emit(platform)

	_setup_platform_lifetime(platform)

func _find_valid_spawn_position() -> Vector2:
	const MAX_ATTEMPTS: int = 20
	const PLATFORM_WIDTH: float = 152.0
	const PLATFORM_HEIGHT: float = 54.0

	var spawn_y = camera.global_position.y - spawn_distance_ahead
	var screen_center_x = camera.global_position.x

	for attempt in range(MAX_ATTEMPTS):
		var random_x_offset = randf_range(-spawn_x_range, spawn_x_range)
		var test_pos = Vector2(screen_center_x + random_x_offset, spawn_y)

		if player:
			var horizontal_dist = abs(test_pos.x - player.global_position.x)
			var vertical_dist = abs(test_pos.y - player.global_position.y)

			if horizontal_dist < player_horizontal_clearance and vertical_dist < player_vertical_clearance:
				continue

		var valid = true
		for existing_platform in active_platforms:
			if not is_instance_valid(existing_platform):
				continue

			var existing_pos = existing_platform.global_position
			var horizontal_dist = abs(test_pos.x - existing_pos.x)
			var vertical_dist = abs(test_pos.y - existing_pos.y)

			var overlaps_horizontally = horizontal_dist < (PLATFORM_WIDTH + min_horizontal_gap)
			var overlaps_vertically = vertical_dist < (PLATFORM_HEIGHT + min_vertical_gap)

			if overlaps_horizontally and overlaps_vertically:
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

	if has_node("/root/EventBus"):
		EventBus.platform_destroyed.emit(platform)

	if use_object_pool:
		for pool in platform_pools:
			if pool.active_objects.has(platform):
				pool.return_object(platform)
				return

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

func set_platform_speed(new_speed: float) -> void:
	platform_speed = new_speed

	for platform in active_platforms:
		if is_instance_valid(platform):
			if platform.has_method("set_speed"):
				platform.call("set_speed", new_speed)
			elif "speed" in platform:
				platform.speed = new_speed

func get_stats() -> Dictionary:
	var pool_stats = []
	for pool in platform_pools:
		pool_stats.append(pool.get_stats())

	return {
		"active_platforms": active_platforms.size(),
		"is_spawning": is_spawning,
		"next_spawn_in": next_spawn_time - spawn_timer,
		"pool_stats": pool_stats
	}

func _on_game_started() -> void:
	start_spawning()

func _on_game_over(_final_score: int) -> void:
	stop_spawning()
