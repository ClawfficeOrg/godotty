# GdUnit4 test: TerminalView CSI J (erase display) and CSI K (erase line)
# sequences routed to the alternate screen grid.
#
# Spec: docs/todo-v1.md  (task 1.0.4)
#
# Covers: CSI 2J clears entire alt grid; CSI J (mode 0), CSI 1J (mode 1);
#         CSI K / CSI 1K / CSI 2K erase partial or full lines.
#
# All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)
	# Enter alternate screen so _alt_grid is active.
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


func _fill_alt_grid(ch: String) -> void:
	var g := _alt_grid()
	for r in range(g._rows):
		for c in range(g._cols):
			(
				g
				. set_cell(
					r,
					c,
					{
						"char": ch,
						"fg": Color.WHITE,
						"bg": Color.RED,
						"bold": false,
						"italic": false,
						"underline": false,
						"url": "",
					}
				)
			)


func _is_blank(cell: Dictionary) -> bool:
	return cell["char"] == " " and cell["bg"] == Color.BLACK


# ---------------------------------------------------------------------------
# CSI 2J -- erase entire display
# ---------------------------------------------------------------------------


func test_csi_2j_clears_all_cells_in_alt_screen() -> void:
	_fill_alt_grid("X")
	SignalBus.output_ready.emit("\u001b[2J")
	var g := _alt_grid()
	for r in range(g._rows):
		for c in range(g._cols):
			assert_bool(_is_blank(g.get_cell(r, c))).is_true()


func test_csi_2j_leaves_alt_grid_active() -> void:
	SignalBus.output_ready.emit("\u001b[2J")
	assert_bool(_view._in_alternate_screen).is_true()
	assert_bool(_alt_grid() != null).is_true()


func test_csi_2j_does_not_move_cursor() -> void:
	# Move cursor to a known position then erase; cursor should stay.
	SignalBus.output_ready.emit("\u001b[3;5H")
	SignalBus.output_ready.emit("\u001b[2J")
	assert_int(_alt_grid().cursor_row).is_equal(2)
	assert_int(_alt_grid().cursor_col).is_equal(4)


# ---------------------------------------------------------------------------
# CSI J (no param / mode 0) -- cursor to end of display
# ---------------------------------------------------------------------------


func test_csi_j_mode0_clears_from_cursor_to_end() -> void:
	_fill_alt_grid("X")
	# Position cursor at row 1, col 2 (1-based: row 2, col 3)
	SignalBus.output_ready.emit("\u001b[2;3H")
	SignalBus.output_ready.emit("\u001b[J")
	var g := _alt_grid()
	# Row 0 should be intact
	assert_bool(_is_blank(g.get_cell(0, 0))).is_false()
	# Cell at cursor and beyond should be blank
	assert_bool(_is_blank(g.get_cell(1, 2))).is_true()
	assert_bool(_is_blank(g.get_cell(g._rows - 1, g._cols - 1))).is_true()


# ---------------------------------------------------------------------------
# CSI K (no param / mode 0) -- cursor to end of line
# ---------------------------------------------------------------------------


func test_csi_k_default_clears_cursor_to_end_of_line() -> void:
	_fill_alt_grid("X")
	SignalBus.output_ready.emit("\u001b[2;3H")
	SignalBus.output_ready.emit("\u001b[K")
	var g := _alt_grid()
	# Cols before cursor intact
	assert_bool(_is_blank(g.get_cell(1, 1))).is_false()
	# Cols at and after cursor blank
	assert_bool(_is_blank(g.get_cell(1, 2))).is_true()
	assert_bool(_is_blank(g.get_cell(1, g._cols - 1))).is_true()
	# Other rows intact
	assert_bool(_is_blank(g.get_cell(0, 0))).is_false()
	assert_bool(_is_blank(g.get_cell(2, 0))).is_false()


# ---------------------------------------------------------------------------
# CSI 1K -- beginning of line to cursor
# ---------------------------------------------------------------------------


func test_csi_1k_clears_start_to_cursor() -> void:
	_fill_alt_grid("X")
	SignalBus.output_ready.emit("\u001b[2;3H")
	SignalBus.output_ready.emit("\u001b[1K")
	var g := _alt_grid()
	# Cols 0 through cursor col (2) blank
	assert_bool(_is_blank(g.get_cell(1, 0))).is_true()
	assert_bool(_is_blank(g.get_cell(1, 2))).is_true()
	# Cols after cursor intact
	assert_bool(_is_blank(g.get_cell(1, 3))).is_false()
	# Other rows intact
	assert_bool(_is_blank(g.get_cell(0, 0))).is_false()
	assert_bool(_is_blank(g.get_cell(2, 0))).is_false()


# ---------------------------------------------------------------------------
# CSI 2K -- entire line
# ---------------------------------------------------------------------------


func test_csi_2k_clears_entire_line() -> void:
	_fill_alt_grid("X")
	SignalBus.output_ready.emit("\u001b[2;3H")
	SignalBus.output_ready.emit("\u001b[2K")
	var g := _alt_grid()
	# Entire row 1 blank
	for c in range(g._cols):
		assert_bool(_is_blank(g.get_cell(1, c))).is_true()
	# Other rows intact
	assert_bool(_is_blank(g.get_cell(0, 0))).is_false()
	assert_bool(_is_blank(g.get_cell(2, 0))).is_false()
