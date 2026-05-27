# GdUnit4 test: TerminalManager grid-API happy-path coverage.
#
# Spec: .ralph/specs/0003-unit-test-coverage.md  (task 0.4.3)
#
# Covers: get_cell, get_dimensions, resize.
# Shell/IO methods live in terminal_manager_methods_test.gd.
#
# All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_current_dir = "/home/user"
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()
	TerminalManager._mock_cols = 80
	TerminalManager._mock_rows = 24


# ---------------------------------------------------------------------------
# get_cell  (mock mode returns default cell)
# ---------------------------------------------------------------------------


func test_get_cell_mock_returns_dict_with_expected_keys() -> void:
	var cell := TerminalManager.get_cell(0, 0)
	assert_bool(cell.has("char")).is_true()
	assert_bool(cell.has("fg")).is_true()
	assert_bool(cell.has("bg")).is_true()
	assert_bool(cell.has("bold")).is_true()
	assert_bool(cell.has("italic")).is_true()


func test_get_cell_mock_returns_space_char() -> void:
	var cell := TerminalManager.get_cell(0, 0)
	assert_str(cell["char"]).is_equal(" ")


func test_get_cell_mock_returns_white_foreground() -> void:
	var cell := TerminalManager.get_cell(0, 0)
	assert_bool(cell["fg"] == Color.WHITE).is_true()


func test_get_cell_mock_returns_black_background() -> void:
	var cell := TerminalManager.get_cell(0, 0)
	assert_bool(cell["bg"] == Color.BLACK).is_true()


func test_get_cell_mock_bold_is_false() -> void:
	var cell := TerminalManager.get_cell(0, 0)
	assert_bool(cell["bold"]).is_false()


func test_get_cell_mock_italic_is_false() -> void:
	var cell := TerminalManager.get_cell(0, 0)
	assert_bool(cell["italic"]).is_false()


# ---------------------------------------------------------------------------
# get_dimensions  (mock mode returns [80, 24])
# ---------------------------------------------------------------------------


func test_get_dimensions_mock_returns_array_of_two() -> void:
	var dims := TerminalManager.get_dimensions()
	assert_int(dims.size()).is_equal(2)


func test_get_dimensions_mock_cols_is_80() -> void:
	var dims := TerminalManager.get_dimensions()
	assert_int(dims[0]).is_equal(80)


func test_get_dimensions_mock_rows_is_24() -> void:
	var dims := TerminalManager.get_dimensions()
	assert_int(dims[1]).is_equal(24)


# ---------------------------------------------------------------------------
# resize  (mock mode is a no-op — must not crash)
# ---------------------------------------------------------------------------


func test_resize_mock_does_not_crash() -> void:
	TerminalManager.resize(120, 40)
	var dims := TerminalManager.get_dimensions()
	assert_int(dims[0]).is_equal(80)
	assert_int(dims[1]).is_equal(24)
