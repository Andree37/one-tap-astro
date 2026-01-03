extends Node

class_name PowerupComponent

signal powerup_collected(powerup_type: String)
signal powerup_expired(powerup_type: String)

enum PowerupType {
	JUMP_BOOST,
	DOUBLE_JUMP,
	ROCKET,
	WALL
}

var active_powerups: Dictionary = {}

@onready var player: CharacterBody2D = get_parent()

func _ready() -> void:
	EventBus.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	clear_all_powerups()

func collect_powerup(type: PowerupType, duration: float = 10.0) -> void:
	print("POWERUP: collect_powerup called with type: ", PowerupType.keys()[type])
	match type:
		PowerupType.JUMP_BOOST:
			print("POWERUP: Activating JUMP_BOOST")
			activate_jump_boost(duration)
		PowerupType.DOUBLE_JUMP:
			print("POWERUP: Activating DOUBLE_JUMP")
			activate_double_jump(duration)
		PowerupType.ROCKET:
			print("POWERUP: Activating ROCKET")
			activate_rocket()
		PowerupType.WALL:
			print("POWERUP: Activating WALL")
			activate_wall(duration)

	powerup_collected.emit(PowerupType.keys()[type])
	print("POWERUP: Emitted powerup_collected signal")
	EventBus.play_sound.emit("powerup")

func activate_jump_boost(_duration: float) -> void:
	if active_powerups.has("jump_boost"):
		return

	active_powerups["jump_boost_original"] = player.JUMP_FORCE
	active_powerups["jump_boost_uses"] = 1
	player.JUMP_FORCE *= 1.5
	print("POWERUP: Jump boost activated - 1 use available, force: ", player.JUMP_FORCE)

func activate_double_jump(_duration: float) -> void:
	if active_powerups.has("double_jump"):
		return

	player.can_double_jump = true
	player.double_jump_available = true
	active_powerups["double_jump_uses"] = 1
	print("POWERUP: Double jump activated - 1 use available")

func activate_rocket() -> void:
	var boost_meters = 100
	var boost_distance = boost_meters * 50.0
	print("POWERUP: ROCKET activated! Boosting ", boost_meters, " meters (", boost_distance, " pixels)")

	var camera = player.get_viewport().get_camera_2d()
	var target_y = player.global_position.y - boost_distance
	var screen_center_x = camera.global_position.x
	var landing_pos = Vector2(screen_center_x, target_y + 100)

	player.velocity = Vector2.ZERO
	player.can_jump = false
	print("POWERUP: Starting rocket tween from ", player.global_position.y, " to ", target_y)

	var spawner = player.get_tree().get_root().get_node("Main/PlatformSpawner")
	spawner.pause_spawning_for(1.5)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(player, "global_position:y", target_y, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position:x", screen_center_x, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "position:y", target_y, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.chain().tween_callback(func():
		player.highest_position = player.global_position.y
		player.last_score_position = player.global_position.y

		print("POWERUP: Rocket tween complete, adding ", boost_meters, " points")
		for i in range(boost_meters):
			player.add_score()

		call_deferred("spawn_landing_platform", landing_pos)

		# Spawn a few extra platforms after rocket to ensure player has something to jump to
		get_tree().create_timer(0.3).timeout.connect(func():
			for i in range(3):
				spawner.spawn_platform()
		)
	)

func spawn_landing_platform(position: Vector2) -> void:
	var platform_scene = load("res://scenes/platform.tscn")
	var platform = platform_scene.instantiate()
	platform.global_position = position
	platform.speed = 100.0

	var main_scene = player.get_tree().get_root().get_node("Main")
	main_scene.add_child(platform)
	print("POWERUP: Spawned landing platform at ", position)

	get_tree().create_timer(5.0).timeout.connect(func():
		if is_instance_valid(platform):
			platform.queue_free()
	)

func activate_wall(_duration: float) -> void:
	if active_powerups.has("wall"):
		if active_powerups["wall"] is SceneTreeTimer:
			active_powerups["wall"].timeout.disconnect(remove_walls)
		active_powerups.erase("wall")

	if not active_powerups.has("left_wall_node"):
		call_deferred("spawn_walls")

	print("POWERUP: Wall powerup activated")

	var timer = get_tree().create_timer(5.0)
	active_powerups["wall"] = timer

	timer.timeout.connect(func():
		remove_walls()
		active_powerups.erase("wall")
		print("POWERUP: Wall powerup expired")
		powerup_expired.emit("WALL")
	)

func spawn_walls() -> void:
	var camera = player.get_viewport().get_camera_2d()
	var viewport_width = player.get_viewport().get_visible_rect().size.x
	var screen_center_x = camera.global_position.x

	var left_wall = StaticBody2D.new()
	left_wall.name = "LeftWall"
	left_wall.collision_layer = 2
	left_wall.collision_mask = 1

	var left_collision = CollisionShape2D.new()
	var left_shape = RectangleShape2D.new()
	left_shape.size = Vector2(20, 10000)
	left_collision.shape = left_shape
	left_wall.add_child(left_collision)

	var left_sprite = Polygon2D.new()
	left_sprite.polygon = PackedVector2Array([
		Vector2(-10, -5000),
		Vector2(10, -5000),
		Vector2(10, 5000),
		Vector2(-10, 5000)
	])
	left_sprite.color = Color(0.7, 0.7, 0.7, 0.5)
	left_wall.add_child(left_sprite)

	left_wall.global_position = Vector2(screen_center_x - viewport_width / 2 + 10, camera.global_position.y)

	var right_wall = StaticBody2D.new()
	right_wall.name = "RightWall"
	right_wall.collision_layer = 2
	right_wall.collision_mask = 1

	var right_collision = CollisionShape2D.new()
	var right_shape = RectangleShape2D.new()
	right_shape.size = Vector2(20, 10000)
	right_collision.shape = right_shape
	right_wall.add_child(right_collision)

	var right_sprite = Polygon2D.new()
	right_sprite.polygon = PackedVector2Array([
		Vector2(-10, -5000),
		Vector2(10, -5000),
		Vector2(10, 5000),
		Vector2(-10, 5000)
	])
	right_sprite.color = Color(0.7, 0.7, 0.7, 0.5)
	right_wall.add_child(right_sprite)

	right_wall.global_position = Vector2(screen_center_x + viewport_width / 2 - 10, camera.global_position.y)

	var main_scene = player.get_tree().get_root().get_node("Main")
	main_scene.add_child(left_wall)
	main_scene.add_child(right_wall)

	active_powerups["left_wall_node"] = left_wall
	active_powerups["right_wall_node"] = right_wall

	print("POWERUP: Walls spawned at x positions: ", left_wall.global_position.x, " and ", right_wall.global_position.x)

func remove_walls() -> void:
	if active_powerups.has("left_wall_node"):
		var left_wall = active_powerups["left_wall_node"]
		if is_instance_valid(left_wall):
			left_wall.queue_free()
		active_powerups.erase("left_wall_node")

	if active_powerups.has("right_wall_node"):
		var right_wall = active_powerups["right_wall_node"]
		if is_instance_valid(right_wall):
			right_wall.queue_free()
		active_powerups.erase("right_wall_node")

	print("POWERUP: Walls removed")

func consume_jump_boost() -> void:
	if not active_powerups.has("jump_boost_uses"):
		return

	var uses = active_powerups["jump_boost_uses"]
	uses -= 1

	if uses <= 0:
		# Restore original jump force
		if active_powerups.has("jump_boost_original"):
			player.JUMP_FORCE = active_powerups["jump_boost_original"]
			active_powerups.erase("jump_boost_original")
		active_powerups.erase("jump_boost_uses")
		print("POWERUP: Jump boost consumed and expired")
		powerup_expired.emit("JUMP_BOOST")
	else:
		active_powerups["jump_boost_uses"] = uses

func consume_double_jump() -> void:
	if not active_powerups.has("double_jump_uses"):
		return

	var uses = active_powerups["double_jump_uses"]
	uses -= 1

	if uses <= 0:
		# Disable double jump
		player.can_double_jump = false
		player.double_jump_available = false
		active_powerups.erase("double_jump_uses")
		print("POWERUP: Double jump consumed and expired")
		powerup_expired.emit("DOUBLE_JUMP")
	else:
		active_powerups["double_jump_uses"] = uses

func has_powerup(powerup_name: String) -> bool:
	return active_powerups.has(powerup_name)

func clear_all_powerups() -> void:
	for powerup in active_powerups.values():
		if powerup is SceneTreeTimer:
			powerup.timeout.emit()
	active_powerups.clear()

func get_active_powerups() -> Array:
	return active_powerups.keys()
