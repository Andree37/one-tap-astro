extends Node2D

@onready var player = $Player
@onready var camera = $Camera2D
@onready var platform_spawner = $PlatformSpawner
@onready var score_label = $UI/ScoreLabel
@onready var highscore_label = $UI/HighscoreLabel
@onready var start_overlay = $UI/StartOverlay
@onready var game_over_overlay = $UI/GameOverOverlay
@onready var final_score_label = $UI/GameOverOverlay/VBoxContainer/FinalScoreLabel

var game_started = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	player.score_changed.connect(_on_score_changed)
	player.died.connect(_on_player_died)

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
	platform_spawner.set_process(true)

	score_label.text = "0m"
	highscore_label.text = "Best: " + str(SaveGame.get_highscore()) + "m"

func _process(_delta):
	if not player.is_dead:
		var viewport_height = get_viewport().get_visible_rect().size.y
		var camera_top = camera.position.y - viewport_height / 2
		var camera_bottom = camera.position.y + viewport_height / 2
		var player_half_height = 71

		if player.position.y + player_half_height < camera_top:
			player.die()

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
