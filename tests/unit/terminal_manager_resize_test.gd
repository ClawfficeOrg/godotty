# GdUnit4 test: TerminalManager resize propagation via SignalBus.terminal_resized.
#
# Spec: .ralph/specs/0003-real-terminal-ci.md  (task 1.2.2)
#
# Covers: mock-mode state update, real-mode stub call, signal connection.
#
# All tests run in mock mode unless explicitly overridden.
# A minimal inner-class stub is injected for the real-mode test.
extends GdUnitTestSuite


# Minimal stub that records resize calls without requiring the GDExtension.
class ResizeStub:
	extends Node
	var last_cols: int = -1
	var last_rows: int = -1
	var call_count: int = 0

	func resize(cols: int, rows: int) -> void:
		last_cols = cols
		last_rows = rows
		call_count += 1


var _saved_mock_mode: bool = true
var _saved_addon_available: bool = false
var _saved_real_terminal: Node = null
var _saved_mock_cols: int = 80
var _saved_mock_rows: int = 24


func before_test() -> void:
	_saved_mock_mode = TerminalManager.is_mock_mode
	_saved_addon_available = TerminalManager.is_addon_available
	_saved_real_terminal = TerminalManager._real_terminal
	_saved_mock_cols = TerminalManager._mock_cols
	_saved_mock_rows = TerminalManager._mock_rows
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._real_terminal = null
	TerminalManager._mock_cols = 80
	TerminalManager._mock_rows = 24


func after_test() -> void:
	TerminalManager.is_mock_mode = _saved_mock_mode
	TerminalManager.is_addon_available = _saved_addon_available
	TerminalManager._real_terminal = _saved_real_terminal
	TerminalManager._mock_cols = _saved_mock_cols
	TerminalManager._mock_rows = _saved_mock_rows


# ---------------------------------------------------------------------------
# mock-mode state update
# ---------------------------------------------------------------------------


func test_terminal_manager_updates_mock_cols_on_resize_signal() -> void:
	SignalBus.terminal_resized.emit(132, 50)
	assert_int(TerminalManager._mock_cols).is_equal(132)


func test_terminal_manager_updates_mock_rows_on_resize_signal() -> void:
	SignalBus.terminal_resized.emit(132, 50)
	assert_int(TerminalManager._mock_rows).is_equal(50)


func test_get_dimensions_reflects_signal_resize_in_mock_mode() -> void:
	SignalBus.terminal_resized.emit(100, 30)
	var dims := TerminalManager.get_dimensions()
	assert_int(dims[0]).is_equal(100)
	assert_int(dims[1]).is_equal(30)


# ---------------------------------------------------------------------------
# real-mode stub call
# ---------------------------------------------------------------------------


func test_terminal_manager_calls_real_resize_on_signal() -> void:
	var stub := ResizeStub.new()
	TerminalManager.is_mock_mode = false
	TerminalManager._real_terminal = stub
	SignalBus.terminal_resized.emit(120, 40)
	TerminalManager.is_mock_mode = true
	TerminalManager._real_terminal = null
	stub.queue_free()
	assert_int(stub.call_count).is_equal(1)


func test_terminal_manager_passes_correct_cols_to_real_resize() -> void:
	var stub := ResizeStub.new()
	TerminalManager.is_mock_mode = false
	TerminalManager._real_terminal = stub
	SignalBus.terminal_resized.emit(120, 40)
	TerminalManager.is_mock_mode = true
	TerminalManager._real_terminal = null
	stub.queue_free()
	assert_int(stub.last_cols).is_equal(120)


func test_terminal_manager_passes_correct_rows_to_real_resize() -> void:
	var stub := ResizeStub.new()
	TerminalManager.is_mock_mode = false
	TerminalManager._real_terminal = stub
	SignalBus.terminal_resized.emit(120, 40)
	TerminalManager.is_mock_mode = true
	TerminalManager._real_terminal = null
	stub.queue_free()
	assert_int(stub.last_rows).is_equal(40)


func test_real_mode_no_crash_when_real_terminal_is_null() -> void:
	TerminalManager.is_mock_mode = false
	TerminalManager._real_terminal = null
	# Must not crash when _real_terminal is null in real mode.
	SignalBus.terminal_resized.emit(80, 24)
	TerminalManager.is_mock_mode = true
	assert_bool(true).is_true()


# ---------------------------------------------------------------------------
# signal connection
# ---------------------------------------------------------------------------


func test_terminal_resized_signal_is_connected_to_handler() -> void:
	var cb := TerminalManager._on_terminal_resized
	assert_bool(SignalBus.terminal_resized.is_connected(cb)).is_true()


func test_signal_disconnect_and_reconnect_roundtrip() -> void:
	var cb := TerminalManager._on_terminal_resized
	SignalBus.terminal_resized.disconnect(cb)
	assert_bool(SignalBus.terminal_resized.is_connected(cb)).is_false()
	SignalBus.terminal_resized.connect(cb)
	assert_bool(SignalBus.terminal_resized.is_connected(cb)).is_true()
