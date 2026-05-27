# GdUnit4 test: TerminalView applies TerminalSettings.background_opacity (task 2.4.1).
#
# Spec: docs/todo-v2.md (task 2.4.1)
#
# Covers:
#   - apply_background_opacity() sets self_modulate.a to the given value.
#   - opacity 0.5 -> self_modulate.a == 0.5.
#   - opacity 1.0 -> self_modulate.a == 1.0 (fully opaque).
#   - out-of-range values are clamped: -0.2 -> 0.0, 1.5 -> 1.0.
#
# All tests run in mock mode -- no GDExtension required.
# Note: OS-level window transparency is not tested here (requires a non-headless
# DisplayServer). Only the panel's self_modulate.a is asserted.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _saved_opacity: float


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_saved_opacity = TerminalSettings.background_opacity
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	TerminalSettings.background_opacity = _saved_opacity
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# apply_background_opacity sets self_modulate.a
# ---------------------------------------------------------------------------


func test_opacity_half_sets_panel_alpha() -> void:
	TerminalSettings.background_opacity = 0.5
	_view.apply_background_opacity()
	assert_float(_view.self_modulate.a).is_equal_approx(0.5, 0.001)


func test_opacity_one_sets_panel_fully_opaque() -> void:
	TerminalSettings.background_opacity = 1.0
	_view.apply_background_opacity()
	assert_float(_view.self_modulate.a).is_equal_approx(1.0, 0.001)


func test_opacity_zero_sets_panel_fully_transparent() -> void:
	TerminalSettings.background_opacity = 0.0
	_view.apply_background_opacity()
	assert_float(_view.self_modulate.a).is_equal_approx(0.0, 0.001)


func test_opacity_clamped_below_zero() -> void:
	TerminalSettings.background_opacity = -0.2
	_view.apply_background_opacity()
	assert_float(_view.self_modulate.a).is_equal_approx(0.0, 0.001)


func test_opacity_clamped_above_one() -> void:
	TerminalSettings.background_opacity = 1.5
	_view.apply_background_opacity()
	assert_float(_view.self_modulate.a).is_equal_approx(1.0, 0.001)


func test_default_opacity_is_fully_opaque_at_ready() -> void:
	# A freshly-instantiated view with default opacity=1.0 must be opaque.
	assert_float(TerminalSettings.background_opacity).is_equal_approx(1.0, 0.001)
	assert_float(_view.self_modulate.a).is_equal_approx(1.0, 0.001)


func test_rgb_channels_unaffected_by_apply_background_opacity() -> void:
	# apply_background_opacity must not alter the RGB channels of self_modulate.
	var before := _view.self_modulate
	TerminalSettings.background_opacity = 0.5
	_view.apply_background_opacity()
	assert_float(_view.self_modulate.r).is_equal_approx(before.r, 0.001)
	assert_float(_view.self_modulate.g).is_equal_approx(before.g, 0.001)
	assert_float(_view.self_modulate.b).is_equal_approx(before.b, 0.001)
