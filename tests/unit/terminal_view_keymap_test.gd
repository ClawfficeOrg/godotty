## GdUnit4 tests: TerminalView consumes TerminalKeymap in _input (task 2.3.2).
##
## Spec: docs/todo-v2.md (task 2.3.2)
##
## Covers:
##   - Default Ctrl+L clears the terminal.
##   - Rebinding "clear" to Ctrl+K causes Ctrl+K to clear.
##   - After rebinding, the old Ctrl+L chord no longer clears.
##   - Echo events are ignored and do not dispatch actions.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _original_keymap: TerminalKeymap


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()
	_original_keymap = TerminalManager.keymap
	TerminalManager.keymap = TerminalKeymap.default()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null
	TerminalManager.keymap = _original_keymap
	_original_keymap = null


func _make_key_event(keycode: Key, ctrl: bool, shift: bool = false) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	ev.ctrl_pressed = ctrl
	ev.shift_pressed = shift
	return ev


## Default Ctrl+L clears the terminal via the keymap.
func test_default_ctrl_l_clears() -> void:
	TerminalManager._mock_output_buffer.append("some output")

	_view._input(_make_key_event(KEY_L, true))

	assert_bool(TerminalManager._mock_output_buffer.is_empty()).is_true()


## Rebinding clear to Ctrl+K causes Ctrl+K to clear the terminal.
func test_rebind_clear_to_ctrl_k() -> void:
	var new_key := InputEventKey.new()
	new_key.keycode = KEY_K
	new_key.ctrl_pressed = true
	TerminalManager.keymap.bindings[TerminalKeymap.ACTION_CLEAR] = new_key
	TerminalManager._mock_output_buffer.append("some output")

	_view._input(_make_key_event(KEY_K, true))

	assert_bool(TerminalManager._mock_output_buffer.is_empty()).is_true()


## After rebinding clear to Ctrl+K, the old Ctrl+L chord no longer clears.
func test_old_ctrl_l_no_longer_clears_after_rebind() -> void:
	var new_key := InputEventKey.new()
	new_key.keycode = KEY_K
	new_key.ctrl_pressed = true
	TerminalManager.keymap.bindings[TerminalKeymap.ACTION_CLEAR] = new_key
	TerminalManager._mock_output_buffer.append("some output")

	_view._input(_make_key_event(KEY_L, true))

	assert_bool(TerminalManager._mock_output_buffer.is_empty()).is_false()


## Echo events are ignored and do not dispatch keymap actions.
func test_echo_event_is_ignored() -> void:
	TerminalManager._mock_output_buffer.append("some output")
	var ev := InputEventKey.new()
	ev.keycode = KEY_L
	ev.ctrl_pressed = true
	ev.pressed = true
	ev.echo = true

	_view._input(ev)

	assert_bool(TerminalManager._mock_output_buffer.is_empty()).is_false()
