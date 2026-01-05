extends Area2D

class_name Lootbox

signal powerup_selected(powerup_type: int)

var is_open: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	print("LOOTBOX: Ready - clickable from anywhere on screen")
	_start_pulse_animation()

func _start_pulse_animation() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _input(event: InputEvent) -> void:
	if is_open:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_visible_on_screen() and _is_click_on_lootbox(event.position):
			open_lootbox()
			get_viewport().set_input_as_handled()

	if event.is_action_pressed("jump") and _is_visible_on_screen():
		open_lootbox()
		get_viewport().set_input_as_handled()

func _is_visible_on_screen() -> bool:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return false

	var viewport_rect = get_viewport_rect()
	var camera_pos = camera.get_screen_center_position()
	var camera_zoom = camera.zoom

	var half_screen = viewport_rect.size / (2.0 * camera_zoom)
	var screen_rect = Rect2(camera_pos - half_screen, half_screen * 2)
	return screen_rect.has_point(global_position)

func _is_click_on_lootbox(click_position: Vector2) -> bool:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return false

	var world_pos = camera.get_screen_center_position() + (click_position - get_viewport_rect().size / 2) / camera.zoom
	var lootbox_rect = Rect2(global_position - Vector2(40, 40), Vector2(80, 80))
	return lootbox_rect.has_point(world_pos)

func open_lootbox() -> void:
	if is_open:
		return

	is_open = true
	print("LOOTBOX: Opening lootbox!")

	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		player_node.game_active = false

	get_tree().paused = true
	_show_powerup_selection()

func _show_powerup_selection() -> void:
	var ui = get_tree().get_root().get_node_or_null("Main/UI/PowerupSelectionUI")

	if not ui:
		print("LOOTBOX: PowerupSelectionUI not found, creating it")
		var ui_scene = load("res://scenes/powerup_selection_ui.tscn")
		if ui_scene:
			ui = ui_scene.instantiate()
			var main_ui = get_tree().get_root().get_node("Main/UI")
			main_ui.add_child(ui)
		else:
			print("LOOTBOX: Failed to load powerup_selection_ui.tscn")
			get_tree().paused = false
			queue_free()
			return

	var powerup_options = _generate_powerup_options()

	ui.show_options(powerup_options)
	ui.powerup_selected.connect(_on_powerup_selected)

func _generate_powerup_options() -> Array:
	var all_powerups = [
		{"type": 0, "name": "Jump Boost", "description": "Next jump is 50% higher!"},
		{"type": 1, "name": "Double Jump", "description": "Press jump in mid-air!"},
		{"type": 2, "name": "Rocket", "description": "+100 meters instantly!"},
		{"type": 3, "name": "Wall Guard", "description": "Side walls for 5 seconds!"},
		{"type": 4, "name": "Speed Boost", "description": "Move faster for 10 seconds!"},
		{"type": 5, "name": "Magnet Shield", "description": "Immune to enemy magnets!"},
		{"type": 6, "name": "XP Multiplier", "description": "2x XP for 30 seconds!"},
	]

	all_powerups.shuffle()
	return all_powerups.slice(0, 3)

func _on_powerup_selected(powerup_data: Dictionary) -> void:
	print("LOOTBOX: Powerup selected: ", powerup_data.name)

	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		var powerup_component = player_node.get_node_or_null("PowerupComponent")
		if powerup_component:
			powerup_component.collect_powerup(powerup_data.type, 10.0)

	powerup_selected.emit(powerup_data.type)

	if player_node:
		player_node.game_active = true

	get_tree().paused = false
	queue_free()
