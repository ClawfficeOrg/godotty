## GdUnit4 tests: Ctrl+Shift+F shows the SearchBar overlay (task 2.2.1).
##
## Spec: docs/todo-v2.md (task 2.2.1)
##
## Covers:
##   - SearchBar is hidden by default after terminal instantiation.
##   - show_search_bar() makes the SearchBar visible.
##   - Ctrl+Shift+F keyboard shortcut calls show_search_bar() (via _input).
##
## All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


## SearchBar is hidden by default when the terminal scene is instantiated.
func test_search_bar_hidden_by_default() -> void:
	assert_bool(_view.search_bar.visible).is_false()


## show_search_bar() makes the SearchBar visible.
func test_show_search_bar_makes_it_visible() -> void:
	assert_bool(_view.search_bar.visible).is_false()
	_view.show_search_bar()
	assert_bool(_view.search_bar.visible).is_true()


## Ctrl+Shift+F keyboard event triggers show_search_bar() via _input().
func test_ctrl_shift_f_shows_search_bar() -> void:
	assert_bool(_view.search_bar.visible).is_false()
	var ev := InputEventKey.new()
	ev.keycode = KEY_F
	ev.ctrl_pressed = true
	ev.shift_pressed = true
	ev.pressed = true
	_view._input(ev)
	assert_bool(_view.search_bar.visible).is_true()


## Calling show_search_bar() twice leaves the overlay visible (idempotent).
func test_show_search_bar_is_idempotent() -> void:
	_view.show_search_bar()
	_view.show_search_bar()
	assert_bool(_view.search_bar.visible).is_true()
