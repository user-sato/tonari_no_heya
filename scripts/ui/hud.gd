extends CanvasLayer

signal overlay_opened
signal overlay_closed
signal document_viewed(id: StringName)
signal notebook_requested

var _mode := ""
var _pages: Array[Dictionary] = []
var _page_index := 0
var _message_serial := 0
var _prompt: Label
var _crosshair: Label
var _message: Label
var _shade: ColorRect
var _title: Label
var _body: Label
var _counter: Label
var _hint: Label
var _list: ItemList


func _ready() -> void:
	_build_ui()


func set_interaction_prompt(text: String) -> void:
	_prompt.text = "[E] " + text if not text.is_empty() else ""
	_prompt.visible = not text.is_empty() and _mode.is_empty()


func show_message(text: String) -> void:
	_message_serial += 1
	var serial := _message_serial
	_message.text = text
	_message.visible = not text.is_empty() and _mode.is_empty()
	if not text.is_empty():
		await get_tree().create_timer(3.5).timeout
		if serial == _message_serial:
			_message.hide()


func open_documents(pages: Array[Dictionary]) -> void:
	_pages = pages.duplicate(true)
	_page_index = 0
	_open("documents")
	_refresh_page()


func open_notebook(entries: Array[Dictionary]) -> void:
	_pages = entries.duplicate(true)
	_page_index = 0
	_open("notebook")
	_list.clear()
	for entry in _pages:
		_list.add_item(str(entry.get("title", "無題")))
	if not _pages.is_empty():
		_list.select(0)
	_refresh_page()


func close_overlay() -> void:
	if _mode.is_empty():
		return
	_mode = ""
	_shade.hide()
	_crosshair.show()
	_prompt.visible = not _prompt.text.is_empty()
	overlay_closed.emit()


func is_overlay_open() -> bool:
	return not _mode.is_empty()


func _open(mode: String) -> void:
	var was_closed := _mode.is_empty()
	_mode = mode
	_shade.show()
	_crosshair.hide()
	_prompt.hide()
	_message.hide()
	_list.visible = mode == "notebook"
	_hint.text = "Esc / Tab  閉じる" if mode == "notebook" else "クリック / ← →  ページをめくる     Esc  閉じる"
	if was_closed:
		overlay_opened.emit()


func _refresh_page() -> void:
	if _pages.is_empty():
		_title.text = "メモ" if _mode == "notebook" else ""
		_body.text = "まだ読んだ文書はありません。" if _mode == "notebook" else ""
		_counter.text = ""
		return
	var page := _pages[_page_index]
	_title.text = str(page.get("title", "無題"))
	_body.text = str(page.get("body", ""))
	(_body.get_parent() as ScrollContainer).scroll_vertical = 0
	_counter.text = "%d / %d" % [_page_index + 1, _pages.size()]
	if _mode == "documents":
		document_viewed.emit(StringName(str(page.get("id", ""))))


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and is_overlay_open():
			close_overlay()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("toggle_notebook"):
			if _mode == "notebook":
				close_overlay()
			elif _mode.is_empty():
				notebook_requested.emit()
			get_viewport().set_input_as_handled()
			return
		if _mode == "documents" and event.keycode in [KEY_LEFT, KEY_RIGHT]:
			_turn_page(-1 if event.keycode == KEY_LEFT else 1)
			get_viewport().set_input_as_handled()
			return
	if _mode == "documents" and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_turn_page(1)
		get_viewport().set_input_as_handled()


func _turn_page(direction: int) -> void:
	if _pages.is_empty():
		return
	var next := clampi(_page_index + direction, 0, _pages.size() - 1)
	if next != _page_index:
		_page_index = next
		_refresh_page()


func _on_item_selected(index: int) -> void:
	if _mode == "notebook" and index >= 0 and index < _pages.size():
		_page_index = index
		_refresh_page()


func _label(parent: Node, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_crosshair = _label(root, 16, Color(1, 1, 1, 0.75))
	_crosshair.text = "·"
	_crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_crosshair.position = Vector2(-10, -12)
	_crosshair.size = Vector2(20, 24)
	_prompt = _label(root, 18, Color(1, 1, 1, 0.85))
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_prompt.position = Vector2(-250, 25)
	_prompt.size = Vector2(500, 32)
	_prompt.hide()
	_message = _label(root, 22, Color.WHITE)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_message.position = Vector2(-450, -105)
	_message.size = Vector2(900, 40)
	_message.hide()
	_shade = ColorRect.new()
	_shade.color = Color(0.03, 0.03, 0.035, 0.88)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_shade)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.08
	panel.anchor_top = 0.06
	panel.anchor_right = 0.92
	panel.anchor_bottom = 0.94
	_shade.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	_title = _label(column, 24, Color(0.95, 0.94, 0.9))
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	column.add_child(content)
	_list = ItemList.new()
	_list.custom_minimum_size.x = 220
	_list.add_theme_font_size_override("font_size", 18)
	_list.item_selected.connect(_on_item_selected)
	content.add_child(_list)
	var body_scroll := ScrollContainer.new()
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(body_scroll)
	_body = _label(body_scroll, 20, Color(0.9, 0.89, 0.85))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_counter = _label(column, 16, Color(0.75, 0.75, 0.73))
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint = _label(column, 15, Color(0.7, 0.7, 0.68))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shade.hide()
