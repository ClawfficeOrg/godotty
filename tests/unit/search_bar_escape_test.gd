## GdUnit4 tests: Escape hides the SearchBar overlay (task 2.2.1).
##
## Spec: docs/todo-v2.md (task 2.2.1)
##
## Covers:
##   - hide_search() hides the SearchBar.
##   - hide_search() clears the query field.
##   - hide_search() resets _search_highlight_count to 0 on TerminalView.
##   - SearchBar _input() handles Escape to call hide_search().
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


## hide_search() hides the SearchBar.
func test_hide_search_hides_overlay() -> void:
	_view.show_search_bar()
	assert_bool(_view.search_bar.visible).is_true()
	_view.search_bar.hide_search()
	assert_bool(_view.search_bar.visible).is_false()


## hide_search() clears the query field text.
func test_hide_search_clears_query() -> void:
	_view.show_search_bar()
	_view.search_bar.query_edit.text = "hello"
	_view.search_bar.hide_search()
	assert_str(_view.search_bar.query_edit.text).is_equal("")


## hide_search() resets _search_highlight_count to 0 on TerminalView.
func test_hide_search_clears_highlight_count() -> void:
	_view.show_search_bar()
	_view._search_highlight_count = 5
	_view.search_bar.hide_search()
	assert_int(_view._search_highlight_count).is_equal(0)


## Escape key on SearchBar calls hide_search() (hides the overlay).
func test_escape_key_hides_search_bar() -> void:
	_view.show_search_bar()
	assert_bool(_view.search_bar.visible).is_true()
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	_view.search_bar._input(ev)
	assert_bool(_view.search_bar.visible).is_false()


## Escape on a hidden SearchBar does nothing (no error).
func test_escape_on_hidden_search_bar_is_safe() -> void:
	assert_bool(_view.search_bar.visible).is_false()
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	_view.search_bar._input(ev)
	assert_bool(_view.search_bar.visible).is_false()
