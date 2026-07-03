## Tests for TerminalSettings static class (project/scripts/terminal_settings.gd).
##
## Spec: task 2.1.1 (rewritten for refactored static-class version)
##
## Coverage:
##   - Default static property values.
##   - Const arrays contain expected entries.
##   - Static var assignment and read-back.
extends GdUnitTestSuite


# ---------------------------------------------------------------------------
# Default values
# ---------------------------------------------------------------------------


func test_default_font_size_is_20() -> void:
	assert_int(TerminalSettings.font_size).is_equal(20)


func test_default_cursor_blink_rate_is_half() -> void:
	assert_float(TerminalSettings.cursor_blink_rate).is_equal_approx(0.5, 0.001)


func test_default_background_opacity_is_one() -> void:
	assert_float(TerminalSettings.background_opacity).is_equal_approx(1.0, 0.001)


func test_default_padding_is_4x4() -> void:
	assert_vector(TerminalSettings.padding).is_equal(Vector2i(4, 4))


func test_default_scrollback_lines_is_1000() -> void:
	assert_int(TerminalSettings.scrollback_lines).is_equal(1000)


func test_default_audio_bell_is_false() -> void:
	assert_bool(TerminalSettings.audio_bell).is_false()


func test_default_font_is_loaded() -> void:
	assert_object(TerminalSettings.font).is_not_null()


# ---------------------------------------------------------------------------
# Const arrays
# ---------------------------------------------------------------------------


func test_bundled_theme_names_includes_default() -> void:
	assert_bool(TerminalSettings.BUNDLED_THEME_NAMES.has("Default")).is_true()


func test_bundled_theme_names_has_at_least_8_themes() -> void:
	assert_int(TerminalSettings.BUNDLED_THEME_NAMES.size()).is_greater_equal(8)


func test_bundled_font_names_includes_jetbrains() -> void:
	assert_bool(TerminalSettings.BUNDLED_FONT_NAMES.has("JetBrains Mono Nerd")).is_true()


func test_bundled_font_paths_has_jetbrains() -> void:
	var path: String = TerminalSettings.BUNDLED_FONT_PATHS.get("JetBrains Mono Nerd", "")
	assert_bool(path.contains("JetBrainsMonoNerdFont")).is_true()


# ---------------------------------------------------------------------------
# Assignment and read-back
# ---------------------------------------------------------------------------


func test_assign_and_read_font_size() -> void:
	TerminalSettings.font_size = 32
	assert_int(TerminalSettings.font_size).is_equal(32)
	TerminalSettings.font_size = 20


func test_assign_and_read_cursor_blink_rate() -> void:
	TerminalSettings.cursor_blink_rate = 1.0
	assert_float(TerminalSettings.cursor_blink_rate).is_equal_approx(1.0, 0.001)
	TerminalSettings.cursor_blink_rate = 0.5


func test_assign_and_read_background_opacity() -> void:
	TerminalSettings.background_opacity = 0.5
	assert_float(TerminalSettings.background_opacity).is_equal_approx(0.5, 0.001)
	TerminalSettings.background_opacity = 1.0


func test_assign_and_read_padding() -> void:
	TerminalSettings.padding = Vector2i(16, 8)
	assert_vector(TerminalSettings.padding).is_equal(Vector2i(16, 8))
	TerminalSettings.padding = Vector2i(4, 4)
