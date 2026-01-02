extends Camera2D

@export var scroll_speed: float = 80.0
@export var game_active: bool = false

func _ready():
	game_active = false

func _process(delta):
	if game_active:
		position.y -= scroll_speed * delta

func start_scrolling():
	game_active = true

func stop_scrolling():
	game_active = false
