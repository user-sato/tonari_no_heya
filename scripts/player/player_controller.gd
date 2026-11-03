extends CharacterBody3D

@export var walk_speed: float = 3.0
@export var mouse_sensitivity: float = 0.002

@onready var head: Node3D = $Head


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mouse_capture") and not event.is_echo():
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.screen_relative.x * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x - event.screen_relative.y * mouse_sensitivity, -PI / 2.0, PI / 2.0)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_direction := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_direction.x, 0.0, input_direction.y)).normalized()
	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed
	move_and_slide()
