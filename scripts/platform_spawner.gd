extends Node2D

@export var min_spawn_time: float = 1.5
@export var max_spawn_time: float = 2.2
@export var platform_speed: float = 80.0
@export var platform_lifetime: float = 10.0
@export var spawn_distance_ahead: float = 250.0
@export var platform_scenes: Array[PackedScene] = []

var timer: float = 0.0
var next_spawn_time: float = 0.0
var active_platforms: Array = []
var camera: Camera2D = null

func _ready():
	next_spawn_time = 0.3
	set_process(false)
	camera = get_viewport().get_camera_2d()
	if not camera:
		push_error("No camera found in scene!")

func _process(delta):
	timer += delta
	if timer >= next_spawn_time:
		spawn_platform()
		timer = 0.0
		next_spawn_time = randf_range(min_spawn_time, max_spawn_time)

func spawn_platform():
	if platform_scenes.is_empty():
		push_warning("No platform scenes assigned to spawner!")
		return

	var random_index = randi() % platform_scenes.size()
	var platform_scene = platform_scenes[random_index]
	var platform = platform_scene.instantiate()
	var spawn_pos = find_valid_spawn_position()

	if spawn_pos == Vector2.ZERO:
		platform.queue_free()
		return

	platform.global_position = spawn_pos
	platform.speed = platform_speed
	get_parent().add_child(platform)
	active_platforms.append(platform)

	var destroy_timer = get_tree().create_timer(platform_lifetime)
	destroy_timer.timeout.connect(func():
		if is_instance_valid(platform):
			active_platforms.erase(platform)
			platform.queue_free()
	)

func find_valid_spawn_position() -> Vector2:
	const PLATFORM_WIDTH = 152.0
	const PLATFORM_HEIGHT = 54.0
	const MIN_HORIZONTAL_GAP = 50.0
	const MIN_VERTICAL_GAP = 200.0
	const MAX_VERTICAL_GAP = 350.0
	const PLAYER_HORIZONTAL_CLEARANCE = 100.0
	const PLAYER_VERTICAL_CLEARANCE = 150.0

	var player = get_tree().get_first_node_in_group("player")
	var spawn_y = camera.global_position.y - spawn_distance_ahead
	var screen_center_x = camera.global_position.x

	for attempt in range(20):
		var random_x_offset = randf_range(-240, 240)
		var test_pos = Vector2(screen_center_x + random_x_offset, spawn_y)

		var horizontal_dist_to_player = abs(test_pos.x - player.global_position.x)
		var vertical_dist_to_player = abs(test_pos.y - player.global_position.y)

		if horizontal_dist_to_player < PLAYER_HORIZONTAL_CLEARANCE and vertical_dist_to_player < PLAYER_VERTICAL_CLEARANCE:
			continue

		var valid = true
		for existing_platform in active_platforms:
			if not is_instance_valid(existing_platform):
				continue

			var existing_pos = existing_platform.global_position
			var horizontal_dist = abs(test_pos.x - existing_pos.x)
			var vertical_dist = abs(test_pos.y - existing_pos.y)
			var overlaps_horizontally = horizontal_dist < (PLATFORM_WIDTH + MIN_HORIZONTAL_GAP)
			var overlaps_vertically = vertical_dist < (PLATFORM_HEIGHT + MIN_VERTICAL_GAP)

			if overlaps_horizontally and overlaps_vertically:
				valid = false
				break

		if valid:
			return test_pos

	return Vector2.ZERO

func set_platform_speed(new_speed: float):
	platform_speed = new_speed
