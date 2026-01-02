extends Resource
class_name GameSettings

@export_group("Platform Spawning")
@export_range(0.5, 3.0, 0.1) var min_spawn_time: float = 1.0
@export_range(1.0, 5.0, 0.1) var max_spawn_time: float = 3.0
@export_range(50, 300, 10) var platform_speed: float = 100.0
@export_range(3.0, 10.0, 0.5) var platform_lifetime: float = 7.0

@export_group("Player Physics")
@export_range(200, 800, 50) var jump_velocity: float = 400.0
@export_range(400, 1000, 50) var max_jump_velocity: float = 600.0
@export_range(100, 500, 25) var jump_charge_rate: float = 200.0
@export_range(1.0, 5.0, 0.1) var fall_multiplier: float = 2.0
@export_range(0.1, 0.5, 0.05) var jump_threshold: float = 0.2

@export_group("Scoring")
@export_range(1, 5, 1) var points_per_landing: int = 1
@export_range(2, 5, 1) var max_multiplier: int = 2
@export_range(1, 10, 1) var multiplier_linger_jumps: int = 3
@export_range(5.0, 30.0, 1.0) var perfect_landing_threshold: float = 10.0

@export_group("Difficulty Progression")
@export var enable_difficulty_scaling: bool = false
@export_range(0.0, 2.0, 0.1) var speed_increase_per_point: float = 0.5
@export_range(0.0, 1.0, 0.05) var spawn_rate_increase: float = 0.05
@export_range(5, 50, 5) var max_speed: int = 200

@export_group("Audio")
@export_range(-20.0, 0.0, 1.0) var master_volume: float = 0.0
@export_range(-20.0, 0.0, 1.0) var sfx_volume: float = 0.0
@export_range(-20.0, 0.0, 1.0) var music_volume: float = -10.0

@export_group("Visual Effects")
@export var enable_screen_shake: bool = true
@export_range(0.0, 10.0, 0.5) var screen_shake_intensity: float = 3.0
@export var enable_particles: bool = true
@export var enable_trail_effect: bool = false

@export_group("Mobile Settings")
@export var enable_haptic_feedback: bool = true
@export var vibration_intensity: float = 1.0

func apply_easy_preset():
	min_spawn_time = 1.5
	max_spawn_time = 4.0
	platform_speed = 80.0
	jump_velocity = 450.0
	fall_multiplier = 1.5
	enable_difficulty_scaling = false

func apply_normal_preset():
	min_spawn_time = 1.0
	max_spawn_time = 3.0
	platform_speed = 100.0
	jump_velocity = 400.0
	fall_multiplier = 2.0
	enable_difficulty_scaling = false

func apply_hard_preset():
	min_spawn_time = 0.7
	max_spawn_time = 2.0
	platform_speed = 150.0
	jump_velocity = 380.0
	fall_multiplier = 2.5
	enable_difficulty_scaling = true
	speed_increase_per_point = 0.8

func apply_endless_preset():
	apply_normal_preset()
	enable_difficulty_scaling = true
	speed_increase_per_point = 1.0
	spawn_rate_increase = 0.1
	max_speed = 250
