class_name Interactable
extends Node3D

signal interacted

@export var interaction_id: StringName
@export var prompt_text: String = "調べる"
@export var enabled: bool = true


func _enter_tree() -> void:
	add_to_group("interactable")


func interact() -> void:
	if enabled:
		interacted.emit()
