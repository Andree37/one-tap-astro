extends Node

class_name ObjectPool

@export var pooled_scene: PackedScene
@export var initial_size: int = 10
@export var max_size: int = 50
@export var auto_grow: bool = true

var available_objects: Array[Node] = []
var active_objects: Array[Node] = []
var total_created: int = 0

func _ready() -> void:
	if pooled_scene:
		_initialize_pool()

func _initialize_pool() -> void:
	for i in range(initial_size):
		var obj = _create_new_object()
		if obj:
			_deactivate_object(obj)

func _create_new_object() -> Node:
	if not pooled_scene:
		push_error("ObjectPool: No pooled_scene assigned!")
		return null

	var obj = pooled_scene.instantiate()
	if not obj:
		push_error("ObjectPool: Failed to instantiate scene!")
		return null

	add_child(obj)
	total_created += 1

	return obj

func get_object() -> Node:
	var obj: Node = null

	if available_objects.size() > 0:
		obj = available_objects.pop_back()
	elif auto_grow and (max_size == 0 or total_created < max_size):
		obj = _create_new_object()
	else:
		push_warning("ObjectPool: Pool exhausted and cannot grow!")
		return null

	if obj:
		_activate_object(obj)

	return obj

func return_object(obj: Node) -> void:
	if not obj:
		return

	if not active_objects.has(obj):
		push_warning("ObjectPool: Trying to return object not from this pool!")
		return

	_deactivate_object(obj)

func _activate_object(obj: Node) -> void:
	if not obj:
		return

	active_objects.append(obj)
	obj.process_mode = Node.PROCESS_MODE_INHERIT
	obj.visible = true

	if obj.has_method("on_pool_activate"):
		obj.call("on_pool_activate")

func _deactivate_object(obj: Node) -> void:
	if not obj:
		return

	active_objects.erase(obj)
	available_objects.append(obj)

	obj.visible = false
	obj.process_mode = Node.PROCESS_MODE_DISABLED

	if obj is Node2D:
		obj.global_position = Vector2.ZERO
		obj.rotation = 0
		obj.scale = Vector2.ONE

	if obj.has_method("on_pool_deactivate"):
		obj.call("on_pool_deactivate")

func clear_pool() -> void:
	for obj in active_objects.duplicate():
		return_object(obj)

	for obj in available_objects:
		if is_instance_valid(obj):
			obj.queue_free()

	available_objects.clear()
	active_objects.clear()
	total_created = 0

func get_stats() -> Dictionary:
	return {
		"total_created": total_created,
		"available": available_objects.size(),
		"active": active_objects.size(),
		"capacity": max_size if max_size > 0 else -1
	}

func prewarm(count: int) -> void:
	var to_create = min(count, max_size - total_created) if max_size > 0 else count

	for i in range(to_create):
		var obj = _create_new_object()
		if obj:
			_deactivate_object(obj)

func return_all_active() -> void:
	for obj in active_objects.duplicate():
		return_object(obj)
