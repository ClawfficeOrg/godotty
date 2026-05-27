# GdUnit4 test: TerminalTheme Resource.
#
# Spec: docs/todo-v2.md  (task 2.0.1)
#
# Tests: default palette size and types, palette validation rejection,
#        resource round-trip via ResourceSaver/ResourceLoader,
#        loading from the shipped default_theme.tres asset.
extends GdUnitTestSuite

const TEMP_PATH := "user://terminal_theme_test_roundtrip.tres"


func after_test() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists("terminal_theme_test_roundtrip.tres"):
		dir.remove("terminal_theme_test_roundtrip.tres")


# ---------------------------------------------------------------------------
# Default palette
# ---------------------------------------------------------------------------


func test_default_palette_has_16_entries() -> void:
	var theme := TerminalTheme.new()
	assert_int(theme.palette.size()).is_equal(16)


func test_default_palette_first_entry_is_color() -> void:
	var theme := TerminalTheme.new()
	assert_bool(theme.palette[0] is Color).is_true()


func test_default_palette_last_entry_is_color() -> void:
	var theme := TerminalTheme.new()
	assert_bool(theme.palette[15] is Color).is_true()


func test_default_background_color_is_set() -> void:
	var theme := TerminalTheme.new()
	assert_bool(theme.color_background is Color).is_true()


func test_default_foreground_color_is_set() -> void:
	var theme := TerminalTheme.new()
	assert_bool(theme.color_foreground is Color).is_true()


func test_default_cursor_color_is_set() -> void:
	var theme := TerminalTheme.new()
	assert_bool(theme.color_cursor is Color).is_true()


# ---------------------------------------------------------------------------
# Palette validation
# ---------------------------------------------------------------------------


func test_palette_validation_rejects_wrong_size() -> void:
	var theme := TerminalTheme.new()
	var bad: Array[Color] = [Color.RED]
	theme.palette = bad
	# Setter must reject wrong-size array; palette stays at 16 entries.
	assert_int(theme.palette.size()).is_equal(16)


func test_palette_validation_rejects_empty_array() -> void:
	var theme := TerminalTheme.new()
	var empty: Array[Color] = []
	theme.palette = empty
	assert_int(theme.palette.size()).is_equal(16)


func test_palette_validation_accepts_16_entries() -> void:
	var theme := TerminalTheme.new()
	var fresh: Array[Color] = []
	fresh.resize(16)
	for i: int in 16:
		fresh[i] = Color.WHITE
	theme.palette = fresh
	assert_int(theme.palette.size()).is_equal(16)
	assert_bool(theme.palette[0] == Color.WHITE).is_true()


# ---------------------------------------------------------------------------
# Resource round-trip
# ---------------------------------------------------------------------------


func test_resource_round_trips_to_tres() -> void:
	var original := TerminalTheme.new()
	original.color_background = Color(0.1, 0.2, 0.3, 1.0)
	original.color_foreground = Color(0.4, 0.5, 0.6, 1.0)
	original.color_cursor = Color(0.7, 0.8, 0.9, 1.0)
	var save_err: int = ResourceSaver.save(original, TEMP_PATH)
	assert_int(save_err).is_equal(OK)
	var loaded := (
		ResourceLoader.load(TEMP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as TerminalTheme
	)
	assert_object(loaded).is_not_null()
	assert_bool(loaded.color_background == original.color_background).is_true()
	assert_bool(loaded.color_foreground == original.color_foreground).is_true()
	assert_bool(loaded.color_cursor == original.color_cursor).is_true()
	assert_int(loaded.palette.size()).is_equal(16)


func test_round_trip_preserves_palette_contents() -> void:
	var original := TerminalTheme.new()
	var custom: Array[Color] = []
	custom.resize(16)
	for i: int in 16:
		custom[i] = Color(float(i) / 15.0, 0.0, 0.0, 1.0)
	original.palette = custom
	var save_err: int = ResourceSaver.save(original, TEMP_PATH)
	assert_int(save_err).is_equal(OK)
	var loaded := (
		ResourceLoader.load(TEMP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as TerminalTheme
	)
	assert_object(loaded).is_not_null()
	assert_int(loaded.palette.size()).is_equal(16)
	assert_bool(loaded.palette[0] == custom[0]).is_true()
	assert_bool(loaded.palette[15] == custom[15]).is_true()


# ---------------------------------------------------------------------------
# Shipped default_theme.tres asset
# ---------------------------------------------------------------------------


func test_load_default_theme_tres() -> void:
	var theme := (
		ResourceLoader.load(
			"res://resources/themes/default_theme.tres", "", ResourceLoader.CACHE_MODE_IGNORE
		)
		as TerminalTheme
	)
	assert_object(theme).is_not_null()
	assert_int(theme.palette.size()).is_equal(16)
