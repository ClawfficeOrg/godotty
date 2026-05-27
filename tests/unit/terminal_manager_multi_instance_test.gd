# GdUnit4 test: TerminalManagerNode can be instanced per-tab with independent state.
#
# Spec: task 3.0.1 -- multi-instance TerminalManager
#
# Covers:
#   - Two TerminalManagerNode instances maintain independent state.
#   - Autoload registry get_default() / set_default() contract.
#   - Backward-compat shim: existing autoload API still works.
#
# All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

var _inst1: TerminalManagerNode
var _inst2: TerminalManagerNode
var _saved_default: Node


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()
	_saved_default = TerminalManager.get_default()
	_inst1 = TerminalManagerNode.new()
	_inst2 = TerminalManagerNode.new()
	_inst1.is_mock_mode = true
	_inst1.is_addon_available = false
	_inst2.is_mock_mode = true
	_inst2.is_addon_available = false


func after_test() -> void:
	TerminalManager.set_default(_saved_default)
	if is_instance_valid(_inst1):
		_inst1.free()
	_inst1 = null
	if is_instance_valid(_inst2):
		_inst2.free()
	_inst2 = null


# ---------------------------------------------------------------------------
# Instanceability
# ---------------------------------------------------------------------------


func test_terminal_manager_can_be_instanced() -> void:
	assert_bool(is_instance_valid(_inst1)).is_true()
	assert_bool(is_instance_valid(_inst2)).is_true()


func test_two_instances_are_distinct_objects() -> void:
	assert_bool(_inst1 != _inst2).is_true()


# ---------------------------------------------------------------------------
# Independent state
# ---------------------------------------------------------------------------


func test_instances_have_independent_mock_dirs() -> void:
	_inst1._mock_current_dir = "/home/alice"
	_inst2._mock_current_dir = "/home/bob"
	assert_str(_inst1._mock_current_dir).is_equal("/home/alice")
	assert_str(_inst2._mock_current_dir).is_equal("/home/bob")


func test_instances_have_independent_histories() -> void:
	_inst1.write_input("echo inst1")
	_inst2.write_input("echo inst2")
	assert_bool(_inst1._mock_history.has("echo inst1")).is_true()
	assert_bool(_inst2._mock_history.has("echo inst2")).is_true()
	assert_bool(_inst1._mock_history.has("echo inst2")).is_false()
	assert_bool(_inst2._mock_history.has("echo inst1")).is_false()


func test_writing_to_inst1_does_not_affect_inst2_buffer() -> void:
	_inst1.spawn_shell()
	# Drain inst1's buffer
	while _inst1.has_output():
		_inst1.read_output()
	_inst1.write_input("echo only_inst1")
	# inst2 should have no output
	assert_bool(_inst2.has_output()).is_false()


# ---------------------------------------------------------------------------
# Registry: get_default / set_default
# ---------------------------------------------------------------------------


func test_autoload_registry_returns_non_null_default() -> void:
	assert_bool(TerminalManager.get_default() != null).is_true()


func test_autoload_registry_default_is_autoload_itself() -> void:
	assert_bool(TerminalManager.get_default() == TerminalManager).is_true()


func test_autoload_set_default_stores_node() -> void:
	TerminalManager.set_default(_inst1)
	assert_bool(TerminalManager.get_default() == _inst1).is_true()
	TerminalManager.set_default(_saved_default)


func test_autoload_set_default_roundtrip_restores_original() -> void:
	TerminalManager.set_default(_inst1)
	TerminalManager.set_default(_saved_default)
	assert_bool(TerminalManager.get_default() == _saved_default).is_true()


# ---------------------------------------------------------------------------
# Backward-compatibility shim
# ---------------------------------------------------------------------------


func test_backward_compat_spawn_shell_returns_true() -> void:
	var result := TerminalManager.spawn_shell()
	assert_bool(result).is_true()


func test_backward_compat_autoload_has_output_after_spawn() -> void:
	TerminalManager.spawn_shell()
	assert_bool(TerminalManager.has_output()).is_true()
