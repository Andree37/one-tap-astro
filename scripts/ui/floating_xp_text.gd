extends Label

var lifetime: float = 1.0
var float_speed: float = 50.0
var fade_start_time: float = 0.5

func _ready() -> void:
	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "position:y", position.y - float_speed, lifetime)
	tween.tween_property(self, "modulate:a", 0.0, lifetime - fade_start_time).set_delay(fade_start_time)
	tween.tween_callback(queue_free).set_delay(lifetime)

func set_xp_amount(amount: int) -> void:
	text = "+%d XP" % amount

	if amount >= 5:
		label_settings.font_color = Color(0.0, 1.0, 0.0, 1.0)
	else:
		label_settings.font_color = Color(1.0, 1.0, 0.0, 1.0)
