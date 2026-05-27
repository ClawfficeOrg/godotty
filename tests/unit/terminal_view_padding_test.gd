# GdUnit4 test: TerminalView applies TerminalSettings.padding via PaddingContainer (task 2.4.2).
#
# Spec: docs/todo-v2.md (task 2.4.2)
#
# Covers:
#   - TerminalSettings.padding default is Vector2i(4, 4).
#   - apply_padding() sets MarginContainer insets from TerminalSettings.padding.
#   - padding (10, 10) -> 10 px inset on each side.
#   - padding (0, 0) -> 0 px inset on each side.
#   - x maps to left/right; y maps to top/bottom independently.
#
# All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _saved_padding: Vector2i


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_saved_padding = TerminalSettings.padding
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	TerminalSettings.padding = _saved_padding
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# Default padding
# ---------------------------------------------------------------------------


func test_default_padding_setting_is_4_4() -> void:
	assert_int(TerminalSettings.padding.x).is_equal(4)
	assert_int(TerminalSettings.padding.y).is_equal(4)


func test_default_padding_applied_at_ready() -> void:
	var mc: MarginContainer = _view.padding_container
	assert_int(mc.get_theme_constant("margin_left")).is_equal(4)
	assert_int(mc.get_theme_constant("margin_right")).is_equal(4)
	assert_int(mc.get_theme_constant("margin_top")).is_equal(4)
	assert_int(mc.get_theme_constant("margin_bottom")).is_equal(4)


# ---------------------------------------------------------------------------
# apply_padding with (10, 10)
# ---------------------------------------------------------------------------


func test_padding_10_10_sets_all_margins_to_10() -> void:
	TerminalSettings.padding = Vector2i(10, 10)
	_view.apply_padding()
	var mc: MarginContainer = _view.padding_container
	assert_int(mc.get_theme_constant("margin_left")).is_equal(10)
	assert_int(mc.get_theme_constant("margin_right")).is_equal(10)
	assert_int(mc.get_theme_constant("margin_top")).is_equal(10)
	assert_int(mc.get_theme_constant("margin_bottom")).is_equal(10)


# ---------------------------------------------------------------------------
# apply_padding with (0, 0)
# ---------------------------------------------------------------------------


func test_padding_0_0_sets_all_margins_to_0() -> void:
	TerminalSettings.padding = Vector2i(0, 0)
	_view.apply_padding()
	var mc: MarginContainer = _view.padding_container
	assert_int(mc.get_theme_constant("margin_left")).is_equal(0)
	assert_int(mc.get_theme_constant("margin_right")).is_equal(0)
	assert_int(mc.get_theme_constant("margin_top")).is_equal(0)
	assert_int(mc.get_theme_constant("margin_bottom")).is_equal(0)


# ---------------------------------------------------------------------------
# x and y axes are independent
# ---------------------------------------------------------------------------


func test_asymmetric_padding_x_16_y_8() -> void:
	TerminalSettings.padding = Vector2i(16, 8)
	_view.apply_padding()
	var mc: MarginContainer = _view.padding_container
	assert_int(mc.get_theme_constant("margin_left")).is_equal(16)
	assert_int(mc.get_theme_constant("margin_right")).is_equal(16)
	assert_int(mc.get_theme_constant("margin_top")).is_equal(8)
	assert_int(mc.get_theme_constant("margin_bottom")).is_equal(8)
