# GdUnit4 test: TerminalGrid backing store.
#
# Spec: docs/todo-v1.md  (task 1.0.1)
#
# Tests: cell round-trips, resize (truncate & pad), out-of-bounds guards,
#        clear_region, scroll_up, to_bbcode_line formatting, two independent
#        instances (primary vs alternate buffer pattern).
#
# TerminalGrid is a RefCounted -- no scene tree needed.
extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


func _make_grid(cols: int, rows: int) -> TerminalGrid:
	var g := TerminalGrid.new()
	g.resize(cols, rows)
	return g


func _red_cell() -> Dictionary:
	return {
		"char": "X",
		"fg": Color.RED,
		"bg": Color.BLUE,
		"bold": true,
		"italic": true,
		"underline": true,
		"url": "https://example.com",
	}


# ---------------------------------------------------------------------------
# Cell round-trip
# ---------------------------------------------------------------------------


func test_cell_round_trip_char() -> void:
	var g := _make_grid(10, 5)
	g.set_cell(2, 3, _red_cell())
	assert_str(g.get_cell(2, 3)["char"]).is_equal("X")


func test_cell_round_trip_fg() -> void:
	var g := _make_grid(10, 5)
	g.set_cell(2, 3, _red_cell())
	assert_bool(g.get_cell(2, 3)["fg"] == Color.RED).is_true()


func test_cell_round_trip_bg() -> void:
	var g := _make_grid(10, 5)
	g.set_cell(2, 3, _red_cell())
	assert_bool(g.get_cell(2, 3)["bg"] == Color.BLUE).is_true()


func test_cell_round_trip_bold() -> void:
	var g := _make_grid(10, 5)
	g.set_cell(2, 3, _red_cell())
	assert_bool(g.get_cell(2, 3)["bold"]).is_true()


func test_cell_round_trip_italic() -> void:
	var g := _make_grid(10, 5)
	g.set_cell(2, 3, _red_cell())
	assert_bool(g.get_cell(2, 3)["italic"]).is_true()


func test_cell_round_trip_underline() -> void:
	var g := _make_grid(10, 5)
	g.set_cell(2, 3, _red_cell())
	assert_bool(g.get_cell(2, 3)["underline"]).is_true()


func test_cell_round_trip_url() -> void:
	var g := _make_grid(10, 5)
	g.set_cell(2, 3, _red_cell())
	assert_str(g.get_cell(2, 3)["url"]).is_equal("https://example.com")


# ---------------------------------------------------------------------------
# Default cell shape
# ---------------------------------------------------------------------------


func test_default_cell_char_is_space() -> void:
	var g := _make_grid(5, 3)
	assert_str(g.get_cell(0, 0)["char"]).is_equal(" ")


func test_default_cell_fg_is_white() -> void:
	var g := _make_grid(5, 3)
	assert_bool(g.get_cell(0, 0)["fg"] == Color.WHITE).is_true()


func test_default_cell_bg_is_black() -> void:
	var g := _make_grid(5, 3)
	assert_bool(g.get_cell(0, 0)["bg"] == Color.BLACK).is_true()


func test_default_cell_bold_is_false() -> void:
	var g := _make_grid(5, 3)
	assert_bool(g.get_cell(0, 0)["bold"]).is_false()


# ---------------------------------------------------------------------------
# Resize -- truncate and pad
# ---------------------------------------------------------------------------


func test_resize_preserves_content_in_overlap() -> void:
	var g := _make_grid(10, 5)
	g.set_cell(1, 2, _red_cell())
	g.resize(10, 5)  # same size -- content survives
	assert_str(g.get_cell(1, 2)["char"]).is_equal("X")


func test_resize_truncates_extra_rows() -> void:
	var g := _make_grid(10, 5)
	g.set_cell(4, 0, _red_cell())  # last row
	g.resize(10, 3)  # shrink rows
	# row 4 is gone; out-of-bounds read returns default
	assert_str(g.get_cell(4, 0)["char"]).is_equal(" ")


func test_resize_truncates_extra_cols() -> void:
	var g := _make_grid(10, 5)
	g.set_cell(0, 9, _red_cell())  # last col
	g.resize(5, 5)  # shrink cols
	assert_str(g.get_cell(0, 9)["char"]).is_equal(" ")


func test_resize_pads_new_rows_with_blank() -> void:
	var g := _make_grid(5, 3)
	g.resize(5, 6)  # grow rows
	assert_str(g.get_cell(5, 0)["char"]).is_equal(" ")


func test_resize_pads_new_cols_with_blank() -> void:
	var g := _make_grid(5, 3)
	g.resize(10, 3)  # grow cols
	assert_str(g.get_cell(0, 9)["char"]).is_equal(" ")


# ---------------------------------------------------------------------------
# Out-of-bounds guards
# ---------------------------------------------------------------------------


func test_get_cell_negative_row_returns_default() -> void:
	var g := _make_grid(5, 3)
	assert_str(g.get_cell(-1, 0)["char"]).is_equal(" ")


func test_get_cell_out_of_bounds_row_returns_default() -> void:
	var g := _make_grid(5, 3)
	assert_str(g.get_cell(3, 0)["char"]).is_equal(" ")


func test_get_cell_out_of_bounds_col_returns_default() -> void:
	var g := _make_grid(5, 3)
	assert_str(g.get_cell(0, 5)["char"]).is_equal(" ")


func test_set_cell_out_of_bounds_is_ignored() -> void:
	var g := _make_grid(5, 3)
	g.set_cell(99, 99, _red_cell())
	# grid unchanged -- no crash and in-bounds cells still default
	assert_str(g.get_cell(0, 0)["char"]).is_equal(" ")


# ---------------------------------------------------------------------------
# clear_region
# ---------------------------------------------------------------------------


func test_clear_region_clears_target_cells() -> void:
	var g := _make_grid(10, 5)
	for r in range(5):
		for c in range(10):
			g.set_cell(r, c, _red_cell())
	g.clear_region(1, 2, 2, 3)  # rows 1-2, cols 2-4
	assert_str(g.get_cell(1, 2)["char"]).is_equal(" ")
	assert_str(g.get_cell(1, 3)["char"]).is_equal(" ")
	assert_str(g.get_cell(2, 4)["char"]).is_equal(" ")


func test_clear_region_does_not_affect_outside_cells() -> void:
	var g := _make_grid(10, 5)
	for r in range(5):
		for c in range(10):
			g.set_cell(r, c, _red_cell())
	g.clear_region(1, 2, 2, 3)
	# row 0 and row 4 should be untouched
	assert_str(g.get_cell(0, 0)["char"]).is_equal("X")
	assert_str(g.get_cell(4, 9)["char"]).is_equal("X")


func test_clear_region_clamps_to_bounds() -> void:
	var g := _make_grid(5, 3)
	for r in range(3):
		for c in range(5):
			g.set_cell(r, c, _red_cell())
	# Region extends beyond grid -- must not crash
	g.clear_region(1, 3, 10, 10)
	assert_str(g.get_cell(2, 4)["char"]).is_equal(" ")


# ---------------------------------------------------------------------------
# scroll_up
# ---------------------------------------------------------------------------


func test_scroll_up_removes_top_rows() -> void:
	var g := _make_grid(5, 3)
	# Fill row 0 with "A", row 1 with "B", row 2 with "C"
	for c in range(5):
		var a_cell := {
			"char": "A",
			"fg": Color.WHITE,
			"bg": Color.BLACK,
			"bold": false,
			"italic": false,
			"underline": false,
			"url": ""
		}
		var b_cell := {
			"char": "B",
			"fg": Color.WHITE,
			"bg": Color.BLACK,
			"bold": false,
			"italic": false,
			"underline": false,
			"url": ""
		}
		g.set_cell(0, c, a_cell)
		g.set_cell(1, c, b_cell)
	g.scroll_up(1)
	# Former row 1 ("B") is now row 0
	assert_str(g.get_cell(0, 0)["char"]).is_equal("B")


func test_scroll_up_appends_blank_rows_at_bottom() -> void:
	var g := _make_grid(5, 3)
	for c in range(5):
		g.set_cell(2, c, _red_cell())
	g.scroll_up(1)
	# New bottom row (row 2) should be blank
	assert_str(g.get_cell(2, 0)["char"]).is_equal(" ")


func test_scroll_up_by_n_shifts_correctly() -> void:
	var g := _make_grid(5, 4)
	for c in range(5):
		var r3_cell := {
			"char": "Z",
			"fg": Color.WHITE,
			"bg": Color.BLACK,
			"bold": false,
			"italic": false,
			"underline": false,
			"url": ""
		}
		g.set_cell(3, c, r3_cell)
	g.scroll_up(2)
	# Former row 3 is now row 1 (shifted up by 2)
	assert_str(g.get_cell(1, 0)["char"]).is_equal("Z")


func test_scroll_up_zero_is_noop() -> void:
	var g := _make_grid(5, 3)
	for c in range(5):
		g.set_cell(0, c, _red_cell())
	g.scroll_up(0)
	assert_str(g.get_cell(0, 0)["char"]).is_equal("X")


# ---------------------------------------------------------------------------
# to_bbcode_line
# ---------------------------------------------------------------------------


func test_to_bbcode_line_plain_text_no_tags() -> void:
	var g := _make_grid(3, 1)
	for c in range(3):
		var cell := {
			"char": "a",
			"fg": Color.WHITE,
			"bg": Color.BLACK,
			"bold": false,
			"italic": false,
			"underline": false,
			"url": ""
		}
		g.set_cell(0, c, cell)
	# All cells have default style -> no tags, just chars
	assert_str(g.to_bbcode_line(0)).is_equal("aaa")


func test_to_bbcode_line_bold_wraps_in_b_tag() -> void:
	var g := _make_grid(1, 1)
	var cell := {
		"char": "X",
		"fg": Color.WHITE,
		"bg": Color.BLACK,
		"bold": true,
		"italic": false,
		"underline": false,
		"url": ""
	}
	g.set_cell(0, 0, cell)
	assert_str(g.to_bbcode_line(0)).is_equal("[b]X[/b]")


func test_to_bbcode_line_italic_wraps_in_i_tag() -> void:
	var g := _make_grid(1, 1)
	var cell := {
		"char": "Y",
		"fg": Color.WHITE,
		"bg": Color.BLACK,
		"bold": false,
		"italic": true,
		"underline": false,
		"url": ""
	}
	g.set_cell(0, 0, cell)
	assert_str(g.to_bbcode_line(0)).is_equal("[i]Y[/i]")


func test_to_bbcode_line_underline_wraps_in_u_tag() -> void:
	var g := _make_grid(1, 1)
	var cell := {
		"char": "Z",
		"fg": Color.WHITE,
		"bg": Color.BLACK,
		"bold": false,
		"italic": false,
		"underline": true,
		"url": ""
	}
	g.set_cell(0, 0, cell)
	assert_str(g.to_bbcode_line(0)).is_equal("[u]Z[/u]")


func test_to_bbcode_line_fg_color_tag() -> void:
	var g := _make_grid(1, 1)
	var cell := {
		"char": "R",
		"fg": Color.RED,
		"bg": Color.BLACK,
		"bold": false,
		"italic": false,
		"underline": false,
		"url": ""
	}
	g.set_cell(0, 0, cell)
	var line := g.to_bbcode_line(0)
	assert_bool(line.begins_with("[color=")).is_true()
	assert_bool(line.ends_with("[/color]")).is_true()
	assert_bool(line.contains("R")).is_true()


func test_to_bbcode_line_url_tag() -> void:
	var g := _make_grid(1, 1)
	var cell := {
		"char": "L",
		"fg": Color.WHITE,
		"bg": Color.BLACK,
		"bold": false,
		"italic": false,
		"underline": false,
		"url": "https://example.com"
	}
	g.set_cell(0, 0, cell)
	var line := g.to_bbcode_line(0)
	assert_bool(line.contains("[url=https://example.com]")).is_true()
	assert_bool(line.contains("[/url]")).is_true()


func test_to_bbcode_line_out_of_bounds_returns_empty() -> void:
	var g := _make_grid(5, 3)
	assert_str(g.to_bbcode_line(-1)).is_equal("")
	assert_str(g.to_bbcode_line(3)).is_equal("")


# ---------------------------------------------------------------------------
# Two independent instances (primary vs alternate buffer)
# ---------------------------------------------------------------------------


func test_two_instances_are_independent() -> void:
	var primary := _make_grid(10, 5)
	var alternate := _make_grid(10, 5)
	primary.set_cell(0, 0, _red_cell())
	# Alternate buffer must not see primary's data
	assert_str(alternate.get_cell(0, 0)["char"]).is_equal(" ")


func test_two_instances_resize_independently() -> void:
	var primary := _make_grid(80, 24)
	var alternate := _make_grid(80, 24)
	primary.resize(40, 12)
	# Alternate remains unchanged
	assert_str(alternate.get_cell(23, 79)["char"]).is_equal(" ")
