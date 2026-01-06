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
@export var bounce_force: float = 600.0
@export var is_boss: bool = false

var player: CharacterBody2D = null
var movement_direction: Vector2 = Vector2.ZERO
var time_alive: float = 0.0
var movement_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var head_detection_area: Area2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")
	print("ENEMY: Ready, player found: ", player != null)

	_choose_new_direction()
	_setup_head_detection()

	if is_boss:
		scale = Vector2(2.0, 2.0)
		health = 10
		max_health = 10
		bounce_force = 900.0

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

	var downward_force = Vector2(0, move_speed * 0.5)
	velocity = movement_direction * move_speed + float_offset + downward_force

	move_and_slide()

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider == player:
			var is_stomping = player.global_position.y < global_position.y - 20 and player.velocity.y > 0

			if not is_stomping:
				var bounce_direction = (player.global_position - global_position).normalized()
				player.velocity = bounce_direction * bounce_force
				print("ENEMY: Player hit enemy body from side, bouncing away!")
			else:
				print("ENEMY: Player is stomping from above, not bouncing (head detection will handle this)")

func _choose_new_direction() -> void:
	var angle = randf() * TAU
	movement_direction = Vector2(cos(angle), sin(angle))

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
	bounce_force = 900.0
	_update_health_bar()

func _setup_head_detection() -> void:
	head_detection_area = Area2D.new()
	head_detection_area.name = "HeadDetectionArea"
	head_detection_area.collision_layer = 0
	head_detection_area.collision_mask = 1
	head_detection_area.monitorable = false
	head_detection_area.monitoring = true

	var head_collision = CollisionShape2D.new()
	var head_shape = RectangleShape2D.new()
	head_shape.size = Vector2(60, 30)
	head_collision.shape = head_shape
	head_collision.position = Vector2(0, -50)

	head_detection_area.add_child(head_collision)
	add_child(head_detection_area)

	head_detection_area.body_entered.connect(_on_head_area_entered)
	print("ENEMY: Head detection area created at position: ", head_collision.position, " with size: ", head_shape.size)

func _on_head_area_entered(body: Node2D) -> void:
	print("ENEMY: Head area entered by: ", body.name, " velocity.y: ", body.get("velocity"))

	if body == player:
		print("ENEMY: Player detected! Player velocity.y: ", player.velocity.y)

		if player.velocity.y > 0:
			print("ENEMY: Player landed on head! Killing enemy and bouncing player")

			player.velocity.y = -800.0

			var xp_manager = get_tree().get_first_node_in_group("xp_manager")
			if xp_manager and xp_manager.has_method("add_xp"):
				if is_boss:
					xp_manager.add_xp(20)
				else:
					xp_manager.add_xp(5)

			EventBus.play_sound.emit("bounce")

			die()
		else:
			print("ENEMY: Player hit head but not falling (velocity.y <= 0)")
