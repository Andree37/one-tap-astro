extends Camera2D

@export var scroll_speed: float = 80.0
@export var game_active: bool = false
@export var speedup_zone_height: float = 250.0
@export var max_speedup_multiplier: float = 5.0

var base_scroll_speed: float = 80.0
var player: CharacterBody2D = null

func _ready():
	game_active = false
	base_scroll_speed = scroll_speed
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if game_active and player:
		var viewport_height = get_viewport().get_visible_rect().size.y
		var camera_top = position.y - viewport_height / 2
		var player_distance_from_top = player.global_position.y - camera_top

		if player_distance_from_top < speedup_zone_height:
			var proximity = 1.0 - (player_distance_from_top / speedup_zone_height)
			proximity = clamp(proximity, 0.0, 1.0)

			var speedup = 1.0 + (max_speedup_multiplier - 1.0) * pow(proximity, 2.0)
			scroll_speed = base_scroll_speed * speedup
		else:
			scroll_speed = lerp(scroll_speed, base_scroll_speed, 0.1)

		position.y -= scroll_speed * delta

func start_scrolling():
	game_active = true
	scroll_speed = base_scroll_speed

func stop_scrolling():
	game_active = false
