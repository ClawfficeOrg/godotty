# GdUnit4 test: TerminalGrid erase_display and erase_line (CSI J / CSI K).
#
# Spec: docs/todo-v1.md  (task 1.0.4)
#
# Covers: erase_display mode 0/1/2 and erase_line mode 0/1/2.
# TerminalGrid is a RefCounted -- no scene tree needed.
extends GdUnitTestSuite


func _make_grid(cols: int, rows: int) -> TerminalGrid:
	var g := TerminalGrid.new()
	g.resize(cols, rows)
	return g


func _fill_grid(g: TerminalGrid, ch: String) -> void:
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
# erase_display mode 2 -- entire display
# ---------------------------------------------------------------------------


func test_erase_display_mode2_clears_all_cells() -> void:
	var g := _make_grid(10, 5)
	_fill_grid(g, "X")
	g.erase_display(2)
	for r in range(5):
		for c in range(10):
			assert_bool(_is_blank(g.get_cell(r, c))).is_true()


func test_erase_display_mode2_does_not_move_cursor() -> void:
	var g := _make_grid(10, 5)
	g.set_cursor(2, 3)
	g.erase_display(2)
	assert_int(g.cursor_row).is_equal(2)
	assert_int(g.cursor_col).is_equal(3)


# ---------------------------------------------------------------------------
# erase_display mode 0 -- cursor to end of display
# ---------------------------------------------------------------------------


func test_erase_display_mode0_clears_from_cursor_to_end() -> void:
	var g := _make_grid(5, 3)
	_fill_grid(g, "X")
	g.set_cursor(1, 2)
	g.erase_display(0)
	# Row 0 fully intact
	for c in range(5):
		assert_bool(_is_blank(g.get_cell(0, c))).is_false()
	# Row 1: cols before cursor intact, cols at/after cursor blank
	assert_bool(_is_blank(g.get_cell(1, 1))).is_false()
	assert_bool(_is_blank(g.get_cell(1, 2))).is_true()
	assert_bool(_is_blank(g.get_cell(1, 4))).is_true()
	# Row 2 fully blank
	for c in range(5):
		assert_bool(_is_blank(g.get_cell(2, c))).is_true()


func test_erase_display_mode0_at_origin_clears_all() -> void:
	var g := _make_grid(5, 3)
	_fill_grid(g, "X")
	g.set_cursor(0, 0)
	g.erase_display(0)
	for r in range(3):
		for c in range(5):
			assert_bool(_is_blank(g.get_cell(r, c))).is_true()


# ---------------------------------------------------------------------------
# erase_display mode 1 -- beginning of display to cursor
# ---------------------------------------------------------------------------


func test_erase_display_mode1_clears_from_start_to_cursor() -> void:
	var g := _make_grid(5, 3)
	_fill_grid(g, "X")
	g.set_cursor(1, 2)
	g.erase_display(1)
	# Row 0 fully blank
	for c in range(5):
		assert_bool(_is_blank(g.get_cell(0, c))).is_true()
	# Row 1: cols 0-2 blank, cols 3-4 intact
	assert_bool(_is_blank(g.get_cell(1, 0))).is_true()
	assert_bool(_is_blank(g.get_cell(1, 2))).is_true()
	assert_bool(_is_blank(g.get_cell(1, 3))).is_false()
	# Row 2 fully intact
	for c in range(5):
		assert_bool(_is_blank(g.get_cell(2, c))).is_false()


# ---------------------------------------------------------------------------
# erase_line mode 2 -- entire line
# ---------------------------------------------------------------------------


func test_erase_line_mode2_clears_entire_line() -> void:
	var g := _make_grid(5, 3)
	_fill_grid(g, "X")
	g.set_cursor(1, 2)
	g.erase_line(2)
	for c in range(5):
		assert_bool(_is_blank(g.get_cell(1, c))).is_true()
	# Other rows intact
	for c in range(5):
		assert_bool(_is_blank(g.get_cell(0, c))).is_false()
	for c in range(5):
		assert_bool(_is_blank(g.get_cell(2, c))).is_false()


func test_erase_line_mode2_does_not_move_cursor() -> void:
	var g := _make_grid(5, 3)
	g.set_cursor(1, 2)
	g.erase_line(2)
	assert_int(g.cursor_row).is_equal(1)
	assert_int(g.cursor_col).is_equal(2)


# ---------------------------------------------------------------------------
# erase_line mode 0 -- cursor to end of line
# ---------------------------------------------------------------------------


func test_erase_line_mode0_clears_cursor_to_end_of_line() -> void:
	var g := _make_grid(5, 3)
	_fill_grid(g, "X")
	g.set_cursor(1, 2)
	g.erase_line(0)
	# Row 1: cols before cursor intact, cols at/after cursor blank
	assert_bool(_is_blank(g.get_cell(1, 1))).is_false()
	assert_bool(_is_blank(g.get_cell(1, 2))).is_true()
	assert_bool(_is_blank(g.get_cell(1, 4))).is_true()
	# Other rows intact
	for c in range(5):
		assert_bool(_is_blank(g.get_cell(0, c))).is_false()
	for c in range(5):
		assert_bool(_is_blank(g.get_cell(2, c))).is_false()


# ---------------------------------------------------------------------------
# erase_line mode 1 -- beginning of line to cursor
# ---------------------------------------------------------------------------


func test_erase_line_mode1_clears_start_to_cursor() -> void:
	var g := _make_grid(5, 3)
	_fill_grid(g, "X")
	g.set_cursor(1, 2)
	g.erase_line(1)
	# Row 1: cols 0-2 blank, cols 3-4 intact
	assert_bool(_is_blank(g.get_cell(1, 0))).is_true()
	assert_bool(_is_blank(g.get_cell(1, 2))).is_true()
	assert_bool(_is_blank(g.get_cell(1, 3))).is_false()
	# Other rows intact
	for c in range(5):
		assert_bool(_is_blank(g.get_cell(0, c))).is_false()
	for c in range(5):
		assert_bool(_is_blank(g.get_cell(2, c))).is_false()
