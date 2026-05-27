# GdUnit4 test: TerminalView DECSCUSR cursor-style sequences (task 1.1.2).
#
# Spec: docs/todo-v1.md (task 1.1.2)
#
# Covers: CSI Ps SP q sequences that set cursor overlay style.
# Ps=0 (default blinking block), Ps=1 (blinking block), Ps=2 (steady block),
# Ps=3 (blinking underline), Ps=4 (steady underline),
# Ps=5 (blinking bar), Ps=6 (steady bar).
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


func test_cursor_style_is_blinking_block_by_default() -> void:
	assert_int(_view.cursor_style).is_equal(TerminalView.CursorStyle.BLINKING_BLOCK)


# ---------------------------------------------------------------------------
# DECSCUSR — CSI Ps SP q
# ---------------------------------------------------------------------------


func test_csi_q_blinking_block() -> void:
	# CSI 0 SP q  → default blinking block
	SignalBus.output_ready.emit("\u001b[0 q")
	assert_int(_view.cursor_style).is_equal(TerminalView.CursorStyle.BLINKING_BLOCK)


func test_csi_q_blinking_block_ps1() -> void:
	# CSI 1 SP q  → blinking block (alias)
	SignalBus.output_ready.emit("\u001b[1 q")
	assert_int(_view.cursor_style).is_equal(TerminalView.CursorStyle.BLINKING_BLOCK)


func test_csi_q_steady_block_ps2() -> void:
	# CSI 2 SP q  → steady block
	SignalBus.output_ready.emit("\u001b[2 q")
	assert_int(_view.cursor_style).is_equal(TerminalView.CursorStyle.STEADY_BLOCK)


func test_csi_q_blinking_underline_ps3() -> void:
	# CSI 3 SP q  → blinking underline
	SignalBus.output_ready.emit("\u001b[3 q")
	assert_int(_view.cursor_style).is_equal(TerminalView.CursorStyle.BLINKING_UNDERLINE)


func test_csi_q_steady_underline_ps4() -> void:
	# CSI 4 SP q  → steady underline
	SignalBus.output_ready.emit("\u001b[4 q")
	assert_int(_view.cursor_style).is_equal(TerminalView.CursorStyle.STEADY_UNDERLINE)


func test_csi_q_blinking_bar_ps5() -> void:
	# CSI 5 SP q  → blinking bar
	SignalBus.output_ready.emit("\u001b[5 q")
	assert_int(_view.cursor_style).is_equal(TerminalView.CursorStyle.BLINKING_BAR)


func test_csi_q_steady_bar_ps6() -> void:
	# CSI 6 SP q  → steady bar
	SignalBus.output_ready.emit("\u001b[6 q")
	assert_int(_view.cursor_style).is_equal(TerminalView.CursorStyle.STEADY_BAR)


# ---------------------------------------------------------------------------
# Overlay size reflects cursor style
# ---------------------------------------------------------------------------


func test_block_style_gives_full_char_size() -> void:
	SignalBus.output_ready.emit("\u001b[2 q")
	assert_float(_view.cursor_overlay.size.x).is_equal(TerminalView.CHAR_W)
	assert_float(_view.cursor_overlay.size.y).is_equal(TerminalView.CHAR_H)


func test_underline_style_gives_thin_horizontal_bar() -> void:
	SignalBus.output_ready.emit("\u001b[4 q")
	assert_float(_view.cursor_overlay.size.x).is_equal(TerminalView.CHAR_W)
	assert_float(_view.cursor_overlay.size.y).is_equal(2.0)


func test_bar_style_gives_thin_vertical_bar() -> void:
	SignalBus.output_ready.emit("\u001b[5 q")
	assert_float(_view.cursor_overlay.size.x).is_equal(2.0)
	assert_float(_view.cursor_overlay.size.y).is_equal(TerminalView.CHAR_H)
