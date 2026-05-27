# GdUnit4 test: TerminalView cursor rendering (task 1.1.1).
#
# Spec: docs/todo-v1.md (task 1.1.1)
#
# Covers: CursorOverlay ColorRect visible at startup at grid (0,0);
#         position update after CSI cursor-position sequence (primary screen).
#
# All tests run in mock mode — no GDExtension required.
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
# Startup state
# ---------------------------------------------------------------------------


func test_cursor_overlay_exists_and_visible_at_startup() -> void:
	assert_object(_view.cursor_overlay).is_not_null()
	assert_bool(_view.cursor_overlay.visible).is_true()


func test_cursor_at_origin_on_startup() -> void:
	assert_int(_view.cursor_row).is_equal(0)
	assert_int(_view.cursor_col).is_equal(0)
	assert_float(_view.cursor_overlay.position.x).is_equal(0.0)
	assert_float(_view.cursor_overlay.position.y).is_equal(0.0)


# ---------------------------------------------------------------------------
# CSI H — cursor position moves the overlay
# ---------------------------------------------------------------------------


func test_csi_h_moves_cursor_to_row_col() -> void:
	# CSI 3;5H → 1-based row=3, col=5 → 0-based row=2, col=4
	SignalBus.output_ready.emit("\u001b[3;5H")
	assert_int(_view.cursor_row).is_equal(2)
	assert_int(_view.cursor_col).is_equal(4)
	assert_float(_view.cursor_overlay.position.x).is_equal(4.0 * TerminalView.CHAR_W)
	assert_float(_view.cursor_overlay.position.y).is_equal(2.0 * TerminalView.CHAR_H)
