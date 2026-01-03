extends Node

signal player_scored(score: int)
signal player_died(final_score: int)

signal game_started()
signal game_over(final_score: int)

signal score_changed(new_score: int)

signal play_sound(sound_name: String)

func emit_player_scored(score: int) -> void:
	player_scored.emit(score)
	score_changed.emit(score)

func emit_player_died(final_score: int) -> void:
	player_died.emit(final_score)
	game_over.emit(final_score)

func request_sound(sound_name: String) -> void:
	play_sound.emit(sound_name)
