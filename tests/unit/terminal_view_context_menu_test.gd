## GdUnit4 tests: right-click context menu in TerminalView (task 1.4.4).
##
## Spec: docs/todo-v1.md (task 1.4.4)
##
## Covers:
##   - Right-click sets _context_menu_popup_requested.
##   - Copy item is disabled when there is no active text selection.
##   - Copy item is enabled when text is selected.
##   - Copy menu action fires copy_selected_to_clipboard().
##   - Paste menu action fires paste_text().
##   - Clear menu action fires TerminalManager.clear().
##
## All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# Helper: write text into alt grid at row 0 for selection-based tests.
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


func _make_right_click(pos: Vector2) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_RIGHT
	ev.pressed = true
	ev.position = pos
	return ev


# ---------------------------------------------------------------------------
# Tests: popup requested
# ---------------------------------------------------------------------------


## Right-clicking sets _context_menu_popup_requested to true.
func test_right_click_sets_popup_requested() -> void:
	_view._gui_input(_make_right_click(Vector2(10.0, 10.0)))
	assert_bool(_view._context_menu_popup_requested).is_true()


## Repeated right-clicks keep _context_menu_popup_requested true.
func test_right_click_popup_requested_stays_true_on_second_click() -> void:
	_view._gui_input(_make_right_click(Vector2(10.0, 10.0)))
	_view._context_menu_popup_requested = false
	_view._gui_input(_make_right_click(Vector2(20.0, 20.0)))
	assert_bool(_view._context_menu_popup_requested).is_true()


# ---------------------------------------------------------------------------
# Tests: Copy item enabled/disabled based on selection
# ---------------------------------------------------------------------------


## No selection -> Copy item is disabled after right-click.
func test_copy_disabled_when_no_selection() -> void:
	_view.selection_start = Vector2i(-1, -1)
	_view.selection_end = Vector2i(-1, -1)
	_view._gui_input(_make_right_click(Vector2(10.0, 10.0)))
	var idx: int = _view._context_menu.get_item_index(TerminalView.MENU_ID_COPY)
	assert_bool(_view._context_menu.is_item_disabled(idx)).is_true()


## Active selection -> Copy item is enabled after right-click.
func test_copy_enabled_when_text_selected() -> void:
	_write_alt_grid("hello")
	_view.selection_start = Vector2i(0, 0)
	_view.selection_end = Vector2i(4, 0)
	_view._gui_input(_make_right_click(Vector2(10.0, 10.0)))
	var idx: int = _view._context_menu.get_item_index(TerminalView.MENU_ID_COPY)
	assert_bool(_view._context_menu.is_item_disabled(idx)).is_false()


# ---------------------------------------------------------------------------
# Tests: menu item actions
# ---------------------------------------------------------------------------


## Activating Copy from the context menu copies selected text.
func test_context_menu_copy_action_copies_selected_text() -> void:
	_write_alt_grid("world")
	_view.selection_start = Vector2i(0, 0)
	_view.selection_end = Vector2i(4, 0)
	_view._on_context_menu_id_pressed(TerminalView.MENU_ID_COPY)
	assert_str(_view._last_copied_text).is_equal("world")


## Activating Paste from the context menu sends clipboard text to terminal.
func test_context_menu_paste_action_sends_clipboard_text() -> void:
	_view._clipboard_override = "pasted"
	_view._on_context_menu_id_pressed(TerminalView.MENU_ID_PASTE)
	assert_bool(TerminalManager._mock_history.size() > 0).is_true()
	assert_str(TerminalManager._mock_history[-1]).is_equal("pasted")


## Activating Clear from the context menu clears the mock output buffer.
func test_context_menu_clear_action_clears_output() -> void:
	TerminalManager._mock_output_buffer.append("some output")
	_view._on_context_menu_id_pressed(TerminalView.MENU_ID_CLEAR)
	assert_bool(TerminalManager._mock_output_buffer.is_empty()).is_true()


# ---------------------------------------------------------------------------
# Tests: left-click still sets selection (regression guard)
# ---------------------------------------------------------------------------


## Left-click still sets selection_start (right-click handler does not break it).
func test_left_click_still_sets_selection_start() -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(0.0, 0.0)
	_view._gui_input(ev)
	assert_that(_view.selection_start).is_equal(Vector2i(0, 0))
