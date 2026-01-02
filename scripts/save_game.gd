extends Node

const SAVE_FILE_PATH: String = "user://savegame.save"

var data: Dictionary = {
	"highscore": 0,
	"num_deaths": 0,
	"total_jumps": 0,
	"total_play_time": 0.0,
	"settings": {}
}

var save_path: String = SAVE_FILE_PATH

func _ready() -> void:
	load_game()

	if has_node("/root/EventBus"):
		EventBus.player_died.connect(_on_player_died)
		EventBus.player_scored.connect(_on_player_scored)
		EventBus.player_jumped.connect(_on_player_jumped)

func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		_reset_to_defaults()
		return false

	var save_file = FileAccess.open(save_path, FileAccess.READ)
	if save_file == null:
		push_error("Failed to open save file for reading: " + str(FileAccess.get_open_error()))
		return false

	var json_string = save_file.get_as_text()
	save_file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse save file: " + json.get_error_message())
		return false

	if typeof(json.data) == TYPE_DICTIONARY:
		for key in json.data:
			if data.has(key):
				data[key] = json.data[key]
		return true

	return false

func save_game() -> bool:
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file == null:
		push_error("Failed to open save file for writing: " + str(FileAccess.get_open_error()))
		return false

	var json_string = JSON.stringify(data, "\t")
	save_file.store_string(json_string)
	save_file.close()
	return true

func _reset_to_defaults() -> void:
	data = {
		"highscore": 0,
		"num_deaths": 0,
		"total_jumps": 0,
		"total_play_time": 0.0,
		"settings": {}
	}

func get_highscore() -> int:
	return data.get("highscore", 0)

func get_deaths() -> int:
	return data.get("num_deaths", 0)

func get_total_jumps() -> int:
	return data.get("total_jumps", 0)

func get_play_time() -> float:
	return data.get("total_play_time", 0.0)

func get_setting(key: String, default: Variant = null) -> Variant:
	var settings = data.get("settings", {})
	return settings.get(key, default)

func set_highscore(new_highscore: int) -> void:
	if new_highscore > get_highscore():
		data["highscore"] = new_highscore
		save_game()

		if has_node("/root/EventBus"):
			EventBus.highscore_updated.emit(new_highscore)

func increment_deaths() -> void:
	data["num_deaths"] = get_deaths() + 1
	save_game()

func increment_jumps() -> void:
	data["total_jumps"] = get_total_jumps() + 1

func add_play_time(seconds: float) -> void:
	data["total_play_time"] = get_play_time() + seconds

func set_setting(key: String, value: Variant) -> void:
	if not data.has("settings"):
		data["settings"] = {}
	data["settings"][key] = value
	save_game()

func reset_save() -> void:
	_reset_to_defaults()
	save_game()

func get_stats() -> Dictionary:
	return {
		"highscore": get_highscore(),
		"deaths": get_deaths(),
		"jumps": get_total_jumps(),
		"play_time": get_play_time(),
		"average_score": get_highscore() / max(1, get_deaths()),
		"jumps_per_death": get_total_jumps() / max(1, get_deaths())
	}

func _on_player_died(final_score: int) -> void:
	increment_deaths()
	if final_score > get_highscore():
		set_highscore(final_score)
	save_game()

func _on_player_scored(score: int) -> void:
	if score > get_highscore():
		set_highscore(score)

func _on_player_jumped() -> void:
	increment_jumps()

func set_save_path(path: String) -> void:
	save_path = path

func reload() -> bool:
	return load_game()

func get_raw_data() -> Dictionary:
	return data.duplicate(true)
