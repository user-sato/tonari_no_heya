extends Node

signal flag_changed(flag_name: StringName, value: bool)
signal document_read(document_id: StringName)

var day_index: int = 1
var flags: Dictionary = {}
var read_documents: Dictionary = {}
var read_document_order: Array[StringName] = []


func has_flag(flag_name: StringName) -> bool:
	return bool(flags.get(flag_name, false))


func set_flag(flag_name: StringName, value: bool = true) -> void:
	if has_flag(flag_name) == value:
		return
	flags[flag_name] = value
	print("[GameState] flag %s = %s" % [flag_name, value])
	flag_changed.emit(flag_name, value)


func mark_document_read(document: Dictionary) -> void:
	var document_id := StringName(document.get("id", ""))
	if document_id.is_empty():
		return
	if not read_documents.has(document_id):
		read_document_order.append(document_id)
	read_documents[document_id] = document.duplicate(true)
	print("[GameState] document read: %s" % document_id)
	document_read.emit(document_id)


func get_read_documents() -> Array[Dictionary]:
	var documents: Array[Dictionary] = []
	for document_id in read_document_order:
		if read_documents.has(document_id):
			documents.append(read_documents[document_id].duplicate(true))
	return documents
