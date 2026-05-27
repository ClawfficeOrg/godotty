# GdUnit4 test: TerminalView visual bell (task 2.4.3).
#
# Spec: docs/todo-v2.md (task 2.4.3)
#
# Covers:
#   - BEL character (\u0007) triggers self_modulate change to bell_color.
#   - self_modulate is restored to original after the tween completes.
#   - bell_color exported var defaults to Color.WHITE.
#   - audio_bell enabled does not crash (DisplayServer.beep() is a no-op headless).
#
# All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _saved_audio_bell: bool


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_saved_audio_bell = TerminalSettings.audio_bell
	TerminalSettings.audio_bell = false
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	TerminalSettings.audio_bell = _saved_audio_bell
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# Exported bell_color default
# ---------------------------------------------------------------------------


func test_bell_color_default_is_white() -> void:
	assert_bool(_view.bell_color == Color.WHITE).is_true()


# ---------------------------------------------------------------------------
# BEL triggers self_modulate change
# ---------------------------------------------------------------------------


func test_bell_modulates_to_bell_color() -> void:
	# Set a known non-white original state so we can detect the flash.
	_view.self_modulate = Color(0.1, 0.2, 0.3, 1.0)
	_view.bell_color = Color.WHITE

	# Trigger BEL through the output pipeline.
	_view._on_output_ready(char(7))

	# Immediately after, self_modulate should equal bell_color (flash was applied).
	assert_bool(_view.self_modulate == Color.WHITE).is_true()


func test_bell_restores_self_modulate_after_duration() -> void:
	var original := Color(0.1, 0.2, 0.3, 1.0)
	_view.self_modulate = original
	_view.bell_color = Color.WHITE

	_view._on_output_ready(char(7))

	# Wait longer than BELL_DURATION (0.15 s) for the tween to complete.
	await get_tree().create_timer(0.25).timeout

	assert_float(_view.self_modulate.r).is_equal_approx(original.r, 0.01)
	assert_float(_view.self_modulate.g).is_equal_approx(original.g, 0.01)
	assert_float(_view.self_modulate.b).is_equal_approx(original.b, 0.01)


# ---------------------------------------------------------------------------
# Audio bell does not crash (smoke test only — DisplayServer.beep() is no-op
# in headless CI)
# ---------------------------------------------------------------------------


func test_bell_with_audio_bell_enabled_no_crash() -> void:
	TerminalSettings.audio_bell = true
	# Should complete without exception.
	_view._on_output_ready(char(7))
	# If we reach here, no crash occurred.
	assert_bool(true).is_true()
