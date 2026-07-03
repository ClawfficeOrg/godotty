# GdUnit4 test: TerminalView applies TerminalSettings font to OutputDisplay (task 2.1.2).
#
# Spec: docs/todo-v2.md (task 2.1.2)
#
# Covers:
#   - apply_font_settings() recomputes char_width as font_size ? 0.5.
#   - apply_font_settings() recomputes line_height as font_size ? 1.0.
#   - Cursor overlay pixel position updates to reflect new char_width / line_height.
#   - OutputDisplay receives a font_size theme override.
#
# All tests run in mock mode -- no GDExtension required.
# Notes: we assert exact computed values rather than pixel distances to stay
# deterministic across headless environments.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _saved_font_size: int


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_saved_font_size = TerminalSettings.font_size
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	TerminalSettings.font_size = _saved_font_size
	TerminalSettings.font = null
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# char_width / line_height recomputed on apply_font_settings
# ---------------------------------------------------------------------------


func test_char_width_matches_half_font_size() -> void:
	TerminalSettings.font_size = 20
	_view.apply_font_settings()
	assert_float(_view.char_width).is_equal(12.0)


func test_char_width_with_small_font_size() -> void:
	TerminalSettings.font_size = 10
	_view.apply_font_settings()
	assert_float(_view.char_width).is_equal(6.0)


func test_line_height_matches_font_size() -> void:
	TerminalSettings.font_size = 20
	_view.apply_font_settings()
	assert_float(_view.line_height).is_equal(20.0)


func test_line_height_with_small_font_size() -> void:
	TerminalSettings.font_size = 10
	_view.apply_font_settings()
	assert_float(_view.line_height).is_equal(10.0)


func test_default_font_size_gives_char_w_constant() -> void:
	TerminalSettings.font_size = 16
	_view.apply_font_settings()
	assert_float(_view.line_height).is_equal(16.0)


# ---------------------------------------------------------------------------
# Cursor overlay position updates after font change
# ---------------------------------------------------------------------------


func test_cursor_pixel_x_updates_after_font_change() -> void:
	_view.cursor_row = 0
	_view.cursor_col = 3
	# font_size=10 -> measured char_width=6.0 -> x = 3 * 6.0 = 18.0
	TerminalSettings.font_size = 10
	_view.apply_font_settings()
	assert_float(_view.cursor_overlay.position.x).is_equal_approx(18.0, 0.01)


func test_cursor_pixel_y_updates_after_font_change() -> void:
	_view.cursor_row = 2
	_view.cursor_col = 0
	# font_size=10 -> line_height=10.0 -> y = 2 * 10.0 = 20.0
	TerminalSettings.font_size = 10
	_view.apply_font_settings()
	assert_float(_view.cursor_overlay.position.y).is_equal_approx(20.0, 0.01)


func test_cursor_position_differs_between_font_sizes() -> void:
	_view.cursor_row = 1
	_view.cursor_col = 2
	TerminalSettings.font_size = 16
	_view.apply_font_settings()
	var pos_large: Vector2 = _view.cursor_overlay.position
	TerminalSettings.font_size = 8
	_view.apply_font_settings()
	var pos_small: Vector2 = _view.cursor_overlay.position
	# smaller font -> smaller pixel offset for same logical cell
	assert_bool(pos_small.x < pos_large.x).is_true()
	assert_bool(pos_small.y < pos_large.y).is_true()


# ---------------------------------------------------------------------------
# OutputDisplay receives a font_size theme override
# ---------------------------------------------------------------------------


func test_font_size_override_applied_to_output_display() -> void:
	TerminalSettings.font_size = 24
	_view.apply_font_settings()
	assert_bool(_view.output_display.has_theme_font_size_override("normal_font_size")).is_true()


func test_font_size_override_value_matches_settings() -> void:
	TerminalSettings.font_size = 18
	_view.apply_font_settings()
	assert_int(_view.output_display.get_theme_font_size("normal_font_size")).is_equal(18)
