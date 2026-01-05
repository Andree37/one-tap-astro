extends CharacterBody2D

class_name Enemy

signal enemy_died(enemy: Enemy)

enum EnemyType {
	NORMAL,
	BOSS
}

@export var enemy_type: EnemyType = EnemyType.NORMAL
@export var health: int = 3
@export var max_health: int = 3
@export var move_speed: float = 50.0
@export var magnet_radius: float = 300.0
@export var magnet_force: float = 2500.0
@export var is_boss: bool = false

var player: CharacterBody2D = null
var movement_direction: Vector2 = Vector2.ZERO
var time_alive: float = 0.0
var movement_timer: float = 0.0
var magnet_force_to_apply: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var magnet_area: Area2D = $MagnetArea
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	print("ENEMY: Ready, player found: ", player != null)

	if magnet_area:
		var magnet_collision = magnet_area.get_node("CollisionShape2D")
		if magnet_collision and magnet_collision.shape is CircleShape2D:
			magnet_collision.shape.radius = magnet_radius

	_choose_new_direction()

	if is_boss:
		scale = Vector2(2.0, 2.0)
		health = 10
		max_health = 10
		magnet_radius = 400.0
		magnet_force = 4000.0

	_update_health_bar()

func _physics_process(delta: float) -> void:
	time_alive += delta
	movement_timer += delta

	if movement_timer >= 2.0:
		_choose_new_direction()
		movement_timer = 0.0

	var float_offset = Vector2(
		sin(time_alive * 1.5) * 30.0,
		cos(time_alive * 2.0) * 20.0
	)

	velocity = movement_direction * move_speed + float_offset

	if player and is_instance_valid(player):
		_apply_magnet_force_to_player(delta)

	move_and_slide()

func _choose_new_direction() -> void:
	var angle = randf() * TAU
	movement_direction = Vector2(cos(angle), sin(angle))

func _apply_magnet_force_to_player(_delta: float) -> void:
	var powerup_component = player.get_node_or_null("PowerupComponent")
	if powerup_component and powerup_component.is_magnet_shield_active():
		magnet_force_to_apply = Vector2.ZERO
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player < magnet_radius:
		var direction_away = (player.global_position - global_position).normalized()
		var force_strength = magnet_force * (1.0 - distance_to_player / magnet_radius)
		magnet_force_to_apply = direction_away * force_strength

		if not player.has_meta("enemy_forces"):
			player.set_meta("enemy_forces", [])
		var forces = player.get_meta("enemy_forces")
		if not forces.has(self):
			forces.append(self)
	else:
		magnet_force_to_apply = Vector2.ZERO

func take_damage(amount: int) -> void:
	health -= amount
	print("ENEMY: Took ", amount, " damage. Health: ", health, "/", max_health)

	_update_health_bar()
	_flash_damage()

	if health <= 0:
		die()

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = health < max_health

func _flash_damage() -> void:
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color.WHITE

		var tween = create_tween()
		tween.tween_property(sprite, "modulate", original_modulate, 0.2)

func die() -> void:
	print("ENEMY: Died! Boss: ", is_boss)
	enemy_died.emit(self)

	if is_boss:
		_spawn_lootbox()

	queue_free()

func _spawn_lootbox() -> void:
	var lootbox_scene = load("res://scenes/lootbox.tscn")
	if lootbox_scene:
		var lootbox = lootbox_scene.instantiate()
		lootbox.global_position = global_position
		get_parent().add_child(lootbox)
		print("ENEMY: Spawned lootbox at ", global_position)
	else:
		print("ENEMY: Failed to load lootbox scene")

func set_as_boss() -> void:
	is_boss = true
	enemy_type = EnemyType.BOSS
	scale = Vector2(2.0, 2.0)
	health = 10
	max_health = 10
	magnet_radius = 400.0
	magnet_force = 4000.0
	_update_health_bar()

func get_magnet_force() -> Vector2:
	return magnet_force_to_apply
