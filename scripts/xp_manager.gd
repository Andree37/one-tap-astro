extends Node

class_name XPManager

signal xp_gained(current_xp: int, level: int)
signal level_up(new_level: int)
signal lootbox_earned(level: int)

var current_xp: int = 0
var current_level: int = 0
var levels_that_give_lootbox: Array[int] = []

func _ready() -> void:
	add_to_group("xp_manager")
	print("XP_MANAGER: _ready called")
	EventBus.game_started.connect(_on_game_started)
	_precalculate_lootbox_levels()
	print("XP_MANAGER: Ready, connected to EventBus")

func _precalculate_lootbox_levels() -> void:
	levels_that_give_lootbox.clear()
	for n in range(0, 50):
		levels_that_give_lootbox.append(5 * n + 2)
	print("XP_MANAGER: Lootbox levels: ", levels_that_give_lootbox.slice(0, 10))

func _on_game_started() -> void:
	print("XP_MANAGER: Game started signal received")
	reset()

func reset() -> void:
	current_xp = 0
	current_level = 0
	print("XP_MANAGER: Reset XP and level")

func add_xp(amount: int) -> void:
	var multiplier = _get_xp_multiplier()
	var final_amount = int(amount * multiplier)

	current_xp += final_amount
	print("XP_MANAGER: Added ", amount, " XP (x", multiplier, " = ", final_amount, "). Total: ", current_xp)
	xp_gained.emit(current_xp, current_level)

	_check_level_up()

func add_perfect_landing_xp() -> void:
	print("XP_MANAGER: Perfect landing! Adding 3 XP")
	add_xp(3)

func add_normal_landing_xp() -> void:
	print("XP_MANAGER: Normal landing. Adding 1 XP")
	add_xp(1)

func _check_level_up() -> void:
	var xp_per_level = 10.0
	var new_level = int(current_xp / xp_per_level)

	if new_level > current_level:
		current_level = new_level
		print("XP_MANAGER: LEVEL UP! New level: ", current_level)
		level_up.emit(current_level)

		if current_level in levels_that_give_lootbox:
			print("XP_MANAGER: LOOTBOX EARNED at level ", current_level)
			lootbox_earned.emit(current_level)

func get_xp_for_next_level() -> int:
	var xp_per_level = 10
	return (current_level + 1) * xp_per_level - current_xp

func get_xp_progress() -> float:
	var xp_per_level = 10
	var xp_into_current_level = current_xp - (current_level * xp_per_level)
	return float(xp_into_current_level) / float(xp_per_level)

func get_current_xp() -> int:
	return current_xp

func get_current_level() -> int:
	return current_level

func _get_xp_multiplier() -> float:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return 1.0

	var powerup_component = player.get_node_or_null("PowerupComponent")
	if not powerup_component:
		return 1.0

	return powerup_component.get_xp_multiplier()
