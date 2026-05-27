# GdUnit4 test: TerminalView cursor hide/show via DEC private mode 25 (task 1.1.4).
#
# Spec: docs/todo-v1.md (task 1.1.4)
#
# Covers:
#   - Cursor is visible by default (_cursor_dec_visible = true).
#   - CSI ?25l hides the cursor overlay and clears _cursor_dec_visible.
#   - CSI ?25h restores the cursor overlay and sets _cursor_dec_visible.
#   - Blink timer timeouts do not show a DEC-hidden cursor.
#   - Focus regain does not show a DEC-hidden cursor.
#   - Focus regain after ?25h restores the cursor correctly.
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
# Default state
# ---------------------------------------------------------------------------


func test_cursor_dec_visible_is_true_by_default() -> void:
	assert_bool(_view._cursor_dec_visible).is_true()


func test_cursor_overlay_visible_at_startup() -> void:
	assert_bool(_view.cursor_overlay.visible).is_true()


# ---------------------------------------------------------------------------
# CSI ?25l — hide cursor
# ---------------------------------------------------------------------------


func test_csi_question25l_hides_cursor_overlay() -> void:
	SignalBus.output_ready.emit("\u001b[?25l")
	assert_bool(_view.cursor_overlay.visible).is_false()


func test_csi_question25l_sets_dec_visible_false() -> void:
	SignalBus.output_ready.emit("\u001b[?25l")
	assert_bool(_view._cursor_dec_visible).is_false()


# ---------------------------------------------------------------------------
# CSI ?25h — show cursor
# ---------------------------------------------------------------------------


func test_csi_question25h_shows_cursor_overlay() -> void:
	SignalBus.output_ready.emit("\u001b[?25l")
	assert_bool(_view.cursor_overlay.visible).is_false()
	SignalBus.output_ready.emit("\u001b[?25h")
	assert_bool(_view.cursor_overlay.visible).is_true()


func test_csi_question25h_sets_dec_visible_true() -> void:
	SignalBus.output_ready.emit("\u001b[?25l")
	SignalBus.output_ready.emit("\u001b[?25h")
	assert_bool(_view._cursor_dec_visible).is_true()


func test_csi_question25h_idempotent_when_already_visible() -> void:
	assert_bool(_view.cursor_overlay.visible).is_true()
	SignalBus.output_ready.emit("\u001b[?25h")
	assert_bool(_view.cursor_overlay.visible).is_true()
	assert_bool(_view._cursor_dec_visible).is_true()


# ---------------------------------------------------------------------------
# Blink timer interaction
# ---------------------------------------------------------------------------


func test_blink_timeout_does_not_show_hidden_cursor() -> void:
	SignalBus.output_ready.emit("\u001b[?25l")
	_view._on_blink_timeout()
	assert_bool(_view.cursor_overlay.visible).is_false()


func test_multiple_blink_timeouts_do_not_show_hidden_cursor() -> void:
	SignalBus.output_ready.emit("\u001b[?25l")
	_view._on_blink_timeout()
	_view._on_blink_timeout()
	_view._on_blink_timeout()
	assert_bool(_view.cursor_overlay.visible).is_false()


# ---------------------------------------------------------------------------
# Focus interaction
# ---------------------------------------------------------------------------


func test_focus_regain_does_not_show_dec_hidden_cursor() -> void:
	SignalBus.output_ready.emit("\u001b[?25l")
	_view.input_field.focus_entered.emit()
	assert_bool(_view.cursor_overlay.visible).is_false()


func test_focus_loss_does_not_show_dec_hidden_cursor() -> void:
	SignalBus.output_ready.emit("\u001b[?25l")
	_view.input_field.focus_exited.emit()
	assert_bool(_view.cursor_overlay.visible).is_false()


func test_show_cursor_after_hide_and_focus_loss() -> void:
	SignalBus.output_ready.emit("\u001b[?25l")
	_view.input_field.focus_exited.emit()
	SignalBus.output_ready.emit("\u001b[?25h")
	assert_bool(_view.cursor_overlay.visible).is_true()
