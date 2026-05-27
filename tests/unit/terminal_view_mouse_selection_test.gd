## GdUnit4 tests: click-drag text selection in TerminalView (task 1.4.1).
##
## Spec: docs/todo-v1.md (task 1.4.1)
##
## Covers:
##   - Mouse-down sets selection_start; drag updates selection_end.
##   - selected_cell_count() returns the inclusive rectangular cell count.
##   - _pixel_to_cell / grid helpers use CHAR_W / CHAR_H metrics.
##   - Selection overlay (ColorRect) is created, visible, and has correct rect.
##   - Out-of-bounds drag is clamped to grid dimensions.
##
## All tests run in mock mode -- no GDExtension required.
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
# Helper: synthesise a left-mouse-button press event at a pixel position.
# ---------------------------------------------------------------------------


func _make_mouse_press(pos: Vector2) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = pos
	return ev


func _make_mouse_release(pos: Vector2) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = false
	ev.position = pos
	return ev


func _make_mouse_motion(pos: Vector2) -> InputEventMouseMotion:
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	return ev


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


## Press at cell (0,0), drag down to cell (0,4) -> 5 cells selected.
func test_mouse_down_and_drag_selects_five_cells() -> void:
	var start_px := Vector2(0.0, 0.0)
	# Cell (col=0, row=4): row 4 * CHAR_H pixels down.
	var end_px := Vector2(0.0, 4.0 * TerminalView.CHAR_H)

	_view._gui_input(_make_mouse_press(start_px))
	_view._gui_input(_make_mouse_motion(end_px))

	assert_that(_view.selection_start).is_equal(Vector2i(0, 0))
	assert_that(_view.selection_end).is_equal(Vector2i(0, 4))
	assert_int(_view.selected_cell_count()).is_equal(5)


## Press at cell (0,5), drag up to cell (0,0) -- reversed drag normalises.
func test_reverse_drag_selection_count_matches_forward() -> void:
	var start_px := Vector2(0.0, 5.0 * TerminalView.CHAR_H)
	var end_px := Vector2(0.0, 0.0)

	_view._gui_input(_make_mouse_press(start_px))
	_view._gui_input(_make_mouse_motion(end_px))

	# selected_cell_count uses abs() so direction is irrelevant.
	assert_int(_view.selected_cell_count()).is_equal(6)


## Verify _pixel_to_cell maps pixel offsets to correct cells via CHAR_W / CHAR_H.
func test_pixel_to_cell_conversion_uses_char_metrics() -> void:
	# col 3, row 2 -> pixel (3*CHAR_W, 2*CHAR_H)
	var px := Vector2(3.0 * TerminalView.CHAR_W, 2.0 * TerminalView.CHAR_H)
	_view._gui_input(_make_mouse_press(px))

	assert_that(_view.selection_start).is_equal(Vector2i(3, 2))


## After a drag the selection overlay must exist, be visible, and cover the cells.
func test_selection_overlay_exists_and_covers_selected_cells() -> void:
	var start_px := Vector2(0.0, 0.0)
	var end_px := Vector2(2.0 * TerminalView.CHAR_W, 0.0)  # 3 cells wide, same row

	_view._gui_input(_make_mouse_press(start_px))
	_view._gui_input(_make_mouse_motion(end_px))

	assert_object(_view._selection_overlay).is_not_null()
	assert_bool(_view._selection_overlay.visible).is_true()
	# Overlay should span 3 columns ? 1 row.
	assert_float(_view._selection_overlay.size.x).is_equal(3.0 * TerminalView.CHAR_W)
	assert_float(_view._selection_overlay.size.y).is_equal(TerminalView.CHAR_H)


## Out-of-bounds drag clamps to grid limits; no negative or overflowing indices.
func test_selection_clamped_to_grid_bounds() -> void:
	# Drag far past the terminal dimensions.
	var start_px := Vector2(0.0, 0.0)
	var huge_px := Vector2(99999.0, 99999.0)

	_view._gui_input(_make_mouse_press(start_px))
	_view._gui_input(_make_mouse_motion(huge_px))

	# End must be clamped: col < _terminal_cols, row < _terminal_rows.
	assert_int(_view.selection_end.x).is_less_equal(_view._terminal_cols - 1)
	assert_int(_view.selection_end.y).is_less_equal(_view._terminal_rows - 1)
	assert_int(_view.selection_end.x).is_greater_equal(0)
	assert_int(_view.selection_end.y).is_greater_equal(0)
