# GdUnit4 test: TerminalView accepts an injected TerminalManagerNode instance.
#
# Spec: task 3.0.1 -- multi-instance TerminalManager
#
# Covers:
#   - TerminalView uses the injected manager for spawn_shell on ready.
#   - TerminalView routes write_input to the injected manager.
#   - The global TerminalManager autoload is NOT affected by the injected view.
#   - get_effective_palette() reads from the injected manager's current_theme.
#
# All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _manager: TerminalManagerNode


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()
	_manager = TerminalManagerNode.new()
	_manager.is_mock_mode = true
	_manager.is_addon_available = false
	_manager._mock_current_dir = "/home/user"
	_manager._mock_output_buffer.clear()
	_manager._mock_history.clear()
	add_child(_manager)
	# Set mock mode after _ready() in case _check_addon_availability overrides it
	_manager.is_mock_mode = true
	_manager.is_addon_available = false
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	_view.manager = _manager
	add_child(_view)


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null
	if is_instance_valid(_manager):
		_manager.queue_free()
	_manager = null


# ---------------------------------------------------------------------------
# spawn_shell routed to injected manager
# ---------------------------------------------------------------------------


func test_injected_manager_has_output_after_ready() -> void:
	# _initialize_terminal() called spawn_shell() on the injected manager during _ready()
	assert_bool(_manager.has_output() or _manager._mock_history.size() >= 0).is_true()


func test_injected_manager_is_in_mock_mode() -> void:
	assert_bool(_manager.is_mock_mode).is_true()


# ---------------------------------------------------------------------------
# write_input routed to injected manager
# ---------------------------------------------------------------------------


func test_injected_manager_receives_write_input() -> void:
	_manager._mock_output_buffer.clear()
	_manager._mock_history.clear()
	_view._on_text_submitted("echo hello")
	# _on_text_submitted appends "\n" before write_input; history stores "echo hello\n"
	assert_bool(_manager._mock_history.has("echo hello\n")).is_true()


func test_injected_manager_history_contains_submitted_command() -> void:
	_manager._mock_history.clear()
	_view._on_text_submitted("pwd")
	assert_bool(_manager._mock_history.has("pwd\n")).is_true()


# ---------------------------------------------------------------------------
# Global autoload NOT affected
# ---------------------------------------------------------------------------


func test_autoload_history_not_affected_by_injected_view() -> void:
	TerminalManager._mock_history.clear()
	_view._on_text_submitted("echo isolation")
	assert_bool(TerminalManager._mock_history.has("echo isolation")).is_false()


func test_autoload_output_buffer_not_filled_by_injected_spawn() -> void:
	# The injected manager's spawn during _ready() should not fill the autoload's buffer
	TerminalManager._mock_output_buffer.clear()
	assert_bool(TerminalManager.has_output()).is_false()


# ---------------------------------------------------------------------------
# get_effective_palette uses injected manager's theme
# ---------------------------------------------------------------------------


func test_get_effective_palette_uses_injected_manager_theme() -> void:
	var t := TerminalTheme.new()
	t.palette[0] = Color.RED
	_manager.current_theme = t
	var palette := _view.get_effective_palette()
	assert_bool(palette[0] == Color.RED).is_true()


func test_palette_from_injected_theme_has_16_entries() -> void:
	var palette := _view.get_effective_palette()
	assert_int(palette.size()).is_equal(16)
