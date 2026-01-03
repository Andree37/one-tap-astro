extends Node

const SAVE_FILE = "user://savegame.save"

var highscore: int = 0
var num_deaths: int = 0

func _ready():
	load_game()

func load_game():
	if not FileAccess.file_exists(SAVE_FILE):
		highscore = 0
		num_deaths = 0
		return

	var save_file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if save_file == null:
		push_error("Failed to open save file for reading")
		return

	var json_string = save_file.get_as_text()
	save_file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse save file")
		return

	var data = json.data

	if typeof(data) == TYPE_DICTIONARY:
		highscore = data.get("highscore", 0)
		num_deaths = data.get("num_deaths", 0)

func save_game():
	var save_data = {
		"highscore": highscore,
		"num_deaths": num_deaths
	}

	var save_file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if save_file == null:
		push_error("Failed to open save file for writing")
		return

	var json_string = JSON.stringify(save_data)
	save_file.store_string(json_string)
	save_file.close()

func get_highscore() -> int:
	return highscore

func set_highscore(new_highscore: int):
	if new_highscore > highscore:
		highscore = new_highscore
		save_game()

func increment_deaths():
	num_deaths += 1
	save_game()

func get_deaths() -> int:
	return num_deaths

func reset_save():
	highscore = 0
	num_deaths = 0
	save_game()
