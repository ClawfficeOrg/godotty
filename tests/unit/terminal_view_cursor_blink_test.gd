# GdUnit4 test: TerminalView cursor blink (task 1.1.3).
#
# Spec: docs/todo-v1.md (task 1.1.3)
#
# Covers:
#   - Cursor is visible on startup.
#   - Blink timer is running when view has focus.
#   - Each timer timeout toggles cursor visibility.
#   - Two timeouts restore cursor to visible.
#   - Focus loss stops the timer and holds cursor visible.
#   - Focus regained restarts the timer.
#   - Steady cursor styles are not toggled by the blink timer.
#   - Timer wait_time matches TerminalSettings.cursor_blink_rate.
#
# All tests run in mock mode — no GDExtension required.
# Tests drive the blink callback directly (no real-time waiting) for
# determinism in headless CI.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _saved_rate: float


func before_test() -> void:
	_saved_rate = TerminalSettings.cursor_blink_rate
	TerminalSettings.cursor_blink_rate = 0.05
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null
	TerminalSettings.cursor_blink_rate = _saved_rate


# ---------------------------------------------------------------------------
# Startup state
# ---------------------------------------------------------------------------


func test_cursor_visible_at_startup() -> void:
	assert_bool(_view.cursor_overlay.visible).is_true()


func test_blink_timer_exists_at_startup() -> void:
	assert_object(_view._blink_timer).is_not_null()


func test_blink_timer_running_at_startup() -> void:
	assert_bool(_view._blink_timer.is_stopped()).is_false()


func test_blink_timer_wait_time_matches_settings() -> void:
	assert_float(_view._blink_timer.wait_time).is_equal(0.05)


# ---------------------------------------------------------------------------
# Blink cycle — driven synchronously via _on_blink_timeout
# ---------------------------------------------------------------------------


func test_blink_timeout_hides_cursor() -> void:
	assert_bool(_view.cursor_overlay.visible).is_true()
	_view._on_blink_timeout()
	assert_bool(_view.cursor_overlay.visible).is_false()


func test_blink_two_timeouts_restore_cursor() -> void:
	_view._on_blink_timeout()
	_view._on_blink_timeout()
	assert_bool(_view.cursor_overlay.visible).is_true()


func test_blink_three_timeouts_hide_cursor() -> void:
	_view._on_blink_timeout()
	_view._on_blink_timeout()
	_view._on_blink_timeout()
	assert_bool(_view.cursor_overlay.visible).is_false()


# ---------------------------------------------------------------------------
# Focus handling
# ---------------------------------------------------------------------------


func test_blink_stops_when_input_focus_lost() -> void:
	assert_bool(_view._blink_timer.is_stopped()).is_false()
	_view.input_field.focus_exited.emit()
	assert_bool(_view._blink_timer.is_stopped()).is_true()


func test_cursor_visible_after_focus_lost() -> void:
	# Blink once so cursor is hidden, then lose focus — should restore visibility.
	_view._on_blink_timeout()
	assert_bool(_view.cursor_overlay.visible).is_false()
	_view.input_field.focus_exited.emit()
	assert_bool(_view.cursor_overlay.visible).is_true()


func test_blink_resumes_when_input_focus_gained() -> void:
	_view.input_field.focus_exited.emit()
	assert_bool(_view._blink_timer.is_stopped()).is_true()
	_view.input_field.focus_entered.emit()
	assert_bool(_view._blink_timer.is_stopped()).is_false()


func test_cursor_visible_on_focus_regain() -> void:
	# Lose focus (hides-if-hidden, holds visible), then regain.
	_view.input_field.focus_exited.emit()
	_view.input_field.focus_entered.emit()
	assert_bool(_view.cursor_overlay.visible).is_true()


# ---------------------------------------------------------------------------
# Steady cursor styles do not blink
# ---------------------------------------------------------------------------


func test_steady_block_does_not_hide_on_timeout() -> void:
	_view.cursor_style = TerminalView.CursorStyle.STEADY_BLOCK
	_view._on_blink_timeout()
	assert_bool(_view.cursor_overlay.visible).is_true()


func test_steady_underline_does_not_hide_on_timeout() -> void:
	_view.cursor_style = TerminalView.CursorStyle.STEADY_UNDERLINE
	_view._on_blink_timeout()
	assert_bool(_view.cursor_overlay.visible).is_true()


func test_steady_bar_does_not_hide_on_timeout() -> void:
	_view.cursor_style = TerminalView.CursorStyle.STEADY_BAR
	_view._on_blink_timeout()
	assert_bool(_view.cursor_overlay.visible).is_true()


func test_blinking_block_does_hide_on_timeout() -> void:
	_view.cursor_style = TerminalView.CursorStyle.BLINKING_BLOCK
	_view._on_blink_timeout()
	assert_bool(_view.cursor_overlay.visible).is_false()
