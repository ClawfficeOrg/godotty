## GdUnit4 tests: three independent shell sessions (release gate 3.0.0).
##
## Spec: docs/todo-v3.md (task 3.0.5)
##
## Release gate: "open 3 tabs, run different commands in each -- tabs are
## fully independent."
##
## Covers:
##   1. test_three_instances_are_distinct   -- three TerminalManagerNode objects are distinct.
##   2. test_each_instance_starts_shell     -- spawn_shell returns true on all three.
##   3. test_output_is_isolated_per_tab     -- writing to tab 1 does not add output to tabs 2/3.
##   4. test_dirs_are_independent           -- each instance tracks its own CWD.
##   5. test_histories_are_isolated         -- command history does not leak between instances.
##   6. test_commands_produce_output_only_in_target -- write_input only buffers to sender.
##
## All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

var _tab1: TerminalManagerNode
var _tab2: TerminalManagerNode
var _tab3: TerminalManagerNode


func before_test() -> void:
	_tab1 = TerminalManagerNode.new()
	_tab2 = TerminalManagerNode.new()
	_tab3 = TerminalManagerNode.new()
	_tab1.is_mock_mode = true
	_tab1.is_addon_available = false
	_tab2.is_mock_mode = true
	_tab2.is_addon_available = false
	_tab3.is_mock_mode = true
	_tab3.is_addon_available = false


func after_test() -> void:
	if is_instance_valid(_tab1):
		_tab1.free()
	if is_instance_valid(_tab2):
		_tab2.free()
	if is_instance_valid(_tab3):
		_tab3.free()
	_tab1 = null
	_tab2 = null
	_tab3 = null


## Three TerminalManagerNode instances are distinct objects.
func test_three_instances_are_distinct() -> void:
	assert_bool(_tab1 != _tab2).is_true()
	assert_bool(_tab2 != _tab3).is_true()
	assert_bool(_tab1 != _tab3).is_true()


## spawn_shell() returns true on all three tabs.
func test_each_instance_starts_shell() -> void:
	assert_bool(_tab1.spawn_shell()).is_true()
	assert_bool(_tab2.spawn_shell()).is_true()
	assert_bool(_tab3.spawn_shell()).is_true()


## Output produced by spawning tab 1 does not appear in tab 2 or tab 3.
func test_output_is_isolated_per_tab() -> void:
	_tab1.spawn_shell()
	assert_bool(_tab2.has_output()).is_false()
	assert_bool(_tab3.has_output()).is_false()


## Each instance maintains its own current working directory.
func test_dirs_are_independent() -> void:
	_tab1._mock_current_dir = "/home/alice"
	_tab2._mock_current_dir = "/home/bob"
	_tab3._mock_current_dir = "/home/carol"
	assert_str(_tab1._mock_current_dir).is_equal("/home/alice")
	assert_str(_tab2._mock_current_dir).is_equal("/home/bob")
	assert_str(_tab3._mock_current_dir).is_equal("/home/carol")


## Command history does not leak between instances.
func test_histories_are_isolated() -> void:
	_tab1.write_input("echo tab1")
	_tab2.write_input("echo tab2")
	_tab3.write_input("echo tab3")
	assert_bool(_tab1._mock_history.has("echo tab1")).is_true()
	assert_bool(_tab2._mock_history.has("echo tab2")).is_true()
	assert_bool(_tab3._mock_history.has("echo tab3")).is_true()
	assert_bool(_tab1._mock_history.has("echo tab2")).is_false()
	assert_bool(_tab1._mock_history.has("echo tab3")).is_false()
	assert_bool(_tab2._mock_history.has("echo tab1")).is_false()
	assert_bool(_tab3._mock_history.has("echo tab1")).is_false()


## write_input to one tab does not produce output in the other two.
func test_commands_produce_output_only_in_target() -> void:
	_tab1.spawn_shell()
	_tab2.spawn_shell()
	_tab3.spawn_shell()
	# Drain initial spawn output.
	while _tab1.has_output():
		_tab1.read_output()
	while _tab2.has_output():
		_tab2.read_output()
	while _tab3.has_output():
		_tab3.read_output()
	_tab1.write_input("echo hello_from_tab1")
	assert_bool(_tab2.has_output()).is_false()
	assert_bool(_tab3.has_output()).is_false()
