## GdUnit4 tests: clipboard copy in TerminalView (task 1.4.2).
##
## Spec: docs/todo-v1.md (task 1.4.2)
##
## Covers:
##   - Ctrl+Shift+C copies selected alt-screen text to clipboard.
##   - Ctrl+Insert copies selected alt-screen text to clipboard.
##   - Empty selection produces no copy (_last_copied_text unchanged).
##   - copy_selected_to_clipboard() is callable directly from tests.
##
## All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# Helper: write a string into the alt grid starting at (row=0, col=0).
# ---------------------------------------------------------------------------


func _write_alt_grid(text: String) -> void:
	_view._in_alternate_screen = true
	_view._alt_grid = TerminalGrid.new()
	_view._alt_grid.resize(80, 24)
	for i in range(text.length()):
		(
			_view
			. _alt_grid
			. set_cell(
				0,
				i,
				{
					"char": text[i],
					"fg": Color.WHITE,
					"bg": Color.BLACK,
					"bold": false,
					"italic": false,
					"underline": false,
					"url": "",
				}
			)
		)


func _make_key_event(keycode: Key, ctrl: bool, shift: bool) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	ev.ctrl_pressed = ctrl
	ev.shift_pressed = shift
	return ev


# ---------------------------------------------------------------------------
# Tests: Ctrl+Shift+C
# ---------------------------------------------------------------------------


## Select "hello" in alt screen, press Ctrl+Shift+C → _last_copied_text is "hello".
func test_copy_selected_word_with_ctrl_shift_c() -> void:
	_write_alt_grid("hello")
	_view.selection_start = Vector2i(0, 0)
	_view.selection_end = Vector2i(4, 0)

	_view._input(_make_key_event(KEY_C, true, true))

	assert_str(_view._last_copied_text).is_equal("hello")


## Select partial text "hel" (cols 0-2), Ctrl+Shift+C → clipboard is "hel".
func test_copy_partial_selection_ctrl_shift_c() -> void:
	_write_alt_grid("hello")
	_view.selection_start = Vector2i(0, 0)
	_view.selection_end = Vector2i(2, 0)

	_view._input(_make_key_event(KEY_C, true, true))

	assert_str(_view._last_copied_text).is_equal("hel")


# ---------------------------------------------------------------------------
# Tests: Ctrl+Insert
# ---------------------------------------------------------------------------


## Select "world" in alt screen, press Ctrl+Insert → _last_copied_text is "world".
func test_copy_selection_with_ctrl_insert() -> void:
	_write_alt_grid("world")
	_view.selection_start = Vector2i(0, 0)
	_view.selection_end = Vector2i(4, 0)

	_view._input(_make_key_event(KEY_INSERT, true, false))

	assert_str(_view._last_copied_text).is_equal("world")


# ---------------------------------------------------------------------------
# Tests: empty / no selection
# ---------------------------------------------------------------------------


## No selection → Ctrl+Shift+C does nothing (_last_copied_text stays empty).
func test_no_selection_copy_does_nothing() -> void:
	_view.selection_start = Vector2i(-1, -1)
	_view.selection_end = Vector2i(-1, -1)

	_view._input(_make_key_event(KEY_C, true, true))

	assert_str(_view._last_copied_text).is_equal("")


## No selection → Ctrl+Insert does nothing.
func test_no_selection_ctrl_insert_does_nothing() -> void:
	_view.selection_start = Vector2i(-1, -1)
	_view.selection_end = Vector2i(-1, -1)

	_view._input(_make_key_event(KEY_INSERT, true, false))

	assert_str(_view._last_copied_text).is_equal("")


# ---------------------------------------------------------------------------
# Tests: copy_selected_to_clipboard() direct call
# ---------------------------------------------------------------------------


## Direct call to copy_selected_to_clipboard() copies selected text.
func test_direct_copy_call_sets_last_copied_text() -> void:
	_write_alt_grid("abc")
	_view.selection_start = Vector2i(0, 0)
	_view.selection_end = Vector2i(2, 0)

	_view.copy_selected_to_clipboard()

	assert_str(_view._last_copied_text).is_equal("abc")


## Direct call with no selection leaves _last_copied_text unchanged.
func test_direct_copy_call_with_no_selection_is_noop() -> void:
	_view._last_copied_text = "previous"
	_view.selection_start = Vector2i(-1, -1)
	_view.selection_end = Vector2i(-1, -1)

	_view.copy_selected_to_clipboard()

	assert_str(_view._last_copied_text).is_equal("previous")


# ---------------------------------------------------------------------------
# Tests: Ctrl+C alone still triggers interrupt (not copy)
# ---------------------------------------------------------------------------


## Plain Ctrl+C (no Shift) must NOT copy to clipboard.
func test_ctrl_c_without_shift_does_not_copy() -> void:
	_write_alt_grid("hello")
	_view.selection_start = Vector2i(0, 0)
	_view.selection_end = Vector2i(4, 0)
	_view._last_copied_text = ""

	# Ctrl+C without shift → _handle_interrupt(), not copy
	_view._input(_make_key_event(KEY_C, true, false))

	assert_str(_view._last_copied_text).is_equal("")
