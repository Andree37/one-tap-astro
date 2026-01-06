extends Node2D

class_name EnemySpawner

signal boss_spawned(boss: Enemy)
signal final_boss_appeared(boss: Enemy)



@export var spawn_interval_min: float = 10.0
@export var spawn_interval_max: float = 20.0
@export var boss_spawn_time: float = 60.0
@export var spawn_distance_ahead: float = 400.0
@export var max_enemies: int = 5

var spawn_timer: float = 0.0
var next_spawn_time: float = 0.0
var game_timer: float = 0.0
var is_spawning: bool = false
var final_boss_has_spawned: bool = false
var active_enemies: Array[Enemy] = []

var camera: Camera2D = null
var player: CharacterBody2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	EventBus.game_started.connect(_on_game_started)
	EventBus.game_over.connect(_on_game_over)

	camera = get_viewport().get_camera_2d()
	player = get_tree().get_first_node_in_group("player")

	_update_next_spawn_time()
	print("ENEMY_SPAWNER: Ready - Camera: ", camera != null, " Player: ", player != null)

func _process(delta: float) -> void:
	if not is_spawning:
		return

	game_timer += delta
	spawn_timer += delta

	if not final_boss_has_spawned and game_timer >= boss_spawn_time:
		spawn_final_boss()
		final_boss_has_spawned = true

	if spawn_timer >= next_spawn_time and active_enemies.size() < max_enemies:
		spawn_enemy()
		spawn_timer = 0.0
		_update_next_spawn_time()

func _update_next_spawn_time() -> void:
	next_spawn_time = randf_range(spawn_interval_min, spawn_interval_max)

func spawn_enemy(as_boss: bool = false) -> Enemy:
	if not camera or not player:
		print("ENEMY_SPAWNER: Cannot spawn - Camera: ", camera != null, " Player: ", player != null)
		return null

	var spawn_pos = _find_spawn_position()

	var enemy_scene = load("res://scenes/enemy.tscn")
	if not enemy_scene:
		print("ENEMY_SPAWNER: Failed to load enemy scene")
		return null

	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos

	if as_boss:
		enemy.set_as_boss()
		print("ENEMY_SPAWNER: Spawned BOSS at ", spawn_pos)
		boss_spawned.emit(enemy)
	else:
		print("ENEMY_SPAWNER: Spawned enemy at ", spawn_pos)

	enemy.enemy_died.connect(_on_enemy_died)

	get_parent().add_child(enemy)
	active_enemies.append(enemy)

	return enemy

func spawn_final_boss() -> void:
	print("ENEMY_SPAWNER: Spawning FINAL BOSS!")

	var spawn_pos = Vector2(
		camera.global_position.x,
		camera.global_position.y + spawn_distance_ahead
	)

	var enemy_scene = load("res://scenes/enemy.tscn")
	if not enemy_scene:
		print("ENEMY_SPAWNER: Failed to load enemy scene for final boss")
		return

	var boss = enemy_scene.instantiate()
	boss.global_position = spawn_pos
	boss.set_as_boss()
	boss.health = 30
	boss.max_health = 30
	boss.scale = Vector2(3.0, 3.0)
	boss.bounce_force = 1200.0

	boss.enemy_died.connect(_on_enemy_died)

	get_parent().add_child(boss)
	active_enemies.append(boss)

	final_boss_appeared.emit(boss)
	print("ENEMY_SPAWNER: Final boss spawned with 30 HP")

func _find_spawn_position() -> Vector2:
	var spawn_y = camera.global_position.y + spawn_distance_ahead
	var screen_center_x = camera.global_position.x
	var spawn_range = 200.0

	var random_x = screen_center_x + randf_range(-spawn_range, spawn_range)

	return Vector2(random_x, spawn_y)

func _on_enemy_died(enemy: Enemy) -> void:
	print("ENEMY_SPAWNER: Enemy died, removing from active list")
	active_enemies.erase(enemy)

func _on_game_started() -> void:
	start_spawning()

func _on_game_over(_final_score: int) -> void:
	stop_spawning()

func start_spawning() -> void:
	is_spawning = true
	spawn_timer = 0.0
	game_timer = 0.0
	final_boss_has_spawned = false
	_update_next_spawn_time()
	print("ENEMY_SPAWNER: Started spawning enemies")

func stop_spawning() -> void:
	is_spawning = false
	print("ENEMY_SPAWNER: Stopped spawning enemies")

func clear_all_enemies() -> void:
	for enemy in active_enemies.duplicate():
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
