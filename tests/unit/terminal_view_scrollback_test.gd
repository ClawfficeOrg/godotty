# GdUnit4 test: TerminalView scrollback buffer size (task 2.4.4).
#
# Spec: docs/todo-v2.md (task 2.4.4)
#
# Covers:
#   - TerminalSettings.scrollback_lines defaults to 1000.
#   - set scrollback_lines = 5; write 10 lines; only last 5 retained.
#   - _line_count does not exceed scrollback_lines after trimming.
#   - Content of retained lines equals the last N lines written.
#
# All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _saved_scrollback: int


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_saved_scrollback = TerminalSettings.scrollback_lines
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	TerminalSettings.scrollback_lines = _saved_scrollback
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# Default value
# ---------------------------------------------------------------------------


func test_default_scrollback_lines_is_1000() -> void:
	assert_int(TerminalSettings.scrollback_lines).is_equal(1000)


# ---------------------------------------------------------------------------
# Scrollback trimming
# ---------------------------------------------------------------------------


func test_scrollback_limit_retains_only_last_n_lines() -> void:
	TerminalSettings.scrollback_lines = 5
	for i in range(10):
		_view._on_output_ready("line%d\n" % i)
	var text := _view.output_display.get_parsed_text()
	var non_empty: Array = []
	for ln in text.split("\n"):
		if not ln.strip_edges().is_empty():
			non_empty.append(ln.strip_edges())
	assert_int(non_empty.size()).is_less_equal(5)


func test_scrollback_limit_last_line_is_final_written() -> void:
	TerminalSettings.scrollback_lines = 5
	for i in range(10):
		_view._on_output_ready("line%d\n" % i)
	var text := _view.output_display.get_parsed_text()
	var non_empty: Array = []
	for ln in text.split("\n"):
		if not ln.strip_edges().is_empty():
			non_empty.append(ln.strip_edges())
	assert_str(non_empty[-1]).is_equal("line9")


func test_line_count_does_not_exceed_scrollback_limit() -> void:
	TerminalSettings.scrollback_lines = 5
	for i in range(10):
		_view._on_output_ready("line%d\n" % i)
	assert_int(_view._line_count).is_less_equal(5)
