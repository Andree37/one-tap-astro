extends Camera2D

@export var follow_smoothness: float = 8.0
@export var y_offset: float = 200.0

var game_active: bool = false
var player: CharacterBody2D = null

func _ready():
	game_active = false
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if game_active and player:
		var target_y = player.global_position.y - y_offset
		position.y = lerp(position.y, target_y, follow_smoothness * delta)

func start_scrolling():
	game_active = true

func stop_scrolling():
	game_active = false
