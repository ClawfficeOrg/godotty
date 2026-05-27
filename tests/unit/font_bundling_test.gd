# GdUnit4 test: bundled Nerd Font loads and contains Powerline glyphs (task 2.1.3).
#
# Spec: docs/todo-v2.md (task 2.1.3)
#
# Covers:
#   - Font file is present and loadable via Godot resource system.
#   - Powerline right-arrow separator U+E0B0 is present in the font.
#
# All tests are headless-safe: they use the font glyph API (has_char),
# not rasterisation, so they pass without a display server.
extends GdUnitTestSuite

const FONT_PATH := "res://resources/fonts/JetBrainsMonoNerdFont-Regular.ttf"

# U+E0B0  POWERLINE RIGHT-POINTING ANGLE QUOTATION MARK (right arrow)
const POWERLINE_RIGHT_ARROW := 0xE0B0


func test_font_file_loads() -> void:
	var font: FontFile = load(FONT_PATH) as FontFile
	assert_object(font).is_not_null()


func test_font_file_is_fontfile_type() -> void:
	var font: FontFile = load(FONT_PATH) as FontFile
	assert_bool(font is FontFile).is_true()


func test_powerline_separator_glyph_present() -> void:
	var font: FontFile = load(FONT_PATH) as FontFile
	assert_object(font).is_not_null()
	assert_bool(font.has_char(POWERLINE_RIGHT_ARROW)).is_true()
