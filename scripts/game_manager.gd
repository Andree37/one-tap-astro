extends Node2D

@onready var player = $Player
@onready var camera = $Camera2D
@onready var platform_spawner = $PlatformSpawner
@onready var xp_manager = $XPManager
@onready var enemy_spawner = $EnemySpawner
@onready var score_label = $UI/ScoreLabel
@onready var highscore_label = $UI/HighscoreLabel
@onready var xp_label = $UI/XPLabel
@onready var xp_bar = $UI/XPBar
@onready var timer_label = $UI/TimerLabel
@onready var start_overlay = $UI/StartOverlay
@onready var game_over_overlay = $UI/GameOverOverlay
@onready var final_score_label = $UI/GameOverOverlay/VBoxContainer/FinalScoreLabel
@onready var powerup_notification = $UI/PowerupNotification
@onready var powerup_name_label = $UI/PowerupNotification/VBoxContainer/PowerupName
@onready var powerup_description_label = $UI/PowerupNotification/VBoxContainer/PowerupDescription

var game_started = false
var game_timer: float = 0.0

func _ready():
	add_to_group("game_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().paused = true

	player.score_changed.connect(_on_score_changed)
	player.died.connect(_on_player_died)

	var powerup_component = player.get_node("PowerupComponent")
	powerup_component.powerup_collected.connect(_on_powerup_collected)

	if xp_manager:
		xp_manager.xp_gained.connect(_on_xp_gained)
		xp_manager.level_up.connect(_on_level_up)
		xp_manager.lootbox_earned.connect(_on_lootbox_earned)

	if enemy_spawner:
		enemy_spawner.boss_spawned.connect(_on_boss_spawned)
		enemy_spawner.final_boss_appeared.connect(_on_final_boss_spawned)

	score_label.text = "Score: 0"
	highscore_label.text = "Best: " + str(SaveGame.get_highscore())
	xp_label.text = "Level: 0 | XP: 0/10"
	xp_bar.value = 0
	xp_bar.visible = true
	timer_label.text = "Time: 0:00"

	start_overlay.visible = true
	game_over_overlay.visible = false

func _unhandled_input(event):
	if not game_started and start_overlay.visible:
		if event is InputEventMouseButton and event.pressed:
			start_game()
			get_viewport().set_input_as_handled()

func _on_start_button_pressed():
	start_game()

func start_game():
	game_started = true
	start_overlay.visible = false

	get_tree().paused = false

	player.rotation = 0
	player.velocity = Vector2.ZERO
	player.current_score = 0
	player.is_dead = false
	player.can_jump = true
	player.game_active = true
	if camera:
		player.highest_camera_position = camera.global_position.y
		player.last_score_camera_position = camera.global_position.y
		player.highest_camera_position_ever = camera.global_position.y
	if player.animation_player:
		player.animation_player.play("RESET")
		player.animation_player.play("idle")

	camera.start_scrolling()

	game_timer = 0.0

	EventBus.game_started.emit()

	score_label.text = "0m"
	highscore_label.text = "Best: " + str(SaveGame.get_highscore()) + "m"
	xp_label.text = "Level: 0 | XP: 0/10"
	xp_bar.value = 0
	xp_bar.visible = true
	timer_label.text = "Time: 0:00"

func _process(delta):
	if game_started and not player.is_dead and player.game_active:
		game_timer += delta
		_update_timer_display()

func _update_timer_display() -> void:
	var minutes = int(game_timer / 60.0)
	var seconds = int(game_timer) % 60
	timer_label.text = "Time: %d:%02d" % [minutes, seconds]

func _on_score_changed(score):
	score_label.text = str(score) + "m"

	if score > SaveGame.get_highscore():
		highscore_label.text = "Best: " + str(score) + "m"

func _on_xp_gained(current_xp: int, level: int) -> void:
	var xp_in_level = current_xp - (level * 10)
	xp_label.text = "Level: %d | XP: %d/%d" % [level, xp_in_level, 10]
	xp_bar.value = xp_manager.get_xp_progress() * 10.0
	xp_bar.visible = true
	print("GAME_MANAGER: XP updated - Level: ", level, " XP: ", current_xp, " (", xp_in_level, "/10 in current level)")

func _on_level_up(new_level: int) -> void:
	print("GAME_MANAGER: Player leveled up to level ", new_level)
	show_notification("LEVEL UP!", "Level " + str(new_level))

func _on_lootbox_earned(_level: int) -> void:
	print("GAME_MANAGER: Lootbox earned at level ", _level)
	_spawn_lootbox_at_player()

func _on_boss_spawned(_boss: Enemy) -> void:
	print("GAME_MANAGER: Boss spawned!")
	show_notification("BOSS APPEARED!", "Defeat it for a reward!")

func _on_final_boss_spawned(_boss: Enemy) -> void:
	print("GAME_MANAGER: FINAL BOSS spawned!")
	show_notification("FINAL BOSS!", "Defeat it to win!")

func _spawn_lootbox_at_player() -> void:
	var lootbox_scene = load("res://scenes/lootbox.tscn")
	if not lootbox_scene:
		print("GAME_MANAGER: Failed to load lootbox scene")
		return

	var lootbox = lootbox_scene.instantiate()
	lootbox.global_position = player.global_position + Vector2(0, -150)
	add_child(lootbox)
	print("GAME_MANAGER: Spawned lootbox at player position")

func _on_player_died(final_score):
	camera.stop_scrolling()

	platform_spawner.set_process(false)

	for platform in get_tree().get_nodes_in_group("platforms"):
		platform.set_physics_process(false)

	EventBus.game_over.emit(final_score)

	if enemy_spawner:
		enemy_spawner.stop_spawning()
		enemy_spawner.clear_all_enemies()

	game_over_overlay.visible = true
	final_score_label.text = str(final_score) + " meters"

	await get_tree().create_timer(0.5).timeout
	get_tree().paused = true

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_powerup_collected(powerup_type: String) -> void:
	var powerup_info = get_powerup_info(powerup_type)
	show_notification(powerup_info.name, powerup_info.description)

func get_powerup_info(powerup_type: String) -> Dictionary:
	match powerup_type:
		"JUMP_BOOST":
			return {
				"name": "JUMP BOOST!",
				"description": "Next 3 jumps are 50% higher!"
			}
		"DOUBLE_JUMP":
			return {
				"name": "DOUBLE JUMP!",
				"description": "Press jump in mid-air! 3 uses!"
			}
		# "ROCKET":  # DISABLED - has bugs
		# 	return {
		# 		"name": "ROCKET!",
		# 		"description": "+100 meters instantly!"
		# 	}
		"WALL":
			return {
				"name": "WALL GUARD!",
				"description": "Side walls for 20 seconds!"
			}
		"XP_MULTIPLIER":
			return {
				"name": "XP MULTIPLIER!",
				"description": "2x XP for 20 seconds!"
			}
		_:
			return {
				"name": "POWERUP!",
				"description": "Unknown powerup"
			}

func show_notification(title: String, description: String) -> void:
	print("GAME_MANAGER: Showing notification: ", title)
	powerup_name_label.text = title
	powerup_description_label.text = description

	powerup_notification.visible = true
	powerup_notification.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_property(powerup_notification, "modulate:a", 0.0, 0.8).set_delay(1.5)
	tween.tween_callback(func(): powerup_notification.visible = false)
