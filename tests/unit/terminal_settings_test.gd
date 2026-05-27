## Tests for the TerminalSettings Resource (project/resources/terminal_settings.gd).
##
## Spec: task 2.1.1
##
## Coverage:
##   - Default property values.
##   - Range clamping for font_size, line_height_scale, and cursor_blink_rate.
##   - .tres round-trip via ResourceSaver / ResourceLoader.
extends GdUnitTestSuite

const SettingsScript := preload("res://resources/terminal_settings.gd")
const TEMP_PATH := "user://terminal_settings_test_roundtrip.tres"


func after_test() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and dir.file_exists("terminal_settings_test_roundtrip.tres"):
		dir.remove("terminal_settings_test_roundtrip.tres")


# ---------------------------------------------------------------------------
# Default values
# ---------------------------------------------------------------------------


func test_default_font_is_null() -> void:
	var settings: Resource = SettingsScript.new()
	assert_object(settings.get("font")).is_null()


func test_default_font_size_is_14() -> void:
	var settings: Resource = SettingsScript.new()
	assert_int(int(settings.get("font_size"))).is_equal(14)


func test_default_line_height_scale_is_1_point_2() -> void:
	var settings: Resource = SettingsScript.new()
	assert_float(float(settings.get("line_height_scale"))).is_equal_approx(1.2, 0.001)


func test_default_theme_is_null() -> void:
	var settings: Resource = SettingsScript.new()
	assert_object(settings.get("theme")).is_null()


func test_default_cursor_blink_rate_is_positive() -> void:
	var settings: Resource = SettingsScript.new()
	assert_float(float(settings.get("cursor_blink_rate"))).is_greater(0.0)


# ---------------------------------------------------------------------------
# Range clamping -- font_size
# ---------------------------------------------------------------------------


func test_font_size_below_min_is_clamped() -> void:
	var settings: Resource = SettingsScript.new()
	settings.set("font_size", 1)
	assert_int(int(settings.get("font_size"))).is_equal(SettingsScript.FONT_SIZE_MIN)


func test_font_size_above_max_is_clamped() -> void:
	var settings: Resource = SettingsScript.new()
	settings.set("font_size", 999)
	assert_int(int(settings.get("font_size"))).is_equal(SettingsScript.FONT_SIZE_MAX)


func test_font_size_at_min_is_accepted() -> void:
	var settings: Resource = SettingsScript.new()
	settings.set("font_size", SettingsScript.FONT_SIZE_MIN)
	assert_int(int(settings.get("font_size"))).is_equal(SettingsScript.FONT_SIZE_MIN)


func test_font_size_at_max_is_accepted() -> void:
	var settings: Resource = SettingsScript.new()
	settings.set("font_size", SettingsScript.FONT_SIZE_MAX)
	assert_int(int(settings.get("font_size"))).is_equal(SettingsScript.FONT_SIZE_MAX)


# ---------------------------------------------------------------------------
# Range clamping -- line_height_scale
# ---------------------------------------------------------------------------


func test_line_height_scale_below_min_is_clamped() -> void:
	var settings: Resource = SettingsScript.new()
	settings.set("line_height_scale", 0.1)
	assert_float(float(settings.get("line_height_scale"))).is_equal_approx(
		SettingsScript.LINE_HEIGHT_SCALE_MIN, 0.001
	)


func test_line_height_scale_above_max_is_clamped() -> void:
	var settings: Resource = SettingsScript.new()
	settings.set("line_height_scale", 10.0)
	assert_float(float(settings.get("line_height_scale"))).is_equal_approx(
		SettingsScript.LINE_HEIGHT_SCALE_MAX, 0.001
	)


func test_line_height_scale_at_min_is_accepted() -> void:
	var settings: Resource = SettingsScript.new()
	settings.set("line_height_scale", SettingsScript.LINE_HEIGHT_SCALE_MIN)
	assert_float(float(settings.get("line_height_scale"))).is_equal_approx(
		SettingsScript.LINE_HEIGHT_SCALE_MIN, 0.001
	)


func test_line_height_scale_at_max_is_accepted() -> void:
	var settings: Resource = SettingsScript.new()
	settings.set("line_height_scale", SettingsScript.LINE_HEIGHT_SCALE_MAX)
	assert_float(float(settings.get("line_height_scale"))).is_equal_approx(
		SettingsScript.LINE_HEIGHT_SCALE_MAX, 0.001
	)


# ---------------------------------------------------------------------------
# Range clamping -- cursor_blink_rate
# ---------------------------------------------------------------------------


func test_cursor_blink_rate_below_min_is_clamped() -> void:
	var settings: Resource = SettingsScript.new()
	settings.set("cursor_blink_rate", -1.0)
	assert_float(float(settings.get("cursor_blink_rate"))).is_equal_approx(
		SettingsScript.CURSOR_BLINK_RATE_MIN, 0.001
	)


func test_cursor_blink_rate_above_max_is_clamped() -> void:
	var settings: Resource = SettingsScript.new()
	settings.set("cursor_blink_rate", 100.0)
	assert_float(float(settings.get("cursor_blink_rate"))).is_equal_approx(
		SettingsScript.CURSOR_BLINK_RATE_MAX, 0.001
	)


func test_cursor_blink_rate_zero_is_valid() -> void:
	var settings: Resource = SettingsScript.new()
	settings.set("cursor_blink_rate", 0.0)
	assert_float(float(settings.get("cursor_blink_rate"))).is_equal_approx(0.0, 0.001)


# ---------------------------------------------------------------------------
# .tres round-trip
# ---------------------------------------------------------------------------


func test_tres_roundtrip_preserves_font_size() -> void:
	var original: Resource = SettingsScript.new()
	original.set("font_size", 20)
	var err: int = ResourceSaver.save(original, TEMP_PATH)
	assert_int(err).is_equal(OK)
	var loaded: Resource = ResourceLoader.load(TEMP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_object(loaded).is_not_null()
	assert_int(int(loaded.get("font_size"))).is_equal(20)


func test_tres_roundtrip_preserves_line_height_scale() -> void:
	var original: Resource = SettingsScript.new()
	original.set("line_height_scale", 1.8)
	var err: int = ResourceSaver.save(original, TEMP_PATH)
	assert_int(err).is_equal(OK)
	var loaded: Resource = ResourceLoader.load(TEMP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_object(loaded).is_not_null()
	assert_float(float(loaded.get("line_height_scale"))).is_equal_approx(1.8, 0.001)


func test_tres_roundtrip_preserves_cursor_blink_rate() -> void:
	var original: Resource = SettingsScript.new()
	original.set("cursor_blink_rate", 1.0)
	var err: int = ResourceSaver.save(original, TEMP_PATH)
	assert_int(err).is_equal(OK)
	var loaded: Resource = ResourceLoader.load(TEMP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_object(loaded).is_not_null()
	assert_float(float(loaded.get("cursor_blink_rate"))).is_equal_approx(1.0, 0.001)
