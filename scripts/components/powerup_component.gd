extends Node

class_name PowerupComponent

signal powerup_collected(powerup_type: String)
signal powerup_expired(powerup_type: String)

enum PowerupType {
	JUMP_BOOST,
	DOUBLE_JUMP,
	ROCKET,
	WALL,
	SPEED_BOOST,
	MAGNET_SHIELD,
	XP_MULTIPLIER
}

var active_powerups: Dictionary = {}

@onready var player: CharacterBody2D = get_parent()

func _ready() -> void:
	EventBus.game_started.connect(_on_game_started)

func _on_game_started() -> void:
	clear_all_powerups()

func collect_powerup(type: PowerupType, duration: float = 20.0) -> void:
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
		PowerupType.SPEED_BOOST:
			print("POWERUP: Activating SPEED_BOOST")
			activate_speed_boost(duration)
		PowerupType.MAGNET_SHIELD:
			print("POWERUP: Activating MAGNET_SHIELD")
			activate_magnet_shield(duration)
		PowerupType.XP_MULTIPLIER:
			print("POWERUP: Activating XP_MULTIPLIER")
			activate_xp_multiplier(duration)

	powerup_collected.emit(PowerupType.keys()[type])
	print("POWERUP: Emitted powerup_collected signal")
	EventBus.play_sound.emit("powerup")

func activate_jump_boost(_duration: float) -> void:
	if active_powerups.has("jump_boost"):
		return

	active_powerups["jump_boost_original"] = player.JUMP_FORCE
	active_powerups["jump_boost_uses"] = 3
	player.JUMP_FORCE *= 1.5
	print("POWERUP: Jump boost activated - 3 uses available")

func activate_double_jump(_duration: float) -> void:
	if active_powerups.has("double_jump"):
		return

	player.can_double_jump = true
	player.double_jump_available = true
	active_powerups["double_jump_uses"] = 3
	print("POWERUP: Double jump activated - 3 uses available")

func activate_rocket() -> void:
	var boost_meters = 100
	var boost_distance = boost_meters * 50.0
	print("POWERUP: ROCKET activated! Boosting ", boost_meters, " meters (", boost_distance, " pixels)")

	var camera = player.get_viewport().get_camera_2d()
	var start_y = player.global_position.y
	var target_y = start_y - boost_distance
	var screen_center_x = camera.global_position.x

	player.velocity = Vector2.ZERO
	player.can_jump = false
	print("POWERUP: Starting rocket tween from ", start_y, " to ", target_y)

	var spawner = player.get_tree().get_root().get_node("Main/PlatformSpawner")
	spawner.pause_spawning_for(8.0)

	call_deferred("spawn_rocket_platforms", start_y, target_y, screen_center_x)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(player, "global_position:y", target_y, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position:x", screen_center_x, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "position:y", target_y, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.chain().tween_callback(func():
		player.highest_position = player.global_position.y
		player.highest_position_ever = player.global_position.y
		player.last_score_position = player.global_position.y

		print("POWERUP: Rocket tween complete, adding ", boost_meters, " points")
		for i in range(boost_meters):
			player.add_score()
	)

func spawn_rocket_platforms(start_y: float, target_y: float, center_x: float) -> void:
	var platform_scene = load("res://scenes/platform.tscn")
	var main_scene = player.get_tree().get_root().get_node("Main")

	var num_platforms = 6
	var step = (start_y - target_y) / float(num_platforms)

	for i in range(1, num_platforms):
		var platform = platform_scene.instantiate()
		var y_pos = start_y - (step * i)
		var x_offset = randf_range(-150, 150)
		platform.global_position = Vector2(center_x + x_offset, y_pos)
		platform.speed = 0.0

		main_scene.add_child(platform)

		get_tree().create_timer(15.0).timeout.connect(func():
			if is_instance_valid(platform):
				platform.queue_free()
		)

	var landing_platform = platform_scene.instantiate()
	landing_platform.global_position = Vector2(center_x, target_y + 100)
	landing_platform.speed = 0.0
	main_scene.add_child(landing_platform)

	get_tree().create_timer(15.0).timeout.connect(func():
		if is_instance_valid(landing_platform):
			landing_platform.queue_free()
	)

	print("POWERUP: Spawned ", num_platforms, " stationary platforms along rocket path")

func activate_wall(_duration: float) -> void:
	if active_powerups.has("wall"):
		if active_powerups["wall"] is SceneTreeTimer:
			active_powerups["wall"].timeout.disconnect(remove_walls)
		active_powerups.erase("wall")

	if not active_powerups.has("left_wall_node"):
		call_deferred("spawn_walls")

	print("POWERUP: Wall powerup activated for ", _duration, " seconds")

	var timer = get_tree().create_timer(_duration)
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


func consume_jump_boost() -> void:
	if not active_powerups.has("jump_boost_uses"):
		return

	var uses = active_powerups["jump_boost_uses"]
	uses -= 1

	if uses <= 0:
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
		player.can_double_jump = false
		player.double_jump_available = false
		active_powerups.erase("double_jump_uses")
		print("POWERUP: Double jump consumed and expired")
		powerup_expired.emit("DOUBLE_JUMP")
	else:
		active_powerups["double_jump_uses"] = uses

func has_powerup(powerup_name: String) -> bool:
	return active_powerups.has(powerup_name)

func is_magnet_shield_active() -> bool:
	return active_powerups.has("magnet_shield_active")

func clear_all_powerups() -> void:
	for powerup in active_powerups.values():
		if powerup is SceneTreeTimer:
			powerup.timeout.emit()
	active_powerups.clear()

func get_active_powerups() -> Array:
	return active_powerups.keys()

func activate_speed_boost(duration: float) -> void:
	print("POWERUP: Speed boost activated for ", duration, " seconds")

func activate_magnet_shield(duration: float) -> void:
	if active_powerups.has("magnet_shield"):
		if active_powerups["magnet_shield"] is SceneTreeTimer:
			active_powerups["magnet_shield"].timeout.disconnect(_deactivate_magnet_shield)
		active_powerups.erase("magnet_shield")

	active_powerups["magnet_shield_active"] = true
	print("POWERUP: Magnet shield activated for ", duration, " seconds")

	var timer = get_tree().create_timer(duration)
	active_powerups["magnet_shield"] = timer
	timer.timeout.connect(_deactivate_magnet_shield)

func _deactivate_magnet_shield() -> void:
	active_powerups.erase("magnet_shield_active")
	active_powerups.erase("magnet_shield")
	print("POWERUP: Magnet shield expired")
	powerup_expired.emit("MAGNET_SHIELD")

func activate_xp_multiplier(duration: float) -> void:
	if active_powerups.has("xp_multiplier"):
		if active_powerups["xp_multiplier"] is SceneTreeTimer:
			active_powerups["xp_multiplier"].timeout.disconnect(_deactivate_xp_multiplier)
		active_powerups.erase("xp_multiplier")

	active_powerups["xp_multiplier_active"] = 2.0
	print("POWERUP: XP multiplier (2x) activated for ", duration, " seconds")

	var timer = get_tree().create_timer(duration)
	active_powerups["xp_multiplier"] = timer
	timer.timeout.connect(_deactivate_xp_multiplier)

func _deactivate_xp_multiplier() -> void:
	active_powerups.erase("xp_multiplier_active")
	active_powerups.erase("xp_multiplier")
	print("POWERUP: XP multiplier expired")
	powerup_expired.emit("XP_MULTIPLIER")

func get_xp_multiplier() -> float:
	if active_powerups.has("xp_multiplier_active"):
		return active_powerups["xp_multiplier_active"]
	return 1.0
