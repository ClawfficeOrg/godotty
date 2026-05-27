## GdUnit4 tests: clipboard paste in TerminalView (task 1.4.3).
##
## Spec: docs/todo-v1.md (task 1.4.3)
##
## Covers:
##   - Ctrl+Shift+V reads clipboard and sends via TerminalManager.write_input.
##   - Shift+Insert reads clipboard and sends via TerminalManager.write_input.
##   - Bracketed paste mode wraps clipboard text with ESC[200~ / ESC[201~.
##   - When bracketed mode is off, clipboard text is sent unwrapped.
##
## Uses _clipboard_override on TerminalView to bypass headless clipboard limits.
## All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

const PASTE_START := "\u001b[200~"
const PASTE_END := "\u001b[201~"

var _view: TerminalView


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)
	# Drain any output emitted by spawn_shell during _ready
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


func _make_key_event(keycode: Key, ctrl: bool, shift: bool) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	ev.ctrl_pressed = ctrl
	ev.shift_pressed = shift
	return ev


# ---------------------------------------------------------------------------
# Ctrl+Shift+V
# ---------------------------------------------------------------------------


## Ctrl+Shift+V reads clipboard and sends via write_input.
func test_paste_from_clipboard_ctrl_shift_v() -> void:
	_view._clipboard_override = "hello world"
	_view._bracketed_paste_mode = false

	_view._input(_make_key_event(KEY_V, true, true))

	assert_int(TerminalManager._mock_history.size()).is_equal(1)
	assert_str(TerminalManager._mock_history[0]).is_equal("hello world")


## Ctrl+Shift+V with empty clipboard sends nothing.
func test_ctrl_shift_v_with_empty_clipboard_sends_nothing() -> void:
	_view._clipboard_override = ""
	_view._bracketed_paste_mode = false

	_view._input(_make_key_event(KEY_V, true, true))

	assert_int(TerminalManager._mock_history.size()).is_equal(0)


# ---------------------------------------------------------------------------
# Shift+Insert
# ---------------------------------------------------------------------------


## Shift+Insert reads clipboard and sends via write_input.
func test_paste_from_clipboard_shift_insert() -> void:
	_view._clipboard_override = "hello world"
	_view._bracketed_paste_mode = false

	_view._input(_make_key_event(KEY_INSERT, false, true))

	assert_int(TerminalManager._mock_history.size()).is_equal(1)
	assert_str(TerminalManager._mock_history[0]).is_equal("hello world")


## Shift+Insert with empty clipboard sends nothing.
func test_shift_insert_with_empty_clipboard_sends_nothing() -> void:
	_view._clipboard_override = ""
	_view._bracketed_paste_mode = false

	_view._input(_make_key_event(KEY_INSERT, false, true))

	assert_int(TerminalManager._mock_history.size()).is_equal(0)


# ---------------------------------------------------------------------------
# Bracketed paste mode ON — key bindings wrap the clipboard text
# ---------------------------------------------------------------------------


## Bracketed mode enabled: Ctrl+Shift+V wraps clipboard text.
func test_bracketed_paste_wraps_ctrl_shift_v_when_mode_on() -> void:
	_view._clipboard_override = "multi\nline"
	_view._bracketed_paste_mode = true

	_view._input(_make_key_event(KEY_V, true, true))

	assert_int(TerminalManager._mock_history.size()).is_equal(1)
	var expected := PASTE_START + "multi\nline" + PASTE_END
	assert_str(TerminalManager._mock_history[0]).is_equal(expected)


## Bracketed mode enabled: Shift+Insert wraps clipboard text.
func test_bracketed_paste_wraps_shift_insert_when_mode_on() -> void:
	_view._clipboard_override = "pasted"
	_view._bracketed_paste_mode = true

	_view._input(_make_key_event(KEY_INSERT, false, true))

	assert_int(TerminalManager._mock_history.size()).is_equal(1)
	var expected := PASTE_START + "pasted" + PASTE_END
	assert_str(TerminalManager._mock_history[0]).is_equal(expected)


# ---------------------------------------------------------------------------
# Bracketed paste mode OFF — text sent unwrapped
# ---------------------------------------------------------------------------


## Bracketed mode disabled: Ctrl+Shift+V sends raw clipboard text.
func test_bracketed_paste_not_wrapped_when_mode_off() -> void:
	_view._clipboard_override = "raw text"
	_view._bracketed_paste_mode = false

	_view._input(_make_key_event(KEY_V, true, true))

	assert_int(TerminalManager._mock_history.size()).is_equal(1)
	assert_str(TerminalManager._mock_history[0]).is_equal("raw text")
