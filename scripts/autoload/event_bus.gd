extends Node

signal player_scored(score: int)
signal player_died(final_score: int)
signal player_jumped()
signal player_landed()

signal game_started()
signal game_over(final_score: int)
signal game_paused()
signal game_resumed()

signal platform_spawned(platform: Node2D)
signal platform_destroyed(platform: Node2D)

signal highscore_updated(new_highscore: int)
signal score_changed(new_score: int)

signal play_sound(sound_name: String)
signal play_music(music_name: String)
signal stop_music()

signal settings_changed(setting_name: String, value: Variant)

func emit_player_scored(score: int) -> void:
	player_scored.emit(score)
	score_changed.emit(score)

func emit_player_died(final_score: int) -> void:
	player_died.emit(final_score)
	game_over.emit(final_score)

func request_sound(sound_name: String) -> void:
	play_sound.emit(sound_name)
