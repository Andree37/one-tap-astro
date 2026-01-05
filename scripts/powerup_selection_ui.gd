extends Control

class_name PowerupSelectionUI

signal powerup_selected(powerup_data: Dictionary)

@onready var option1_button: Button = $Panel/VBoxContainer/HBoxContainer/Option1
@onready var option2_button: Button = $Panel/VBoxContainer/HBoxContainer/Option2
@onready var option3_button: Button = $Panel/VBoxContainer/HBoxContainer/Option3
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel

var current_options: Array = []

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	if option1_button:
		option1_button.pressed.connect(_on_option1_pressed)
	if option2_button:
		option2_button.pressed.connect(_on_option2_pressed)
	if option3_button:
		option3_button.pressed.connect(_on_option3_pressed)

	print("POWERUP_UI: Ready")

func show_options(options: Array) -> void:
	if options.size() < 3:
		print("POWERUP_UI: Not enough options provided")
		return

	current_options = options

	if option1_button:
		option1_button.text = options[0].name + "\n" + options[0].description
	if option2_button:
		option2_button.text = options[1].name + "\n" + options[1].description
	if option3_button:
		option3_button.text = options[2].name + "\n" + options[2].description

	visible = true
	print("POWERUP_UI: Showing powerup selection")

func _on_option1_pressed() -> void:
	_select_powerup(0)
	get_viewport().set_input_as_handled()

func _on_option2_pressed() -> void:
	_select_powerup(1)
	get_viewport().set_input_as_handled()

func _on_option3_pressed() -> void:
	_select_powerup(2)
	get_viewport().set_input_as_handled()

func _select_powerup(index: int) -> void:
	if index >= current_options.size():
		return

	var selected = current_options[index]
	print("POWERUP_UI: Selected powerup: ", selected.name)

	powerup_selected.emit(selected)

	visible = false
	current_options.clear()
