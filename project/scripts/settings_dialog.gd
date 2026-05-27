## SettingsDialog — keybinding editor panel (task 2.3.3).
##
## Presents a scrollable list of (action name, current chord, [Edit] button)
## rows. Clicking Edit captures the next key press and rebinds the action.
## Save writes the live keymap to user://keymap.tres.
## load_keymap() restores from that file, or falls back to the built-in defaults
## when the file is absent.
class_name SettingsDialog
extends Control

## Path where the user's custom keymap is persisted.
const KEYMAP_PATH: String = "user://keymap.tres"

## Action currently waiting for a key capture; "" when idle.
var _capturing_action: String = ""

@onready var _rows_container: VBoxContainer = $VBoxContainer/ScrollContainer/RowsContainer
@onready var _save_button: Button = $VBoxContainer/ButtonBar/SaveButton
@onready var _reset_button: Button = $VBoxContainer/ButtonBar/ResetButton


func _ready() -> void:
	load_keymap()
	_populate_rows()
	_save_button.pressed.connect(save_keymap)
	_reset_button.pressed.connect(_on_reset_pressed)


func _exit_tree() -> void:
	if _save_button.pressed.is_connected(save_keymap):
		_save_button.pressed.disconnect(save_keymap)
	if _reset_button.pressed.is_connected(_on_reset_pressed):
		_reset_button.pressed.disconnect(_on_reset_pressed)


func _input(event: InputEvent) -> void:
	if _capturing_action == "":
		return
	if not (event is InputEventKey):
		return
	var ev: InputEventKey = event as InputEventKey
	if not ev.pressed or ev.echo:
		return
	# Ignore bare modifier keys — they can't form a useful binding on their own.
	if ev.keycode in [KEY_CTRL, KEY_SHIFT, KEY_ALT, KEY_META]:
		return
	var new_key := InputEventKey.new()
	new_key.keycode = ev.keycode
	new_key.ctrl_pressed = ev.ctrl_pressed
	new_key.shift_pressed = ev.shift_pressed
	new_key.alt_pressed = ev.alt_pressed
	new_key.meta_pressed = ev.meta_pressed
	TerminalManager.keymap.bindings[_capturing_action] = new_key
	_refresh_row(_capturing_action)
	_capturing_action = ""
	if get_viewport() != null:
		get_viewport().set_input_as_handled()


## Trigger a key-capture session for the given action.
## The next non-modifier key press received by _input() will become the binding.
func _on_edit_pressed(action: String) -> void:
	_capturing_action = action


## Rebuild the row list from the live keymap.
func _populate_rows() -> void:
	for child in _rows_container.get_children():
		_rows_container.remove_child(child)
		child.free()
	for action: String in TerminalKeymap.BUILTIN_ACTIONS:
		_rows_container.add_child(_make_row(action))


## Build one row HBox for the given action.
func _make_row(action: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = action
	name_label.custom_minimum_size = Vector2(180, 0)
	var chord_label := Label.new()
	chord_label.name = "ChordLabel"
	chord_label.text = _chord_string(TerminalManager.keymap.bindings.get(action))
	chord_label.custom_minimum_size = Vector2(160, 0)
	var edit_button := Button.new()
	edit_button.text = "Edit"
	edit_button.pressed.connect(_on_edit_pressed.bind(action))
	row.add_child(name_label)
	row.add_child(chord_label)
	row.add_child(edit_button)
	return row


## Update the chord label for a single row after a rebind.
func _refresh_row(action: String) -> void:
	var idx: int = TerminalKeymap.BUILTIN_ACTIONS.find(action)
	if idx < 0 or idx >= _rows_container.get_child_count():
		return
	var row: HBoxContainer = _rows_container.get_child(idx) as HBoxContainer
	if row == null:
		return
	var chord_label: Label = row.get_node("ChordLabel") as Label
	if chord_label != null:
		chord_label.text = _chord_string(TerminalManager.keymap.bindings.get(action))


## Return a human-readable string for an InputEventKey (e.g. "Ctrl+Shift+C").
func _chord_string(ev: InputEventKey) -> String:
	if ev == null:
		return "(none)"
	var parts: Array[String] = []
	if ev.ctrl_pressed:
		parts.append("Ctrl")
	if ev.shift_pressed:
		parts.append("Shift")
	if ev.alt_pressed:
		parts.append("Alt")
	if ev.meta_pressed:
		parts.append("Meta")
	parts.append(OS.get_keycode_string(ev.keycode))
	return "+".join(parts)


## Save the live keymap to user://keymap.tres.
func save_keymap() -> void:
	var err: int = ResourceSaver.save(TerminalManager.keymap, KEYMAP_PATH)
	if err != OK:
		push_error("SettingsDialog: failed to save keymap (error %d)" % err)


## Load keymap from user://keymap.tres, falling back to the built-in defaults.
func load_keymap() -> void:
	if ResourceLoader.exists(KEYMAP_PATH):
		var loaded: TerminalKeymap = (
			ResourceLoader.load(KEYMAP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as TerminalKeymap
		)
		if loaded != null:
			TerminalManager.keymap = loaded
			return
	TerminalManager.keymap = TerminalKeymap.default()


func _on_reset_pressed() -> void:
	TerminalManager.keymap = TerminalKeymap.default()
	_populate_rows()
