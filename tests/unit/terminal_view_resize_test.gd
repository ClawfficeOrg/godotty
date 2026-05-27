# GdUnit4 test: TerminalView resize -> cols/rows calculation (task 1.2.1).
#
# Spec: docs/todo-v1.md (task 1.2.1)
#
# Covers: _on_viewport_resize computes cols/rows from TerminalSettings.font_size
#         and emits SignalBus.terminal_resized(cols, rows).
#
# All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _saved_font_size: int


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_saved_font_size = TerminalSettings.font_size
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	TerminalSettings.font_size = _saved_font_size
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# Signal fires with correct cols/rows for a known size + font_size
# ---------------------------------------------------------------------------


func test_terminal_resized_signal_fires_with_correct_cols_rows() -> void:
	TerminalSettings.font_size = 10
	# char_width = 10 * 0.5 = 5.0, line_height = 10.0
	# 200 / 5.0 = 40 cols, 100 / 10.0 = 10 rows
	_view.size = Vector2(200, 100)
	var received: Array = []
	var cb := func(cols: int, rows: int) -> void: received.append([cols, rows])
	SignalBus.terminal_resized.connect(cb)
	_view._on_viewport_resize()
	SignalBus.terminal_resized.disconnect(cb)
	assert_array(received).is_not_empty()
	assert_int(received[0][0]).is_equal(40)
	assert_int(received[0][1]).is_equal(10)


# ---------------------------------------------------------------------------
# Different font_size yields different col/row counts for the same pixel size
# ---------------------------------------------------------------------------


func test_terminal_resized_larger_font_gives_fewer_cols() -> void:
	# font_size=20 -> char_w=10.0 -> 200/10=20 cols, 100/20=5 rows
	TerminalSettings.font_size = 20
	_view.size = Vector2(200, 100)
	var received: Array = []
	var cb := func(cols: int, rows: int) -> void: received.append([cols, rows])
	SignalBus.terminal_resized.connect(cb)
	_view._on_viewport_resize()
	SignalBus.terminal_resized.disconnect(cb)
	assert_array(received).is_not_empty()
	assert_int(received[0][0]).is_equal(20)
	assert_int(received[0][1]).is_equal(5)


# ---------------------------------------------------------------------------
# Signal NOT emitted when view size is zero (guard branch)
# ---------------------------------------------------------------------------


func test_terminal_resized_not_fired_when_size_is_zero() -> void:
	TerminalSettings.font_size = 10
	_view.size = Vector2(0, 0)
	var fired: Array[bool] = [false]
	var cb := func(_cols: int, _rows: int) -> void: fired[0] = true
	SignalBus.terminal_resized.connect(cb)
	_view._on_viewport_resize()
	SignalBus.terminal_resized.disconnect(cb)
	assert_bool(fired[0]).is_false()


# ---------------------------------------------------------------------------
# floor semantics: fractional pixels are truncated, not rounded
# ---------------------------------------------------------------------------


func test_terminal_resized_uses_floor_not_round() -> void:
	# font_size=10 -> char_w=5.0
	# width=209 -> floor(209/5)=41, not round(209/5)=42
	TerminalSettings.font_size = 10
	_view.size = Vector2(209, 109)
	var received: Array = []
	var cb := func(cols: int, rows: int) -> void: received.append([cols, rows])
	SignalBus.terminal_resized.connect(cb)
	_view._on_viewport_resize()
	SignalBus.terminal_resized.disconnect(cb)
	assert_array(received).is_not_empty()
	assert_int(received[0][0]).is_equal(41)
	assert_int(received[0][1]).is_equal(10)


# ---------------------------------------------------------------------------
# Default font_size (16) produces char_w=8 and line_h=16 matching constants
# ---------------------------------------------------------------------------


func test_terminal_resized_default_font_size_matches_char_constants() -> void:
	# Default font_size=16 -> char_w=8.0=CHAR_W, line_h=16.0=CHAR_H
	TerminalSettings.font_size = 16
	_view.size = Vector2(160, 96)
	# 160/8=20 cols, 96/16=6 rows
	var received: Array = []
	var cb := func(cols: int, rows: int) -> void: received.append([cols, rows])
	SignalBus.terminal_resized.connect(cb)
	_view._on_viewport_resize()
	SignalBus.terminal_resized.disconnect(cb)
	assert_array(received).is_not_empty()
	assert_int(received[0][0]).is_equal(20)
	assert_int(received[0][1]).is_equal(6)
