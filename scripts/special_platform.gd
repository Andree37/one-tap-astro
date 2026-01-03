extends StaticBody2D

class_name SpecialPlatform

enum PlatformType {
	NORMAL,
	BOUNCE
}

@export var platform_type: PlatformType = PlatformType.NORMAL
@export var speed: float = 80.0
@export var bounce_multiplier: float = 1.5

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var area = $Area2D

var player_on_platform: bool = false
var powerup_collected: bool = false

func _ready() -> void:
	if area and not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)
	setup_platform_appearance()

func setup_platform_appearance() -> void:
	match platform_type:
		PlatformType.NORMAL:
			sprite.modulate = Color.WHITE
		PlatformType.BOUNCE:
			sprite.modulate = Color(0.0, 1.0, 0.0)

func _physics_process(delta: float) -> void:
	if speed > 0:
		position.y += speed * delta
		if position.y > 1500:
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	print("COLLISION DETECTED with: ", body.name)

	if not body.is_in_group("player"):
		print("Not in player group, returning")
		return

	if powerup_collected:
		print("Powerup already collected")
		return

	print("Platform type: ", platform_type)

	match platform_type:
		PlatformType.BOUNCE:
			print("Applying BOUNCE")
			apply_bounce(body)
			show_platform_notification("BOUNCE PLATFORM!", "You bounced higher!")

func apply_bounce(body: CharacterBody2D) -> void:
	body.velocity.y = -abs(body.velocity.y) * bounce_multiplier
	EventBus.play_sound.emit("bounce")



func set_speed(new_speed: float) -> void:
	speed = new_speed

func on_pool_activate() -> void:
	powerup_collected = false
	sprite.modulate.a = 1.0
	setup_platform_appearance()

func on_pool_deactivate() -> void:
	powerup_collected = false

func show_platform_notification(title: String, description: String) -> void:
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("show_notification"):
		game_manager.show_notification(title, description)
