extends Area2D

class_name PowerupPickup

enum PowerupType {
	JUMP_BOOST,
	DOUBLE_JUMP,
	ROCKET,
	WALL
}

@export var powerup_type: PowerupType = PowerupType.JUMP_BOOST:
	set(value):
		powerup_type = value
		if is_node_ready():
			setup_appearance()
@export var bounce_height: float = 15.0
@export var bounce_speed: float = 4.0
@export var rotation_speed: float = 2.0

@onready var visual = $Visual
@onready var collision = $CollisionShape2D

var time_elapsed: float = 0.0
var initial_y: float = 0.0
var collected: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	initial_y = position.y

	body_entered.connect(_on_body_entered)
	setup_appearance()

func setup_appearance() -> void:
	if not visual:
		return

	print("POWERUP_PICKUP: Setting appearance for type: ", PowerupType.keys()[powerup_type])

	match powerup_type:
		PowerupType.JUMP_BOOST:
			visual.color = Color(0, 1, 0.5, 1)
		PowerupType.DOUBLE_JUMP:
			visual.color = Color(1, 0, 1, 1)
		PowerupType.ROCKET:
			visual.color = Color(1, 0, 0, 1)
		PowerupType.WALL:
			visual.color = Color(0.7, 0.7, 0.7, 1)

func _process(delta: float) -> void:
	if collected:
		return

	time_elapsed += delta
	var offset = sin(time_elapsed * bounce_speed) * bounce_height
	position.y = initial_y + offset

	if visual:
		visual.rotation += rotation_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return

	if not body.is_in_group("player"):
		return

	print("PICKUP: Collected by player, type: ", PowerupType.keys()[powerup_type])

	var powerup_component = body.get_node("PowerupComponent")
	powerup_component.collect_powerup(powerup_type)

	collected = true

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
