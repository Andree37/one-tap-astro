extends StaticBody2D

var player_has_left: bool = false
var removal_timer: Timer = null

@onready var landing_detector: Area2D = $LandingDetector

func _ready() -> void:
	if landing_detector:
		landing_detector.body_exited.connect(_on_player_left)

	removal_timer = Timer.new()
	removal_timer.wait_time = 10.0
	removal_timer.one_shot = true
	removal_timer.timeout.connect(_on_timer_timeout)
	add_child(removal_timer)
	removal_timer.start()

func _on_player_left(body: Node2D) -> void:
	if body.is_in_group("player") and not player_has_left:
		player_has_left = true
		print("STARTING_PLATFORM: Player left, removing platform")
		if removal_timer:
			removal_timer.stop()
		get_tree().create_timer(0.5).timeout.connect(func():
			queue_free()
		)

func _on_timer_timeout() -> void:
	print("STARTING_PLATFORM: Timer expired, removing platform")
	queue_free()
