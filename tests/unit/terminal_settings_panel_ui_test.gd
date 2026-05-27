# GdUnit4 test: font settings panel UI wiring in TerminalView (task 2.1.4).
#
# Spec: docs/todo-v2.md (task 2.1.4)
#
# Covers:
#   - SpinBox change updates TerminalSettings.font_size.
#   - SpinBox increase causes OutputDisplay font_size theme override to update.
#   - OptionButton lists at least the bundled fonts.
#   - OptionButton first item is "Default".
#   - Selecting Default sets TerminalSettings.font to null.
#   - Selecting a named font loads the resource into TerminalSettings.font.
#
# All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _saved_font_size: int
var _saved_font: Font
var _saved_font_name: String


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_saved_font_size = TerminalSettings.font_size
	_saved_font = TerminalSettings.font
	_saved_font_name = TerminalSettings.selected_font_name
	TerminalSettings.selected_font_name = "Default"
	TerminalSettings.font = null
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	TerminalSettings.font_size = _saved_font_size
	TerminalSettings.font = _saved_font
	TerminalSettings.selected_font_name = _saved_font_name
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# SpinBox -> TerminalSettings wiring
# ---------------------------------------------------------------------------


func test_spinbox_emit_updates_terminal_settings_font_size() -> void:
	_view._font_spinbox.value_changed.emit(24.0)
	assert_int(TerminalSettings.font_size).is_equal(24)


func test_spinbox_increase_updates_output_display_font_size() -> void:
	_view._font_spinbox.value_changed.emit(20.0)
	assert_int(_view.output_display.get_theme_font_size("normal_font_size")).is_equal(20)


func test_spinbox_decrease_updates_output_display_font_size() -> void:
	_view._font_spinbox.value_changed.emit(10.0)
	assert_int(_view.output_display.get_theme_font_size("normal_font_size")).is_equal(10)


# ---------------------------------------------------------------------------
# OptionButton population
# ---------------------------------------------------------------------------


func test_font_option_lists_at_least_two_items() -> void:
	assert_bool(_view._font_option.item_count >= 2).is_true()


func test_font_option_first_item_is_default() -> void:
	assert_str(_view._font_option.get_item_text(0)).is_equal("Default")


func test_font_option_includes_jetbrains_mono_nerd() -> void:
	var found: bool = false
	for i: int in range(_view._font_option.item_count):
		if _view._font_option.get_item_text(i) == "JetBrains Mono Nerd":
			found = true
			break
	assert_bool(found).is_true()


# ---------------------------------------------------------------------------
# OptionButton -> TerminalSettings wiring
# ---------------------------------------------------------------------------


func test_selecting_default_sets_font_null() -> void:
	_view._font_option.item_selected.emit(0)
	assert_object(TerminalSettings.font).is_null()


func test_selecting_default_sets_selected_font_name() -> void:
	_view._font_option.item_selected.emit(0)
	assert_str(TerminalSettings.selected_font_name).is_equal("Default")


func test_selecting_nerd_font_loads_resource() -> void:
	var idx: int = -1
	for i: int in range(_view._font_option.item_count):
		if _view._font_option.get_item_text(i) == "JetBrains Mono Nerd":
			idx = i
			break
	if idx < 0:
		return
	_view._font_option.item_selected.emit(idx)
	assert_object(TerminalSettings.font).is_not_null()


func test_selecting_nerd_font_persists_selected_font_name() -> void:
	var idx: int = -1
	for i: int in range(_view._font_option.item_count):
		if _view._font_option.get_item_text(i) == "JetBrains Mono Nerd":
			idx = i
			break
	if idx < 0:
		return
	_view._font_option.item_selected.emit(idx)
	assert_str(TerminalSettings.selected_font_name).is_equal("JetBrains Mono Nerd")
