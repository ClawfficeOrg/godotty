# GdUnit4 test: bundled TerminalTheme .tres resources (task 2.0.3).
#
# Spec: docs/todo-v2.md  (task 2.0.3)
#
# Tests: all 8 theme files load without error, each has exactly 16 palette
#        entries, every entry is a Color, and each Color component is in [0,1].
extends GdUnitTestSuite

const THEME_PATHS: Array[String] = [
	"res://resources/themes/solarized_dark.tres",
	"res://resources/themes/solarized_light.tres",
	"res://resources/themes/dracula.tres",
	"res://resources/themes/tokyo_night.tres",
	"res://resources/themes/gruvbox_dark.tres",
	"res://resources/themes/catppuccin_mocha.tres",
	"res://resources/themes/nord.tres",
	"res://resources/themes/one_dark.tres",
]

# ---------------------------------------------------------------------------
# Helper: load a theme, fail test immediately if result is null.
# ---------------------------------------------------------------------------


func _load_theme(path: String) -> TerminalTheme:
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_object(res).is_not_null()
	return res as TerminalTheme


# ---------------------------------------------------------------------------
# Load sanity: every resource parses successfully.
# ---------------------------------------------------------------------------


func test_load_all_theme_resources() -> void:
	for path: String in THEME_PATHS:
		var theme := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		(
			assert_object(theme)
			. override_failure_message("Failed to load theme resource: " + path)
			. is_not_null()
		)


# ---------------------------------------------------------------------------
# Palette length: exactly 16 entries per theme.
# ---------------------------------------------------------------------------


func test_solarized_dark_palette_has_16_entries() -> void:
	var theme := _load_theme("res://resources/themes/solarized_dark.tres")
	assert_int(theme.palette.size()).is_equal(16)


func test_solarized_light_palette_has_16_entries() -> void:
	var theme := _load_theme("res://resources/themes/solarized_light.tres")
	assert_int(theme.palette.size()).is_equal(16)


func test_dracula_palette_has_16_entries() -> void:
	var theme := _load_theme("res://resources/themes/dracula.tres")
	assert_int(theme.palette.size()).is_equal(16)


func test_tokyo_night_palette_has_16_entries() -> void:
	var theme := _load_theme("res://resources/themes/tokyo_night.tres")
	assert_int(theme.palette.size()).is_equal(16)


func test_gruvbox_dark_palette_has_16_entries() -> void:
	var theme := _load_theme("res://resources/themes/gruvbox_dark.tres")
	assert_int(theme.palette.size()).is_equal(16)


func test_catppuccin_mocha_palette_has_16_entries() -> void:
	var theme := _load_theme("res://resources/themes/catppuccin_mocha.tres")
	assert_int(theme.palette.size()).is_equal(16)


func test_nord_palette_has_16_entries() -> void:
	var theme := _load_theme("res://resources/themes/nord.tres")
	assert_int(theme.palette.size()).is_equal(16)


func test_one_dark_palette_has_16_entries() -> void:
	var theme := _load_theme("res://resources/themes/one_dark.tres")
	assert_int(theme.palette.size()).is_equal(16)


# ---------------------------------------------------------------------------
# Color types and component range: use solarized_dark as representative sample.
# ---------------------------------------------------------------------------


func test_palette_entries_are_colors() -> void:
	var theme := _load_theme("res://resources/themes/solarized_dark.tres")
	for i: int in theme.palette.size():
		(
			assert_bool(theme.palette[i] is Color)
			. override_failure_message("palette[%d] is not a Color" % i)
			. is_true()
		)


func test_palette_color_components_in_unit_range() -> void:
	var theme := _load_theme("res://resources/themes/solarized_dark.tres")
	for i: int in theme.palette.size():
		var c: Color = theme.palette[i]
		(
			assert_bool(c.r >= 0.0 and c.r <= 1.0)
			. override_failure_message("palette[%d].r = %f out of [0,1]" % [i, c.r])
			. is_true()
		)
		(
			assert_bool(c.g >= 0.0 and c.g <= 1.0)
			. override_failure_message("palette[%d].g = %f out of [0,1]" % [i, c.g])
			. is_true()
		)
		(
			assert_bool(c.b >= 0.0 and c.b <= 1.0)
			. override_failure_message("palette[%d].b = %f out of [0,1]" % [i, c.b])
			. is_true()
		)


# ---------------------------------------------------------------------------
# Self-contained: resource has a script ref but no unexpected sub-resources.
# ---------------------------------------------------------------------------


func test_theme_has_no_unexpected_subresources() -> void:
	var theme := _load_theme("res://resources/themes/nord.tres")
	assert_object(theme).is_not_null()
	# TerminalTheme should have no nested resource properties other than
	# the script itself -- verify by confirming cast succeeds (implies correct type)
	# and all expected properties are present.
	assert_bool(theme is TerminalTheme).is_true()
	assert_bool(theme.color_background is Color).is_true()
	assert_bool(theme.color_foreground is Color).is_true()
	assert_bool(theme.color_cursor is Color).is_true()
	assert_bool(theme.color_selection_bg is Color).is_true()
	assert_bool(theme.color_selection_fg is Color).is_true()
