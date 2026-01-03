extends Node2D

@onready var player = $Player
@onready var camera = $Camera2D
@onready var platform_spawner = $PlatformSpawner
@onready var score_label = $UI/ScoreLabel
@onready var highscore_label = $UI/HighscoreLabel
@onready var start_overlay = $UI/StartOverlay
@onready var game_over_overlay = $UI/GameOverOverlay
@onready var final_score_label = $UI/GameOverOverlay/VBoxContainer/FinalScoreLabel
@onready var powerup_notification = $UI/PowerupNotification
@onready var powerup_name_label = $UI/PowerupNotification/VBoxContainer/PowerupName
@onready var powerup_description_label = $UI/PowerupNotification/VBoxContainer/PowerupDescription

var game_started = false

func _ready():
	add_to_group("game_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().paused = true

	player.score_changed.connect(_on_score_changed)
	player.died.connect(_on_player_died)

	var powerup_component = player.get_node("PowerupComponent")
	powerup_component.powerup_collected.connect(_on_powerup_collected)

	score_label.text = "Score: 0"
	highscore_label.text = "Best: " + str(SaveGame.get_highscore())

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
	player.highest_position = player.global_position.y
	player.last_score_position = player.global_position.y
	if player.animation_player:
		player.animation_player.play("RESET")
		player.animation_player.play("idle")

	camera.start_scrolling()

	EventBus.game_started.emit()

	score_label.text = "0m"
	highscore_label.text = "Best: " + str(SaveGame.get_highscore()) + "m"

func _process(_delta):
	if not player.is_dead:
		var viewport_height = get_viewport().get_visible_rect().size.y
		var camera_bottom = camera.position.y + viewport_height / 2
		var player_half_height = 71

		if player.position.y + player_half_height > camera_bottom:
			player.die()

func _on_score_changed(score):
	score_label.text = str(score) + "m"

	if score > SaveGame.get_highscore():
		highscore_label.text = "Best: " + str(score) + "m"

func _on_player_died(final_score):
	camera.stop_scrolling()

	platform_spawner.set_process(false)

	for platform in get_tree().get_nodes_in_group("platforms"):
		platform.set_physics_process(false)

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
				"description": "Next jump is 50% higher!"
			}
		"DOUBLE_JUMP":
			return {
				"name": "DOUBLE JUMP!",
				"description": "Press jump in mid-air for one double jump!"
			}
		"ROCKET":
			return {
				"name": "ROCKET!",
				"description": "+100 meters instantly!"
			}
		"WALL":
			return {
				"name": "WALL GUARD!",
				"description": "Side walls for 5 seconds!"
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
