# GdUnit4 test: TerminalGrid cursor API.
#
# Spec: docs/todo-v1.md  (task 1.0.3)
#
# Tests: cursor initial position, set_cursor, move_cursor, write_at_cursor,
#        bounds-clamping, column-advance behaviour.
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


# ---------------------------------------------------------------------------
# Initial cursor state
# ---------------------------------------------------------------------------


func test_cursor_initial_row_is_zero() -> void:
	var g := _make_grid(80, 24)
	assert_int(g.cursor_row).is_equal(0)


func test_cursor_initial_col_is_zero() -> void:
	var g := _make_grid(80, 24)
	assert_int(g.cursor_col).is_equal(0)


# ---------------------------------------------------------------------------
# set_cursor
# ---------------------------------------------------------------------------


func test_set_cursor_updates_row() -> void:
	var g := _make_grid(80, 24)
	g.set_cursor(3, 5)
	assert_int(g.cursor_row).is_equal(3)


func test_set_cursor_updates_col() -> void:
	var g := _make_grid(80, 24)
	g.set_cursor(3, 5)
	assert_int(g.cursor_col).is_equal(5)


func test_set_cursor_clamps_row_to_last_row() -> void:
	var g := _make_grid(10, 5)
	g.set_cursor(100, 0)
	assert_int(g.cursor_row).is_equal(4)


func test_set_cursor_clamps_col_to_last_col() -> void:
	var g := _make_grid(10, 5)
	g.set_cursor(0, 100)
	assert_int(g.cursor_col).is_equal(9)


func test_set_cursor_clamps_negative_row_to_zero() -> void:
	var g := _make_grid(10, 5)
	g.set_cursor(-5, 0)
	assert_int(g.cursor_row).is_equal(0)


func test_set_cursor_clamps_negative_col_to_zero() -> void:
	var g := _make_grid(10, 5)
	g.set_cursor(0, -5)
	assert_int(g.cursor_col).is_equal(0)


# ---------------------------------------------------------------------------
# move_cursor
# ---------------------------------------------------------------------------


func test_move_cursor_up() -> void:
	var g := _make_grid(80, 24)
	g.set_cursor(5, 5)
	g.move_cursor(-2, 0)
	assert_int(g.cursor_row).is_equal(3)


func test_move_cursor_down() -> void:
	var g := _make_grid(80, 24)
	g.set_cursor(5, 5)
	g.move_cursor(3, 0)
	assert_int(g.cursor_row).is_equal(8)


func test_move_cursor_right() -> void:
	var g := _make_grid(80, 24)
	g.set_cursor(5, 5)
	g.move_cursor(0, 4)
	assert_int(g.cursor_col).is_equal(9)


func test_move_cursor_left() -> void:
	var g := _make_grid(80, 24)
	g.set_cursor(5, 5)
	g.move_cursor(0, -3)
	assert_int(g.cursor_col).is_equal(2)


func test_move_cursor_clamps_up_at_top() -> void:
	var g := _make_grid(10, 5)
	g.set_cursor(1, 0)
	g.move_cursor(-10, 0)
	assert_int(g.cursor_row).is_equal(0)


func test_move_cursor_clamps_down_at_bottom() -> void:
	var g := _make_grid(10, 5)
	g.set_cursor(3, 0)
	g.move_cursor(100, 0)
	assert_int(g.cursor_row).is_equal(4)


func test_move_cursor_clamps_left_at_zero() -> void:
	var g := _make_grid(10, 5)
	g.set_cursor(0, 2)
	g.move_cursor(0, -100)
	assert_int(g.cursor_col).is_equal(0)


func test_move_cursor_clamps_right_at_last_col() -> void:
	var g := _make_grid(10, 5)
	g.set_cursor(0, 7)
	g.move_cursor(0, 100)
	assert_int(g.cursor_col).is_equal(9)


# ---------------------------------------------------------------------------
# write_at_cursor
# ---------------------------------------------------------------------------


func test_write_at_cursor_places_char_at_cursor_position() -> void:
	var g := _make_grid(80, 24)
	g.set_cursor(3, 5)
	g.write_at_cursor(_char_cell("X"))
	assert_str(g.get_cell(3, 5)["char"]).is_equal("X")


func test_write_at_cursor_advances_col_by_one() -> void:
	var g := _make_grid(80, 24)
	g.set_cursor(0, 0)
	g.write_at_cursor(_char_cell("A"))
	assert_int(g.cursor_col).is_equal(1)


func test_write_at_cursor_does_not_advance_past_last_col() -> void:
	var g := _make_grid(5, 3)
	g.set_cursor(0, 4)  # last col
	g.write_at_cursor(_char_cell("Z"))
	assert_int(g.cursor_col).is_equal(4)


func test_write_at_cursor_does_not_change_row() -> void:
	var g := _make_grid(80, 24)
	g.set_cursor(3, 5)
	g.write_at_cursor(_char_cell("R"))
	assert_int(g.cursor_row).is_equal(3)


func test_write_multiple_chars_advances_sequentially() -> void:
	var g := _make_grid(80, 24)
	g.set_cursor(2, 0)
	g.write_at_cursor(_char_cell("A"))
	g.write_at_cursor(_char_cell("B"))
	g.write_at_cursor(_char_cell("C"))
	assert_str(g.get_cell(2, 0)["char"]).is_equal("A")
	assert_str(g.get_cell(2, 1)["char"]).is_equal("B")
	assert_str(g.get_cell(2, 2)["char"]).is_equal("C")


# ---------------------------------------------------------------------------
# resize clamps cursor
# ---------------------------------------------------------------------------


func test_resize_smaller_clamps_cursor_row() -> void:
	var g := _make_grid(80, 24)
	g.set_cursor(20, 70)
	g.resize(80, 10)
	assert_int(g.cursor_row).is_equal(9)


func test_resize_smaller_clamps_cursor_col() -> void:
	var g := _make_grid(80, 24)
	g.set_cursor(0, 70)
	g.resize(40, 24)
	assert_int(g.cursor_col).is_equal(39)
