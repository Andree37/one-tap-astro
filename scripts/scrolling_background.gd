extends ParallaxBackground

@export var scroll_speed: float = 50.0
@export var scroll_direction: Vector2 = Vector2.LEFT

func _process(delta):
	scroll_base_offset += scroll_direction * scroll_speed * delta
