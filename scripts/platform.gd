extends StaticBody2D

@export var speed: float = 80.0

func _physics_process(delta):
	if speed > 0:
		position.y += speed * delta

		if position.y > 1500:
			queue_free()
