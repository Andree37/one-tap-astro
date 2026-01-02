extends Node

class_name State

var state_machine: StateMachine = null
var actor: Node = null

func enter(_data: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

func transition_to(target_state: String, data: Dictionary = {}) -> void:
	if state_machine:
		state_machine.transition_to(target_state, data)
	else:
		push_error("State '%s' has no state machine reference!" % name)

func get_actor_as(type: Variant) -> Variant:
	if actor and is_instance_of(actor, type):
		return actor
	return null

func can_transition_to(target_state: String) -> bool:
	return state_machine and state_machine.states.has(target_state)
