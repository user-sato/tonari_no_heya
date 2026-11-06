extends Node

const DOCUMENT_PATH := "res://data/documents/day1_mail.json"

@onready var world: SubViewport = get_parent().get_node("WorldDisplay/WorldView")
@onready var level: Node3D = world.get_node("ApartmentFloor")
@onready var player: CharacterBody3D = world.get_node("Player")
@onready var interaction_ray: InteractionRay = player.get_node("Head/Camera3D/InteractionRay")
@onready var hud: CanvasLayer = get_parent().get_node("HUD")
@onready var game_state = get_node("/root/GameState")

var documents: Array[Dictionary] = []
var documents_by_id: Dictionary = {}


func _ready() -> void:
	_load_documents()
	interaction_ray.prompt_changed.connect(hud.set_interaction_prompt)
	interaction_ray.interaction_requested.connect(_on_interaction_requested)
	hud.overlay_opened.connect(_on_overlay_opened)
	hud.overlay_closed.connect(_on_overlay_closed)
	hud.document_viewed.connect(_on_document_viewed)
	hud.notebook_requested.connect(_on_notebook_requested)
	_apply_world_state()


func _load_documents() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DOCUMENT_PATH))
	if not parsed is Array:
		push_error("Day 1 mail data could not be loaded")
		return
	for value in parsed:
		if value is Dictionary:
			var document: Dictionary = value.duplicate(true)
			documents.append(document)
			documents_by_id[StringName(document.get("id", ""))] = document


func _on_interaction_requested(target: Interactable) -> void:
	match target.interaction_id:
		&"mailbox_203":
			_collect_mail()
		&"desk_mail":
			_inspect_mail()
		&"door_202":
			if game_state.has_flag(&"first_knock_heard"):
				game_state.set_flag(&"neighbor_door_checked")
				hud.show_message("扉をノックした。返事はない。")
			else:
				game_state.set_flag(&"door_202_examined")
				hud.show_message("返事はない。鍵が掛かっている。")


func _collect_mail() -> void:
	if game_state.has_flag(&"mail_collected"):
		return
	game_state.set_flag(&"mail_collected")
	_apply_world_state()
	hud.show_message("郵便物を回収した。机で確認しよう。")


func _inspect_mail() -> void:
	if not game_state.has_flag(&"mail_collected"):
		return
	if not game_state.has_flag(&"mail_placed"):
		game_state.set_flag(&"mail_placed")
		_apply_world_state()
	hud.open_documents(documents)


func _on_document_viewed(document_id: StringName) -> void:
	if not documents_by_id.has(document_id):
		return
	game_state.mark_document_read(documents_by_id[document_id])
	if document_id == &"unknown_letter":
		game_state.set_flag(&"letter_read")
	elif document_id == &"electricity_notice":
		game_state.set_flag(&"power_cut_notice_seen")


func _on_notebook_requested() -> void:
	hud.open_notebook(game_state.get_read_documents())


func _on_overlay_opened() -> void:
	player.set_input_enabled(false)
	interaction_ray.set_interaction_enabled(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_overlay_closed() -> void:
	if game_state.has_flag(&"sleep_sequence_started") or game_state.has_flag(&"day1_complete"):
		return
	player.set_input_enabled(true)
	interaction_ray.set_interaction_enabled(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _apply_world_state() -> void:
	var mailbox := level.get_node("Corridor/Mailbox203") as Interactable
	var desk := level.get_node("Room203/Desk") as Interactable
	var mail_stack := mailbox.get_node("MailStack") as Node3D
	var placed_mail := desk.get_node("PlacedMail") as Node3D
	var collected: bool = game_state.has_flag(&"mail_collected")
	var placed: bool = game_state.has_flag(&"mail_placed")
	mailbox.enabled = not collected
	mail_stack.visible = not collected
	desk.enabled = collected
	desk.prompt_text = "郵便物を見る" if placed else "郵便物を置く"
	placed_mail.visible = placed
