# GdUnit4 test: TerminalView reads color palette from TerminalManager.current_theme.
#
# Spec: docs/todo-v2.md (task 2.0.2)
#
# Covers: get_effective_palette() returns TerminalManager.current_theme.palette;
#         swapping current_theme at runtime changes get_effective_palette();
#         theme change sets _needs_full_rerender flag.
#
# All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _saved_theme: TerminalTheme


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_saved_theme = TerminalManager.current_theme
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null
	# Restore theme via backing var to avoid emitting theme_changed after _view is freed.
	TerminalManager._current_theme = _saved_theme


# ---------------------------------------------------------------------------
# get_effective_palette reflects TerminalManager.current_theme on startup
# ---------------------------------------------------------------------------


func test_initial_palette_from_terminal_manager() -> void:
	var manager_palette: Array[Color] = TerminalManager.current_theme.palette
	var view_palette: Array[Color] = _view.get_effective_palette()
	assert_int(view_palette.size()).is_equal(16)
	assert_bool(view_palette[0] == manager_palette[0]).is_true()
	assert_bool(view_palette[15] == manager_palette[15]).is_true()


func test_get_effective_palette_has_16_entries() -> void:
	assert_int(_view.get_effective_palette().size()).is_equal(16)


func test_get_effective_palette_entries_are_colors() -> void:
	var palette: Array[Color] = _view.get_effective_palette()
	assert_bool(palette[0] is Color).is_true()
	assert_bool(palette[7] is Color).is_true()
	assert_bool(palette[15] is Color).is_true()


# ---------------------------------------------------------------------------
# Swapping current_theme changes get_effective_palette
# ---------------------------------------------------------------------------


func test_swapping_theme_changes_effective_palette() -> void:
	var theme_a := TerminalTheme.new()
	var palette_a: Array[Color] = []
	palette_a.resize(16)
	for i: int in 16:
		palette_a[i] = Color(1.0, 0.0, 0.0, 1.0)
	theme_a.palette = palette_a

	TerminalManager.current_theme = theme_a

	var view_palette: Array[Color] = _view.get_effective_palette()
	assert_bool(view_palette[0] == Color(1.0, 0.0, 0.0, 1.0)).is_true()
	assert_bool(view_palette[7] == Color(1.0, 0.0, 0.0, 1.0)).is_true()


func test_swapping_theme_twice_reflects_final_theme() -> void:
	var theme_x := TerminalTheme.new()
	var px: Array[Color] = []
	px.resize(16)
	for i: int in 16:
		px[i] = Color(0.2, 0.4, 0.6, 1.0)
	theme_x.palette = px

	var theme_y := TerminalTheme.new()
	var py: Array[Color] = []
	py.resize(16)
	for i: int in 16:
		py[i] = Color(0.6, 0.4, 0.2, 1.0)
	theme_y.palette = py

	TerminalManager.current_theme = theme_x
	TerminalManager.current_theme = theme_y

	var view_palette: Array[Color] = _view.get_effective_palette()
	assert_bool(view_palette[0] == Color(0.6, 0.4, 0.2, 1.0)).is_true()
	assert_bool(view_palette[15] == Color(0.6, 0.4, 0.2, 1.0)).is_true()


# ---------------------------------------------------------------------------
# Theme change sets _needs_full_rerender flag
# ---------------------------------------------------------------------------


func test_swapping_theme_sets_needs_full_rerender_flag() -> void:
	_view._needs_full_rerender = false

	var theme_b := TerminalTheme.new()
	var palette_b: Array[Color] = []
	palette_b.resize(16)
	for i: int in 16:
		palette_b[i] = Color(0.0, 1.0, 0.0, 1.0)
	theme_b.palette = palette_b

	TerminalManager.current_theme = theme_b

	assert_bool(_view._needs_full_rerender).is_true()


func test_needs_full_rerender_false_before_theme_change() -> void:
	assert_bool(_view._needs_full_rerender).is_false()
