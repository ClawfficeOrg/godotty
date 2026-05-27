## Tests for the theme picker UI in TerminalView (task 2.0.4).
## Verifies the menu lists all bundled themes, Dracula applies a dark
## background, the selection persists in TerminalSettings, and that a
## freshly instantiated view restores the persisted theme on startup.
##
## All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _saved_theme: TerminalTheme
var _saved_theme_name: String


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_saved_theme = TerminalManager._current_theme
	_saved_theme_name = TerminalSettings.selected_theme_name
	TerminalSettings.selected_theme_name = ""
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null
	TerminalManager._current_theme = _saved_theme
	TerminalSettings.selected_theme_name = _saved_theme_name


# ---------------------------------------------------------------------------
# Menu population
# ---------------------------------------------------------------------------


func test_theme_picker_lists_eight_or_more_items() -> void:
	var popup := _view._theme_menu.get_popup()
	assert_bool(popup.get_item_count() >= 8).is_true()


func test_theme_picker_includes_dracula() -> void:
	var popup := _view._theme_menu.get_popup()
	var found: bool = false
	for i: int in range(popup.get_item_count()):
		if popup.get_item_text(i) == "Dracula":
			found = true
			break
	assert_bool(found).is_true()


# ---------------------------------------------------------------------------
# Theme application
# ---------------------------------------------------------------------------


func test_selecting_dracula_applies_dark_background() -> void:
	var popup := _view._theme_menu.get_popup()
	var idx: int = -1
	for i: int in range(popup.get_item_count()):
		if popup.get_item_text(i) == "Dracula":
			idx = i
			break
	popup.index_pressed.emit(idx)
	assert_bool(TerminalManager.current_theme.color_background.r < 0.5).is_true()


func test_selecting_theme_persists_in_settings() -> void:
	var popup := _view._theme_menu.get_popup()
	var idx: int = -1
	for i: int in range(popup.get_item_count()):
		if popup.get_item_text(i) == "Dracula":
			idx = i
			break
	popup.index_pressed.emit(idx)
	assert_str(TerminalSettings.selected_theme_name).is_equal("Dracula")


# ---------------------------------------------------------------------------
# Persistence across scene reload
# ---------------------------------------------------------------------------


func test_persisted_theme_applied_on_new_view() -> void:
	TerminalSettings.selected_theme_name = "Dracula"
	var view2 := TERMINAL_SCENE.instantiate() as TerminalView
	add_child(view2)
	assert_bool(TerminalManager.current_theme.color_background.r < 0.5).is_true()
	view2.queue_free()
