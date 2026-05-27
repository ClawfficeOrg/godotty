# GdUnit4 test: TerminalView CSI cursor-positioning sequences.
#
# Spec: docs/todo-v1.md  (task 1.0.3)
#
# Covers: CSI H (cursor home/position), CSI f (cursor position),
#         CSI A/B/C/D (cursor up/down/right/left), character written at
#         cursor position in the alternate screen, out-of-bounds clamping,
#         and partial-escape buffering for cursor sequences.
#
# All tests run in mock mode — no GDExtension required.
# Characters are verified via _view._alt_grid (the backing TerminalGrid).
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)
	# Enter alternate screen so _alt_grid is initialised.
	SignalBus.output_ready.emit("\u001b[?1049h")


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


func _alt_grid() -> TerminalGrid:
	return _view._alt_grid


# ---------------------------------------------------------------------------
# CSI H — cursor home / position
# ---------------------------------------------------------------------------


func test_csi_h_no_params_homes_cursor_to_origin() -> void:
	_alt_grid().set_cursor(5, 10)
	SignalBus.output_ready.emit("\u001b[H")
	assert_int(_alt_grid().cursor_row).is_equal(0)
	assert_int(_alt_grid().cursor_col).is_equal(0)


func test_csi_h_with_params_positions_cursor_row_col() -> void:
	SignalBus.output_ready.emit("\u001b[3;5H")
	# CSI params are 1-based; grid is 0-based → row=2, col=4
	assert_int(_alt_grid().cursor_row).is_equal(2)
	assert_int(_alt_grid().cursor_col).is_equal(4)


func test_csi_h_with_row_only_defaults_col_to_one() -> void:
	SignalBus.output_ready.emit("\u001b[4H")
	assert_int(_alt_grid().cursor_row).is_equal(3)
	assert_int(_alt_grid().cursor_col).is_equal(0)


# ---------------------------------------------------------------------------
# CSI f — cursor position (same as H)
# ---------------------------------------------------------------------------


func test_csi_f_positions_cursor_row_col() -> void:
	SignalBus.output_ready.emit("\u001b[3;5f")
	assert_int(_alt_grid().cursor_row).is_equal(2)
	assert_int(_alt_grid().cursor_col).is_equal(4)


# ---------------------------------------------------------------------------
# CSI A — cursor up
# ---------------------------------------------------------------------------


func test_csi_a_moves_cursor_up_by_n() -> void:
	SignalBus.output_ready.emit("\u001b[5;5H")
	SignalBus.output_ready.emit("\u001b[2A")
	assert_int(_alt_grid().cursor_row).is_equal(2)


func test_csi_a_no_param_moves_up_by_one() -> void:
	SignalBus.output_ready.emit("\u001b[5;1H")
	SignalBus.output_ready.emit("\u001b[A")
	assert_int(_alt_grid().cursor_row).is_equal(3)


func test_csi_a_clamps_at_top() -> void:
	SignalBus.output_ready.emit("\u001b[1;1H")
	SignalBus.output_ready.emit("\u001b[10A")
	assert_int(_alt_grid().cursor_row).is_equal(0)


# ---------------------------------------------------------------------------
# CSI B — cursor down
# ---------------------------------------------------------------------------


func test_csi_b_moves_cursor_down_by_n() -> void:
	SignalBus.output_ready.emit("\u001b[2;1H")
	SignalBus.output_ready.emit("\u001b[3B")
	assert_int(_alt_grid().cursor_row).is_equal(4)


func test_csi_b_no_param_moves_down_by_one() -> void:
	SignalBus.output_ready.emit("\u001b[2;1H")
	SignalBus.output_ready.emit("\u001b[B")
	assert_int(_alt_grid().cursor_row).is_equal(2)


# ---------------------------------------------------------------------------
# CSI C — cursor right
# ---------------------------------------------------------------------------


func test_csi_c_moves_cursor_right_by_n() -> void:
	SignalBus.output_ready.emit("\u001b[1;1H")
	SignalBus.output_ready.emit("\u001b[4C")
	assert_int(_alt_grid().cursor_col).is_equal(4)


func test_csi_c_no_param_moves_right_by_one() -> void:
	SignalBus.output_ready.emit("\u001b[1;1H")
	SignalBus.output_ready.emit("\u001b[C")
	assert_int(_alt_grid().cursor_col).is_equal(1)


# ---------------------------------------------------------------------------
# CSI D — cursor left
# ---------------------------------------------------------------------------


func test_csi_d_moves_cursor_left_by_n() -> void:
	SignalBus.output_ready.emit("\u001b[1;6H")
	SignalBus.output_ready.emit("\u001b[3D")
	assert_int(_alt_grid().cursor_col).is_equal(2)


func test_csi_d_no_param_moves_left_by_one() -> void:
	SignalBus.output_ready.emit("\u001b[1;4H")
	SignalBus.output_ready.emit("\u001b[D")
	assert_int(_alt_grid().cursor_col).is_equal(2)


func test_csi_d_clamps_at_left_edge() -> void:
	SignalBus.output_ready.emit("\u001b[1;1H")
	SignalBus.output_ready.emit("\u001b[10D")
	assert_int(_alt_grid().cursor_col).is_equal(0)


# ---------------------------------------------------------------------------
# Character written at cursor position (core task requirement)
# ---------------------------------------------------------------------------


func test_char_lands_at_cursor_position_after_csi_h() -> void:
	SignalBus.output_ready.emit("\u001b[3;5H")
	SignalBus.output_ready.emit("X")
	# CSI 3;5H → 0-based (2, 4)
	assert_str(_alt_grid().get_cell(2, 4)["char"]).is_equal("X")


func test_char_advances_cursor_after_write() -> void:
	SignalBus.output_ready.emit("\u001b[3;5H")
	SignalBus.output_ready.emit("A")
	assert_int(_alt_grid().cursor_col).is_equal(5)


func test_sequential_chars_fill_consecutive_cells() -> void:
	SignalBus.output_ready.emit("\u001b[2;3H")
	SignalBus.output_ready.emit("Hi")
	# CSI 2;3H → (1, 2); then 'H' at (1,2), 'i' at (1,3)
	assert_str(_alt_grid().get_cell(1, 2)["char"]).is_equal("H")
	assert_str(_alt_grid().get_cell(1, 3)["char"]).is_equal("i")


func test_move_cursor_then_write_lands_correctly() -> void:
	# Position at (5;5) then move up 2 → (3;5), then write 'Q'
	SignalBus.output_ready.emit("\u001b[5;5H")
	SignalBus.output_ready.emit("\u001b[2A")
	SignalBus.output_ready.emit("Q")
	# (5;5H) → row=4,col=4; move up 2 → row=2,col=4
	assert_str(_alt_grid().get_cell(2, 4)["char"]).is_equal("Q")


# ---------------------------------------------------------------------------
# Partial escape split across two emissions
# ---------------------------------------------------------------------------


func test_partial_csi_h_split_across_chunks_positions_cursor() -> void:
	SignalBus.output_ready.emit("\u001b[3;")
	SignalBus.output_ready.emit("5H")
	assert_int(_alt_grid().cursor_row).is_equal(2)
	assert_int(_alt_grid().cursor_col).is_equal(4)


# ---------------------------------------------------------------------------
# Out-of-bounds cursor coordinates are clamped (no crash)
# ---------------------------------------------------------------------------


func test_csi_h_out_of_bounds_row_clamps() -> void:
	SignalBus.output_ready.emit("\u001b[9999;1H")
	assert_int(_alt_grid().cursor_row).is_equal(_view._terminal_rows - 1)


func test_csi_h_out_of_bounds_col_clamps() -> void:
	SignalBus.output_ready.emit("\u001b[1;9999H")
	assert_int(_alt_grid().cursor_col).is_equal(_view._terminal_cols - 1)


# ---------------------------------------------------------------------------
# Alt grid is null outside alternate screen (no crash writing chars)
# ---------------------------------------------------------------------------


func test_chars_outside_alt_screen_do_not_crash() -> void:
	# Exit alternate screen first.
	SignalBus.output_ready.emit("\u001b[?1049l")
	assert_bool(_view._alt_grid == null).is_true()
	# Writing a character outside alt screen must not crash.
	SignalBus.output_ready.emit("Z")
	assert_bool(true).is_true()
