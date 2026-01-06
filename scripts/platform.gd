extends StaticBody2D

@export var speed: float = 80.0
@export var perfect_landing_zone_width: float = 40.0
@export var floating_xp_text_scene: PackedScene

var player_landed: bool = false
var xp_manager: XPManager = null

@onready var perfect_zone: Area2D = null
@onready var landing_detector: Area2D = null

func _ready() -> void:
	call_deferred("_setup_xp_manager")
	call_deferred("_setup_landing_detector")
	_create_perfect_landing_zone()

func _setup_xp_manager() -> void:
	var main = get_parent()
	print("PLATFORM: Looking for Main node (parent): ", main)
	if main:
		xp_manager = main.get_node_or_null("XPManager")
		print("PLATFORM: XPManager found: ", xp_manager)
	else:
		print("PLATFORM: Main node (parent) not found!")

func _setup_landing_detector() -> void:
	landing_detector = get_node_or_null("LandingDetector")
	if landing_detector:
		landing_detector.body_entered.connect(_on_body_entered)
		landing_detector.body_exited.connect(_on_body_exited)

func _create_perfect_landing_zone() -> void:
	perfect_zone = Area2D.new()
	perfect_zone.name = "PerfectZone"
	perfect_zone.collision_layer = 0
	perfect_zone.collision_mask = 1

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(perfect_landing_zone_width, 10.0)
	collision.shape = shape
	collision.position = Vector2(0, -30)

	perfect_zone.add_child(collision)
	add_child(perfect_zone)

	perfect_zone.body_entered.connect(_on_perfect_zone_entered)

var perfect_landing_zone_active = false

func _on_perfect_zone_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		perfect_landing_zone_active = true

func _show_perfect_landing_effect() -> void:
	var original_modulate = modulate
	modulate = Color(0.0, 1.0, 0.0, 1.0)

	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, 0.3)

func _physics_process(delta):
	if speed > 0:
		position.y += speed * delta

		if position.y > 1500:
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not player_landed:
		call_deferred("_check_landing", body)

func _check_landing(body: Node2D) -> void:
	if not is_instance_valid(body) or player_landed:
		return

	if not body.is_on_floor():
		return

	if body.velocity.y < 0:
		return

	var current_score = body.current_score
	var last_xp_score = body.last_score_with_xp

	if current_score <= last_xp_score:
		print("PLATFORM: No XP - current score ", current_score, " not higher than last XP score ", last_xp_score)
		player_landed = true
		return

	player_landed = true

	if perfect_landing_zone_active:
		print("PLATFORM: PERFECT LANDING! Score: ", current_score, " (last XP at: ", last_xp_score, ")")
		if xp_manager:
			xp_manager.add_perfect_landing_xp()
			body.last_score_with_xp = current_score
			_spawn_floating_xp_text(3, true)
		else:
			print("PLATFORM: XPManager is null, cannot add XP")
		_show_perfect_landing_effect()
	else:
		print("PLATFORM: Normal landing - adding 1 XP. Score: ", current_score, " (last XP at: ", last_xp_score, ")")
		if xp_manager:
			xp_manager.add_normal_landing_xp()
			body.last_score_with_xp = current_score
			_spawn_floating_xp_text(1)
		else:
			print("PLATFORM: XPManager is null, cannot add XP")

	perfect_landing_zone_active = false

func _spawn_floating_xp_text(amount: int, is_perfect: bool = false) -> void:
	if not floating_xp_text_scene:
		return

	var floating_text = floating_xp_text_scene.instantiate()
	get_parent().add_child(floating_text)
	floating_text.global_position = global_position + Vector2(0, -40)
	floating_text.set_xp_amount(amount, is_perfect)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_landed = false
		perfect_landing_zone_active = false
