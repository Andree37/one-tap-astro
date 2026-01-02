extends Node

class_name StateMachine

signal state_changed(from_state: String, to_state: String)

var current_state: State = null
var states: Dictionary = {}

@export var actor: Node

func _ready() -> void:
	await owner.ready

	if not actor:
		actor = get_parent()

	for child in get_children():
		if child is State:
			states[child.name] = child
			child.state_machine = self
			child.actor = actor

	if get_child_count() > 0 and get_child(0) is State:
		current_state = get_child(0) as State
		current_state.enter()

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func transition_to(target_state_name: String, data: Dictionary = {}) -> void:
	if not states.has(target_state_name):
		push_error("State '%s' does not exist!" % target_state_name)
		return

	var previous_state_name = current_state.name if current_state else "null"

	if current_state:
		current_state.exit()

	current_state = states[target_state_name]
	current_state.enter(data)

	state_changed.emit(previous_state_name, target_state_name)

func get_current_state_name() -> String:
	return current_state.name if current_state else ""

func is_in_state(state_name: String) -> bool:
	return current_state and current_state.name == state_name
