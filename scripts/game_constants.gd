extends Node

class_name GameConstants

const GRAVITY: float = 1200.0
const JUMP_FORCE: float = 1000.0
const FALL_MULTIPLIER: float = 2.5

const MIN_HORIZONTAL_RATIO: float = 0.05
const MAX_HORIZONTAL_RATIO: float = 0.3
const MAX_CHARGE_TIME: float = 1.0
const JUMP_ANGLE_MAX_ROTATION: float = 45.0
const MOUSE_MAX_OFFSET: float = 300.0

const PIXELS_PER_METER: float = 50.0

const PLAYER_HALF_HEIGHT: float = 71.0
const PLAYER_MAX_ROTATION: float = 0.5

const PLATFORM_WIDTH: float = 152.0
const PLATFORM_HEIGHT: float = 54.0
const PLATFORM_POOL_SIZE: int = 20

const MIN_SPAWN_TIME: float = 1.5
const MAX_SPAWN_TIME: float = 2.2
const PLATFORM_SPEED: float = 80.0
const PLATFORM_LIFETIME: float = 10.0
const SPAWN_DISTANCE_AHEAD: float = 250.0

const MIN_HORIZONTAL_GAP: float = 50.0
const MIN_VERTICAL_GAP: float = 200.0
const MAX_VERTICAL_GAP: float = 350.0
const PLAYER_HORIZONTAL_CLEARANCE: float = 100.0
const PLAYER_VERTICAL_CLEARANCE: float = 150.0

const CAMERA_SCROLL_SPEED: float = 80.0

const SCREEN_WIDTH: float = 720.0
const SCREEN_HEIGHT: float = 1280.0
const SPAWN_X_RANGE: float = 240.0

const LAYER_PLAYER: int = 1
const LAYER_PLATFORM: int = 2
const LAYER_BOUNDS: int = 3

const GROUP_PLAYER: String = "player"
const GROUP_PLATFORMS: String = "platforms"

const SAVE_FILE_PATH: String = "user://savegame.save"

const PATH_AUDIO_JUMP: String = "res://assets/audio/jump.wav"
const PATH_AUDIO_POINTS: String = "res://assets/audio/points.wav"
const PATH_AUDIO_DEAD: String = "res://assets/audio/dead.mp3"

const ANIM_IDLE: String = "idle"
const ANIM_CROUCH: String = "crouch"
const ANIM_JUMP: String = "jump"
const ANIM_DEAD: String = "dead"
const ANIM_RESET: String = "RESET"

const DIFFICULTY_SPEED_INCREMENT: float = 5.0
const DIFFICULTY_TIME_DECREMENT: float = 0.1
const SCORE_PER_DIFFICULTY_INCREASE: int = 10
