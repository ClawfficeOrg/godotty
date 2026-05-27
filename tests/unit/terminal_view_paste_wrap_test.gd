# GdUnit4 test: TerminalView bracketed paste wrapping (task 1.3.2).
#
# Spec: docs/todo-v1.md (task 1.3.2)
#
# Covers: paste_text() wraps payload with ESC[200~…ESC[201~ when
# _bracketed_paste_mode is true; sends bare text when false.
#
# All tests run in mock mode — no GDExtension required.
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


# ---------------------------------------------------------------------------
# paste_text — bracketed mode ON
# ---------------------------------------------------------------------------


func test_paste_wraps_in_bracketed_mode() -> void:
	_view._bracketed_paste_mode = true
	_view.paste_text("hello")
	assert_int(TerminalManager._mock_history.size()).is_equal(1)
	assert_str(TerminalManager._mock_history[0]).is_equal(PASTE_START + "hello" + PASTE_END)


func test_paste_wraps_multiline_text_as_one_call_when_mode_on() -> void:
	_view._bracketed_paste_mode = true
	_view.paste_text("line one\nline two\nline three")
	assert_int(TerminalManager._mock_history.size()).is_equal(1)
	var expected := PASTE_START + "line one\nline two\nline three" + PASTE_END
	assert_str(TerminalManager._mock_history[0]).is_equal(expected)


func test_paste_start_marker_present_when_mode_on() -> void:
	_view._bracketed_paste_mode = true
	_view.paste_text("abc")
	assert_str(TerminalManager._mock_history[0]).starts_with(PASTE_START)


func test_paste_end_marker_present_when_mode_on() -> void:
	_view._bracketed_paste_mode = true
	_view.paste_text("abc")
	assert_str(TerminalManager._mock_history[0]).ends_with(PASTE_END)


# ---------------------------------------------------------------------------
# paste_text — bracketed mode OFF
# ---------------------------------------------------------------------------


func test_paste_unwrapped_when_bracketed_mode_off() -> void:
	_view._bracketed_paste_mode = false
	_view.paste_text("hello")
	assert_int(TerminalManager._mock_history.size()).is_equal(1)
	assert_str(TerminalManager._mock_history[0]).is_equal("hello")


func test_paste_bare_has_no_start_marker_when_mode_off() -> void:
	_view._bracketed_paste_mode = false
	_view.paste_text("text")
	assert_str(TerminalManager._mock_history[0]).is_equal("text")


func test_paste_bare_has_no_end_marker_when_mode_off() -> void:
	_view._bracketed_paste_mode = false
	_view.paste_text("text")
	assert_str(TerminalManager._mock_history[0]).is_equal("text")


# ---------------------------------------------------------------------------
# paste_text — edge cases
# ---------------------------------------------------------------------------


func test_paste_empty_string_sends_nothing() -> void:
	_view._bracketed_paste_mode = true
	_view.paste_text("")
	assert_int(TerminalManager._mock_history.size()).is_equal(0)


func test_paste_empty_string_sends_nothing_when_mode_off() -> void:
	_view._bracketed_paste_mode = false
	_view.paste_text("")
	assert_int(TerminalManager._mock_history.size()).is_equal(0)
