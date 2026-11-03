extends Control

const RESOLUTIONS: Array[Vector2i] = [Vector2i(320, 180), Vector2i(256, 144)]

@onready var display: SubViewportContainer = $WorldDisplay
@onready var world_view: SubViewport = $WorldDisplay/WorldView

var resolution_index := 0


func _ready() -> void:
	resized.connect(_fit_world_display)
	_apply_resolution()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		resolution_index = (resolution_index + 1) % RESOLUTIONS.size()
		_apply_resolution()
		get_viewport().set_input_as_handled()


func _apply_resolution() -> void:
	world_view.size = RESOLUTIONS[resolution_index]
	display.size = Vector2(world_view.size)
	_fit_world_display()


func _fit_world_display() -> void:
	var render_size := Vector2(RESOLUTIONS[resolution_index])
	var factor: float = minf(size.x / render_size.x, size.y / render_size.y)
	display.scale = Vector2.ONE * factor
	display.position = (size - render_size * factor) / 2.0
