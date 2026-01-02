extends Node

class_name AudioComponent

@export_group("Audio Clips")
@export var jump_sound: AudioStream
@export var land_sound: AudioStream
@export var score_sound: AudioStream
@export var death_sound: AudioStream
@export var charge_sound: AudioStream

@export_group("Settings")
@export var volume_db: float = 0.0
@export var bus: String = "Master"

var audio_players: Array[AudioStreamPlayer] = []
var pool_size: int = 3

func _ready() -> void:
	for i in range(pool_size):
		var player = AudioStreamPlayer.new()
		player.bus = bus
		player.volume_db = volume_db
		add_child(player)
		audio_players.append(player)

	if has_node("/root/EventBus"):
		EventBus.play_sound.connect(_on_sound_requested)

func play(sound_name: String) -> void:
	var stream: AudioStream = null

	match sound_name.to_lower():
		"jump":
			stream = jump_sound
		"land":
			stream = land_sound
		"score", "points":
			stream = score_sound
		"death", "dead", "die":
			stream = death_sound
		"charge":
			stream = charge_sound
		_:
			push_warning("Unknown sound name: " + sound_name)
			return

	if stream:
		_play_stream(stream)

func play_stream(stream: AudioStream) -> void:
	if stream:
		_play_stream(stream)

func _play_stream(stream: AudioStream) -> void:
	for player in audio_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return

	if audio_players.size() > 0:
		audio_players[0].stream = stream
		audio_players[0].play()

func stop_all() -> void:
	for player in audio_players:
		player.stop()

func _on_sound_requested(sound_name: String) -> void:
	play(sound_name)

func set_volume(db: float) -> void:
	volume_db = db
	for player in audio_players:
		player.volume_db = db

func set_bus(bus_name: String) -> void:
	bus = bus_name
	for player in audio_players:
		player.bus = bus_name
