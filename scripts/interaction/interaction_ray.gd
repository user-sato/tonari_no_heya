class_name InteractionRay
extends RayCast3D

signal prompt_changed(prompt: String)
signal interaction_requested(target: Interactable)

var _interaction_enabled: bool = true
var _target: Interactable
var _prompt: String = ""


func _ready() -> void:
	target_position = Vector3(0.0, 0.0, -2.0)


func _physics_process(_delta: float) -> void:
	_update_target()


func _unhandled_input(event: InputEvent) -> void:
	if not _interaction_enabled or not event.is_action_pressed("interact") or event.is_echo():
		return
	_update_target()
	if is_instance_valid(_target) and _target.enabled:
		var target := _target
		interaction_requested.emit(target)
		if is_instance_valid(target):
			target.interact()
		get_viewport().set_input_as_handled()


func set_interaction_enabled(value: bool) -> void:
	_interaction_enabled = value
	_update_target()


func _update_target() -> void:
	var found: Interactable = null
	if _interaction_enabled and is_colliding():
		var node := get_collider() as Node
		while node != null:
			if node is Interactable:
				if node.enabled:
					found = node
				break
			node = node.get_parent()
	_target = found
	var prompt := found.prompt_text if found != null else ""
	if prompt != _prompt:
		_prompt = prompt
		prompt_changed.emit(_prompt)
