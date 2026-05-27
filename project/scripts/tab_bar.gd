## TerminalTabBar -- HBoxContainer-based tab bar for multi-terminal layouts.
##
## Manages a row of TerminalTerminalTabButton nodes, one per terminal session.
## Exposes signals for new-tab and close-tab so callers (e.g. the main
## scene or TerminalManager) can spawn or teardown sessions independently.
##
## Usage:
##   bar.add_tab("shell_1", "bash")
##   bar.set_tab_title("shell_1", "vim ~/file.txt")
##   bar.notify_output("shell_1")   # mark indicator when shell writes
##   bar.focus_tab("shell_1")       # clear indicator, mark active
##   bar.remove_tab("shell_1")
class_name TerminalTabBar
extends HBoxContainer

## Emitted when the user presses the + add button.
signal new_tab_requested

## Emitted when the user presses a tab's close button.
signal tab_close_requested(shell_id: String)

## Emitted when a tab receives focus (click or programmatic focus_tab).
signal tab_focused(shell_id: String)

## Fallback title shown when no shell name is available.
const DEFAULT_TITLE: String = "Shell"

## Map from shell_id (String) to TerminalTabButton.
var _tabs: Dictionary = {}

## Insertion-ordered list of shell_ids (used for cycling with next_tab).
var _tab_order: Array[String] = []

## shell_id of the tab that currently has focus.
var _active_shell_id: String = ""

@onready var _add_button: Button = $AddButton


func _ready() -> void:
	_add_button.pressed.connect(_on_add_pressed)


func _exit_tree() -> void:
	if is_instance_valid(_add_button) and _add_button.pressed.is_connected(_on_add_pressed):
		_add_button.pressed.disconnect(_on_add_pressed)
	for key: String in _tabs.keys():
		_disconnect_tab(_tabs[key] as TerminalTabButton)


## Add a tab for the given shell_id.  No-op if the id already exists.
## Uses DEFAULT_TITLE when title is empty.
func add_tab(shell_id: String, title: String = DEFAULT_TITLE) -> void:
	if _tabs.has(shell_id):
		return
	var btn := TerminalTabButton.new()
	btn.shell_id = shell_id
	add_child(btn)
	# Keep the AddButton as the last child.
	move_child(btn, get_child_count() - 2)
	var resolved: String = title if not title.is_empty() else DEFAULT_TITLE
	btn.set_title(resolved)
	btn.close_requested.connect(_on_tab_close_requested)
	btn.focused.connect(_on_tab_focused)
	_tabs[shell_id] = btn
	_tab_order.append(shell_id)


## Remove the tab for shell_id and free its node.  No-op if absent.
func remove_tab(shell_id: String) -> void:
	if not _tabs.has(shell_id):
		return
	var btn: TerminalTabButton = _tabs[shell_id] as TerminalTabButton
	_disconnect_tab(btn)
	_tabs.erase(shell_id)
	_tab_order.erase(shell_id)
	btn.queue_free()
	if _active_shell_id == shell_id:
		_active_shell_id = ""


## Returns the number of open tabs.
func get_tab_count() -> int:
	return _tab_order.size()


## Returns the shell_id of the currently active tab, or "" if none is focused.
func get_active_shell_id() -> String:
	return _active_shell_id


## Cycle focus to the tab after the currently active one (wraps around).
## Emits tab_focused. No-op when there are no tabs.
func next_tab() -> void:
	if _tab_order.is_empty():
		return
	var idx: int = _tab_order.find(_active_shell_id)
	var next_idx: int = (idx + 1) % _tab_order.size()
	focus_tab(_tab_order[next_idx])


## Update the displayed title for an existing tab.
func set_tab_title(shell_id: String, title: String) -> void:
	if not _tabs.has(shell_id):
		return
	(_tabs[shell_id] as TerminalTabButton).set_title(title)


## Mark the output indicator on a tab that received output while unfocused.
## Does nothing when shell_id matches the currently active tab.
func notify_output(shell_id: String) -> void:
	if shell_id == _active_shell_id:
		return
	if not _tabs.has(shell_id):
		return
	(_tabs[shell_id] as TerminalTabButton).set_indicator(true)


## Programmatically focus a tab: clear its indicator, update active id,
## and emit tab_focused.
func focus_tab(shell_id: String) -> void:
	if not _tabs.has(shell_id):
		return
	_activate_tab(shell_id)
	tab_focused.emit(shell_id)


func _activate_tab(shell_id: String) -> void:
	if _tabs.has(_active_shell_id) and _active_shell_id != shell_id:
		(_tabs[_active_shell_id] as TerminalTabButton).set_indicator(false)
	_active_shell_id = shell_id
	if _tabs.has(shell_id):
		(_tabs[shell_id] as TerminalTabButton).set_indicator(false)


func _disconnect_tab(btn: TerminalTabButton) -> void:
	if not is_instance_valid(btn):
		return
	if btn.close_requested.is_connected(_on_tab_close_requested):
		btn.close_requested.disconnect(_on_tab_close_requested)
	if btn.focused.is_connected(_on_tab_focused):
		btn.focused.disconnect(_on_tab_focused)


func _on_add_pressed() -> void:
	new_tab_requested.emit()


func _on_tab_close_requested(shell_id: String) -> void:
	tab_close_requested.emit(shell_id)


func _on_tab_focused(shell_id: String) -> void:
	_activate_tab(shell_id)
	tab_focused.emit(shell_id)
