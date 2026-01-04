extends Node

class_name DifficultyManager

signal difficulty_changed(level: int)
signal speed_increased(new_speed: float)

@export var base_platform_speed: float = 80.0
@export var base_camera_speed: float = 80.0
@export var base_spawn_time_min: float = 0.8
@export var base_spawn_time_max: float = 1.5

@export var speed_increase_per_level: float = 10.0
@export var spawn_time_decrease_per_level: float = 0.1
@export var meters_per_difficulty_level: int = 10

var current_difficulty_level: int = 0
var current_platform_speed: float = 80.0
var current_camera_speed: float = 80.0
var current_spawn_time_min: float = 0.8
var current_spawn_time_max: float = 1.5

var max_platform_speed: float = 200.0
var max_camera_speed: float = 150.0
var min_spawn_time: float = 0.5

var special_platform_chance: float = 0.0
var powerup_platform_chance: float = 0.0

func _ready() -> void:
	EventBus.score_changed.connect(_on_score_changed)
	EventBus.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	reset_difficulty()

func reset_difficulty() -> void:
	current_difficulty_level = 0
	current_platform_speed = base_platform_speed
	current_camera_speed = base_camera_speed
	current_spawn_time_min = base_spawn_time_min
	current_spawn_time_max = base_spawn_time_max
	special_platform_chance = 0.0
	powerup_platform_chance = 0.0

func _on_score_changed(score: int) -> void:
	var new_level = int(score / float(meters_per_difficulty_level))

	if new_level > current_difficulty_level:
		current_difficulty_level = new_level
		update_difficulty()
		difficulty_changed.emit(current_difficulty_level)

func update_difficulty() -> void:
	current_platform_speed = min(
		base_platform_speed + (current_difficulty_level * speed_increase_per_level),
		max_platform_speed
	)

	current_camera_speed = min(
		base_camera_speed + (current_difficulty_level * speed_increase_per_level * 0.8),
		max_camera_speed
	)

	current_spawn_time_min = max(
		base_spawn_time_min - (current_difficulty_level * spawn_time_decrease_per_level),
		min_spawn_time
	)

	current_spawn_time_max = max(
		base_spawn_time_max - (current_difficulty_level * spawn_time_decrease_per_level),
		min_spawn_time + 0.5
	)

	special_platform_chance = min(0.1 + (current_difficulty_level * 0.02), 0.3)
	powerup_platform_chance = min(0.1 + (current_difficulty_level * 0.02), 0.3)

	speed_increased.emit(current_platform_speed)

func get_platform_speed() -> float:
	return current_platform_speed

func get_camera_speed() -> float:
	return current_camera_speed

func get_spawn_time_range() -> Vector2:
	return Vector2(current_spawn_time_min, current_spawn_time_max)

func should_spawn_special_platform() -> bool:
	return randf() < special_platform_chance

func should_spawn_powerup_platform() -> bool:
	return randf() < powerup_platform_chance

func get_difficulty_level() -> int:
	return current_difficulty_level
