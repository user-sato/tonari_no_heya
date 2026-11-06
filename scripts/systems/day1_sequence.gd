extends Node

const CONTRACT_PATH := "res://data/documents/day1_contract.json"
const KNOCK_COUNT := 3
const SHARED_WALL_POSITION := Vector3(-2.0, 1.15, 4.65)

@onready var world: SubViewport = get_parent().get_node("WorldDisplay/WorldView")
@onready var level: Node3D = world.get_node("ApartmentFloor")
@onready var player: CharacterBody3D = world.get_node("Player")
@onready var interaction_ray: InteractionRay = player.get_node("Head/Camera3D/InteractionRay")
@onready var audio: Node3D = world.get_node("Day1AudioDirector")
@onready var hud: CanvasLayer = get_parent().get_node("HUD")
@onready var game_state = get_node("/root/GameState")

var contract_documents: Array[Dictionary] = []
var contract_by_id: Dictionary = {}
var _first_knock_pending := false
var _sleep_sequence_running := false
var _awaiting_player_knock := false
var _oddity_observation_pending := false
var _overlay_open_serial := 0


func _ready() -> void:
	_load_contract()
	game_state.flag_changed.connect(_on_flag_changed)
	interaction_ray.interaction_requested.connect(_on_interaction_requested)
	hud.document_viewed.connect(_on_document_viewed)
	hud.overlay_opened.connect(_on_overlay_opened)
	level.get_node("Balcony203/VisitTrigger").body_entered.connect(_on_balcony_entered)
	_apply_world_state()
	if game_state.has_flag(&"day1_complete"):
		_lock_for_sleep()
		_restore_sleep_view()
		hud.fade_to_black(0.0)
		hud.show_day_end()
	elif game_state.has_flag(&"sleep_sequence_started"):
		_begin_sleep_sequence()
	elif game_state.has_flag(&"mail_placed") and not game_state.has_flag(&"first_knock_heard"):
		_schedule_first_knock()


func _process(_delta: float) -> void:
	if _awaiting_player_knock and Input.is_action_just_pressed("interact"):
		_accept_player_knock()


func _unhandled_input(event: InputEvent) -> void:
	if _awaiting_player_knock and event.is_action_pressed("interact") and not event.is_echo():
		_accept_player_knock()
		get_viewport().set_input_as_handled()


func _accept_player_knock() -> void:
	if not _awaiting_player_knock:
		return
	_awaiting_player_knock = false
	_finish_wall_exchange()


func _load_contract() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
	if not parsed is Array:
		push_error("Day 1 contract data could not be loaded")
		return
	for value in parsed:
		if value is Dictionary:
			var document: Dictionary = value.duplicate(true)
			contract_documents.append(document)
			contract_by_id[StringName(document.get("id", ""))] = document


func _on_flag_changed(flag_name: StringName, _value: bool) -> void:
	_apply_world_state()
	if flag_name == &"mail_placed" and not game_state.has_flag(&"first_knock_heard"):
		_schedule_first_knock()


func _schedule_first_knock() -> void:
	if _first_knock_pending:
		return
	_first_knock_pending = true
	_run_first_knock()


func _on_overlay_opened() -> void:
	_overlay_open_serial += 1


func _run_first_knock() -> void:
	# mail_placed is emitted synchronously before the document overlay opens.
	await get_tree().process_frame
	while true:
		while hud.is_overlay_open():
			await hud.overlay_closed
		var overlay_serial := _overlay_open_serial
		await get_tree().create_timer(1.2).timeout
		if not hud.is_overlay_open() and overlay_serial == _overlay_open_serial:
			break
	if game_state.has_flag(&"first_knock_heard") or game_state.has_flag(&"sleep_sequence_started") or game_state.has_flag(&"day1_complete"):
		_first_knock_pending = false
		return
	hud.show_subtitle("（隣の壁から、乾いた音が三回）", 2.2)
	await audio.play_knocks(KNOCK_COUNT, SHARED_WALL_POSITION, 0.38, -14.0, 1)
	game_state.set_flag(&"first_knock_heard")
	while hud.is_overlay_open():
		await hud.overlay_closed
	hud.show_message("隣の部屋からだろうか。202号室を確認してみよう。")
	_first_knock_pending = false


func _on_interaction_requested(target: Interactable) -> void:
	match target.interaction_id:
		&"contract_file":
			if not game_state.has_flag(&"neighbor_door_checked"):
				return
			game_state.set_flag(&"contract_found")
			hud.open_documents(contract_documents)
		&"phone_call":
			if not game_state.has_flag(&"contract_found"):
				return
			game_state.set_flag(&"contact_attempted")
			hud.show_message("『営業時間外です。受付時間は9時から18時です』")
		&"bed_sleep":
			if game_state.has_flag(&"contact_attempted") and not _sleep_sequence_running:
				_begin_sleep_sequence()


func _on_document_viewed(document_id: StringName) -> void:
	if contract_by_id.has(document_id):
		game_state.mark_document_read(contract_by_id[document_id])


func _apply_world_state() -> void:
	if not is_instance_valid(level):
		return
	var contract := level.get_node("Room203/ContractFile") as Interactable
	var phone := level.get_node("Room203/Phone") as Interactable
	var bed := level.get_node("Room203/Bed") as Interactable
	var oddity := level.get_node("Exterior202/OddityShadow") as Node3D
	contract.enabled = game_state.has_flag(&"neighbor_door_checked")
	phone.enabled = game_state.has_flag(&"contract_found") and not game_state.has_flag(&"contact_attempted")
	bed.enabled = game_state.has_flag(&"contact_attempted") and not game_state.has_flag(&"sleep_sequence_started")
	oddity.visible = game_state.has_flag(&"contract_found") and not game_state.has_flag(&"balcony_oddity_seen")


func _on_balcony_entered(body: Node3D) -> void:
	if body != player:
		return
	game_state.set_flag(&"balcony_visited")
	var oddity := level.get_node("Exterior202/OddityShadow") as Node3D
	if oddity.visible and not _oddity_observation_pending:
		_oddity_observation_pending = true
		await get_tree().create_timer(2.5).timeout
		game_state.set_flag(&"balcony_oddity_seen")
		oddity.hide()
		hud.show_message("隣の窓際で、何かが動いた気がした。")
		_oddity_observation_pending = false


func _begin_sleep_sequence() -> void:
	_sleep_sequence_running = true
	game_state.set_flag(&"sleep_sequence_started")
	_lock_for_sleep()
	_run_sleep_sequence()


func _lock_for_sleep() -> void:
	hud.set_notebook_enabled(false)
	player.set_input_enabled(false)
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	player.collision_layer = 0
	player.collision_mask = 0
	interaction_ray.set_interaction_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _restore_sleep_view() -> void:
	(level.get_node("Room203/RoomLight") as Light3D).visible = false
	player.global_position = Vector3(-1.32, 0.0, 5.20)
	player.rotation = Vector3(0.0, PI / 2.0, 0.0)
	var head := player.get_node("Head") as Node3D
	head.position.y = 0.72
	head.rotation.x = 0.0


func _run_sleep_sequence() -> void:
	await hud.fade_to_black(0.7)
	_restore_sleep_view()
	await hud.fade_from_black(0.7)
	await get_tree().create_timer(0.8).timeout
	hud.show_subtitle("（壁の向こうから、三回）", 2.0)
	await audio.play_knocks(KNOCK_COUNT, SHARED_WALL_POSITION, 0.42, -15.0, 1)
	await get_tree().create_timer(0.5).timeout
	hud.set_sequence_prompt("[E] 壁を叩く")
	_awaiting_player_knock = true


func _finish_wall_exchange() -> void:
	hud.clear_sequence_prompt()
	print("[Day1] player wall knocks: %d" % KNOCK_COUNT)
	await audio.play_knocks(KNOCK_COUNT, SHARED_WALL_POSITION, 0.42, -13.0, 0)
	await get_tree().create_timer(0.7).timeout
	hud.show_subtitle("（同じ数だけ、返ってくる）", 2.0)
	print("[Day1] neighbor reply knocks: %d" % KNOCK_COUNT)
	await audio.play_knocks(KNOCK_COUNT, SHARED_WALL_POSITION, 0.42, -15.0, 1)
	game_state.set_flag(&"day1_complete")
	await get_tree().create_timer(0.8).timeout
	await hud.fade_to_black(1.2)
	hud.show_day_end()
