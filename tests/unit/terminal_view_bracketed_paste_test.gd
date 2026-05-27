# GdUnit4 test: TerminalView bracketed paste mode state (task 1.3.1).
#
# Spec: docs/todo-v1.md (task 1.3.1)
#
# Covers: CSI ?2004h (enable) and CSI ?2004l (disable) set/clear
# _bracketed_paste_mode on TerminalView.
#
# All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# Default state
# ---------------------------------------------------------------------------


func test_bracketed_paste_mode_is_false_by_default() -> void:
	assert_bool(_view._bracketed_paste_mode).is_false()


# ---------------------------------------------------------------------------
# CSI ?2004h — enable bracketed paste
# ---------------------------------------------------------------------------


func test_csi_2004h_enables_bracketed_paste_mode() -> void:
	SignalBus.output_ready.emit("\u001b[?2004h")
	assert_bool(_view._bracketed_paste_mode).is_true()


# ---------------------------------------------------------------------------
# CSI ?2004l — disable bracketed paste
# ---------------------------------------------------------------------------


func test_csi_2004l_disables_bracketed_paste_mode() -> void:
	# Pre-enable so we can verify the disable transition.
	SignalBus.output_ready.emit("\u001b[?2004h")
	SignalBus.output_ready.emit("\u001b[?2004l")
	assert_bool(_view._bracketed_paste_mode).is_false()


# ---------------------------------------------------------------------------
# Toggle: enable then disable
# ---------------------------------------------------------------------------


func test_bracketed_paste_mode_toggles_with_sequence_pair() -> void:
	SignalBus.output_ready.emit("\u001b[?2004h")
	assert_bool(_view._bracketed_paste_mode).is_true()
	SignalBus.output_ready.emit("\u001b[?2004l")
	assert_bool(_view._bracketed_paste_mode).is_false()
