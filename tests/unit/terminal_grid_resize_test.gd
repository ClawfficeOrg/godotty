# GdUnit4 test: TerminalGrid grid reflow on resize (task 1.2.3).
#
# Spec: docs/todo-v1.md (task 1.2.3)
#
# Tests: 80-col to 40-col reflow, long lines wrap across rows, short rows
#        gain blank cells on expand, scrollback offset reset on resize.
#
# TerminalGrid is a RefCounted -- no scene tree needed.
extends GdUnitTestSuite


func _make_grid(cols: int, rows: int) -> TerminalGrid:
	var g := TerminalGrid.new()
	g.resize(cols, rows)
	return g


func _char_cell(ch: String) -> Dictionary:
	return {
		"char": ch,
		"fg": Color.WHITE,
		"bg": Color.BLACK,
		"bold": false,
		"italic": false,
		"underline": false,
		"url": "",
	}


## Fill `count` cells at the start of `row` with chars starting at code point 65 ('A').
func _fill_row(grid: TerminalGrid, row: int, count: int) -> void:
	for c in range(count):
		grid.set_cell(row, c, _char_cell(char(65 + c)))


# ---------------------------------------------------------------------------
# 80-col grid reflows to 40-col
# ---------------------------------------------------------------------------


func test_resize_80_to_40_first_half_in_penultimate_row() -> void:
	# Row 3 (bottom) of 80?4 grid has 80 distinct chars.
	# After reflow to 40 cols: [blank, blank, first40, last40].
	var g := _make_grid(80, 4)
	_fill_row(g, 3, 80)
	g.resize(40, 4)
	assert_str(g.get_cell(2, 0)["char"]).is_equal("A")


func test_resize_80_to_40_second_half_in_last_row() -> void:
	var g := _make_grid(80, 4)
	_fill_row(g, 3, 80)
	g.resize(40, 4)
	# Col 40 of the original row had char(65 + 40).
	assert_str(g.get_cell(3, 0)["char"]).is_equal(char(65 + 40))


func test_resize_80_to_40_first_half_chars_correct() -> void:
	var g := _make_grid(80, 4)
	_fill_row(g, 3, 80)
	g.resize(40, 4)
	var ok := true
	for c in range(40):
		if g.get_cell(2, c)["char"] != char(65 + c):
			ok = false
	assert_bool(ok).is_true()


func test_resize_80_to_40_second_half_chars_correct() -> void:
	var g := _make_grid(80, 4)
	_fill_row(g, 3, 80)
	g.resize(40, 4)
	var ok := true
	for c in range(40):
		if g.get_cell(3, c)["char"] != char(65 + 40 + c):
			ok = false
	assert_bool(ok).is_true()


# ---------------------------------------------------------------------------
# Long lines wrap across multiple rows
# ---------------------------------------------------------------------------


func test_long_line_first_half_visible_after_reflow() -> void:
	# 80?3 grid: rows 0,1 blank, row 2 = 80 chars.
	# Reflow to 40?3: [blank, first40, last40].
	var g := _make_grid(80, 3)
	_fill_row(g, 2, 80)
	g.resize(40, 3)
	assert_str(g.get_cell(1, 0)["char"]).is_equal("A")


func test_long_line_second_half_visible_after_reflow() -> void:
	var g := _make_grid(80, 3)
	_fill_row(g, 2, 80)
	g.resize(40, 3)
	assert_str(g.get_cell(2, 0)["char"]).is_equal(char(65 + 40))


func test_long_line_no_char_loss_first_half() -> void:
	var g := _make_grid(80, 3)
	_fill_row(g, 2, 80)
	g.resize(40, 3)
	var ok := true
	for c in range(40):
		if g.get_cell(1, c)["char"] != char(65 + c):
			ok = false
	assert_bool(ok).is_true()


func test_long_line_no_char_loss_second_half() -> void:
	var g := _make_grid(80, 3)
	_fill_row(g, 2, 80)
	g.resize(40, 3)
	var ok := true
	for c in range(40):
		if g.get_cell(2, c)["char"] != char(65 + 40 + c):
			ok = false
	assert_bool(ok).is_true()


func test_very_long_line_wraps_three_times() -> void:
	# 120-char line in a 120?4 grid; reflow to 40 -> 3 physical rows.
	var g := _make_grid(120, 4)
	_fill_row(g, 3, 120)
	g.resize(40, 4)
	# Reflow of 3 blank + 1?120-char line -> [blank, row0, row1, row2].
	assert_str(g.get_cell(1, 0)["char"]).is_equal("A")
	assert_str(g.get_cell(2, 0)["char"]).is_equal(char(65 + 40))
	assert_str(g.get_cell(3, 0)["char"]).is_equal(char(65 + 80))


# ---------------------------------------------------------------------------
# Short rows gain blank cells
# ---------------------------------------------------------------------------


func test_short_row_trailing_cells_are_blank_after_expand() -> void:
	# 5-char row in 10?3 grid; expand to 20.
	var g := _make_grid(10, 3)
	_fill_row(g, 2, 5)
	g.resize(20, 3)
	assert_str(g.get_cell(2, 5)["char"]).is_equal(" ")
	assert_str(g.get_cell(2, 19)["char"]).is_equal(" ")


func test_short_row_content_preserved_after_expand() -> void:
	var g := _make_grid(10, 3)
	_fill_row(g, 2, 5)
	g.resize(20, 3)
	assert_str(g.get_cell(2, 0)["char"]).is_equal("A")
	assert_str(g.get_cell(2, 4)["char"]).is_equal("E")


func test_blank_rows_padded_on_expand() -> void:
	var g := _make_grid(10, 2)
	g.resize(10, 5)
	# New rows 2, 3, 4 should exist and be blank.
	assert_str(g.get_cell(2, 0)["char"]).is_equal(" ")
	assert_str(g.get_cell(4, 9)["char"]).is_equal(" ")


# ---------------------------------------------------------------------------
# Scrollback offset adjusted
# ---------------------------------------------------------------------------


func test_scrollback_offset_reset_to_zero_when_nonzero() -> void:
	var g := _make_grid(80, 5)
	g.scrollback_offset = 3
	g.resize(40, 5)
	assert_int(g.scrollback_offset).is_equal(0)


func test_scrollback_offset_stays_zero_on_expand() -> void:
	var g := _make_grid(80, 5)
	g.scrollback_offset = 0
	g.resize(80, 10)
	assert_int(g.scrollback_offset).is_equal(0)


func test_scrollback_offset_is_zero_after_shrink() -> void:
	var g := _make_grid(80, 10)
	g.scrollback_offset = 7
	g.resize(80, 5)
	assert_int(g.scrollback_offset).is_equal(0)
