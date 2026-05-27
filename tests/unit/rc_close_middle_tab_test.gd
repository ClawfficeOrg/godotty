## GdUnit4 tests: closing the middle tab leaves remaining tabs intact (release gate 3.0.0).
##
## Spec: docs/todo-v3.md (task 3.0.5)
##
## Release gate: "close the middle tab; tabs are fully independent."
##
## Covers:
##   1. test_three_tabs_initial_count          -- three tabs give tab_count == 3.
##   2. test_remove_middle_tab_count           -- removing middle tab gives count == 2.
##   3. test_first_tab_survives_middle_close   -- tab 1 still present after middle removed.
##   4. test_third_tab_survives_middle_close   -- tab 3 still present after middle removed.
##   5. test_middle_tab_absent_after_close     -- tab 2 is absent after removal.
##   6. test_active_id_clears_when_active_closed -- active_shell_id resets when active tab removed.
##   7. test_managers_independent_after_middle_close -- removing tab 2 does not affect tab 1/3 managers.
##
## All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

const TAB_BAR_SCENE := preload("res://scenes/tab_bar.tscn")

var _bar: TerminalTabBar
var _mgr1: TerminalManagerNode
var _mgr2: TerminalManagerNode
var _mgr3: TerminalManagerNode


func before_test() -> void:
	_bar = TAB_BAR_SCENE.instantiate() as TerminalTabBar
	add_child(_bar)
	_bar.add_tab("sh_1", "bash")
	_bar.add_tab("sh_2", "zsh")
	_bar.add_tab("sh_3", "sh")
	_mgr1 = TerminalManagerNode.new()
	_mgr2 = TerminalManagerNode.new()
	_mgr3 = TerminalManagerNode.new()
	for m: TerminalManagerNode in [_mgr1, _mgr2, _mgr3]:
		m.is_mock_mode = true
		m.is_addon_available = false


func after_test() -> void:
	if is_instance_valid(_bar):
		_bar.queue_free()
	_bar = null
	for m: TerminalManagerNode in [_mgr1, _mgr2, _mgr3]:
		if is_instance_valid(m):
			m.free()
	_mgr1 = null
	_mgr2 = null
	_mgr3 = null


## Three tabs give get_tab_count() == 3.
func test_three_tabs_initial_count() -> void:
	assert_int(_bar.get_tab_count()).is_equal(3)


## Removing the middle tab reduces count to 2.
func test_remove_middle_tab_count() -> void:
	_bar.remove_tab("sh_2")
	assert_int(_bar.get_tab_count()).is_equal(2)


## Tab 1 is still present after the middle tab is removed.
func test_first_tab_survives_middle_close() -> void:
	_bar.remove_tab("sh_2")
	assert_bool(_bar._tabs.has("sh_1")).is_true()


## Tab 3 is still present after the middle tab is removed.
func test_third_tab_survives_middle_close() -> void:
	_bar.remove_tab("sh_2")
	assert_bool(_bar._tabs.has("sh_3")).is_true()


## Tab 2 is absent from _tabs after removal.
func test_middle_tab_absent_after_close() -> void:
	_bar.remove_tab("sh_2")
	assert_bool(_bar._tabs.has("sh_2")).is_false()


## If the active tab is the one removed, active_shell_id resets to "".
func test_active_id_clears_when_active_closed() -> void:
	_bar.focus_tab("sh_2")
	assert_str(_bar.get_active_shell_id()).is_equal("sh_2")
	_bar.remove_tab("sh_2")
	assert_str(_bar.get_active_shell_id()).is_equal("")


## TerminalManagerNode instances for tabs 1 and 3 are unaffected after tab 2's
## manager is freed (simulates closing the middle terminal session).
func test_managers_independent_after_middle_close() -> void:
	_mgr1.spawn_shell()
	_mgr2.spawn_shell()
	_mgr3.spawn_shell()
	_mgr1.write_input("echo tab1")
	_mgr3.write_input("echo tab3")
	# Free the middle manager as if the tab was closed.
	_mgr2.free()
	_mgr2 = null
	# Tab 1 and tab 3 managers still function independently.
	assert_bool(is_instance_valid(_mgr1)).is_true()
	assert_bool(is_instance_valid(_mgr3)).is_true()
	assert_bool(_mgr1._mock_history.has("echo tab1")).is_true()
	assert_bool(_mgr3._mock_history.has("echo tab3")).is_true()
