## GdUnit4 tests: Ctrl+Tab cycles focus among three tabs (release gate 3.0.0).
##
## Spec: docs/todo-v3.md (task 3.0.5)
##
## Release gate: "Ctrl+Tab cycles."
##
## Covers:
##   1. test_cycle_three_tabs_full_round   -- next_tab cycles 1->2->3->1.
##   2. test_cycle_emits_tab_focused       -- each next_tab() step emits tab_focused.
##   3. test_cycle_after_close_middle      -- after removing tab 2, cycles 1->3->1.
##   4. test_cycle_starts_at_first_when_none_active -- with no active tab, goes to index 0.
##   5. test_active_id_tracks_cycle        -- get_active_shell_id() reflects each step.
##   6. test_cycle_three_tabs_signal_count -- three next_tab() calls emit three tab_focused signals.
##
## All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

const TAB_BAR_SCENE := preload("res://scenes/tab_bar.tscn")

var _bar: TerminalTabBar
var _focused_ids: Array[String] = []


func before_test() -> void:
	_bar = TAB_BAR_SCENE.instantiate() as TerminalTabBar
	add_child(_bar)
	_focused_ids.clear()
	_bar.tab_focused.connect(_on_tab_focused)
	_bar.add_tab("sh_1", "bash")
	_bar.add_tab("sh_2", "zsh")
	_bar.add_tab("sh_3", "sh")
	_bar.focus_tab("sh_1")
	_focused_ids.clear()


func after_test() -> void:
	if is_instance_valid(_bar):
		if _bar.tab_focused.is_connected(_on_tab_focused):
			_bar.tab_focused.disconnect(_on_tab_focused)
		_bar.queue_free()
	_bar = null


func _on_tab_focused(shell_id: String) -> void:
	_focused_ids.append(shell_id)


## next_tab() cycles through tabs 1 -> 2 -> 3 -> 1 (full round).
func test_cycle_three_tabs_full_round() -> void:
	_bar.next_tab()
	assert_str(_bar.get_active_shell_id()).is_equal("sh_2")
	_bar.next_tab()
	assert_str(_bar.get_active_shell_id()).is_equal("sh_3")
	_bar.next_tab()
	assert_str(_bar.get_active_shell_id()).is_equal("sh_1")


## Each next_tab() emits tab_focused with the correct shell_id.
func test_cycle_emits_tab_focused() -> void:
	_bar.next_tab()
	_bar.next_tab()
	_bar.next_tab()
	assert_int(_focused_ids.size()).is_equal(3)
	assert_str(_focused_ids[0]).is_equal("sh_2")
	assert_str(_focused_ids[1]).is_equal("sh_3")
	assert_str(_focused_ids[2]).is_equal("sh_1")


## After removing the middle tab, next_tab() cycles 1 -> 3 -> 1.
func test_cycle_after_close_middle() -> void:
	_bar.remove_tab("sh_2")
	_bar.focus_tab("sh_1")
	_focused_ids.clear()
	_bar.next_tab()
	assert_str(_bar.get_active_shell_id()).is_equal("sh_3")
	_bar.next_tab()
	assert_str(_bar.get_active_shell_id()).is_equal("sh_1")


## With no active tab, next_tab() moves to the first tab in insertion order.
func test_cycle_starts_at_first_when_none_active() -> void:
	var bar2: TerminalTabBar = TAB_BAR_SCENE.instantiate() as TerminalTabBar
	add_child(bar2)
	bar2.tab_focused.connect(_on_tab_focused)
	bar2.add_tab("x_1", "bash")
	bar2.add_tab("x_2", "zsh")
	_focused_ids.clear()
	bar2.next_tab()
	assert_str(bar2.get_active_shell_id()).is_equal("x_1")
	if is_instance_valid(bar2):
		if bar2.tab_focused.is_connected(_on_tab_focused):
			bar2.tab_focused.disconnect(_on_tab_focused)
		bar2.queue_free()


## get_active_shell_id() returns the tab focused most recently by next_tab().
func test_active_id_tracks_cycle() -> void:
	_bar.next_tab()
	assert_str(_bar.get_active_shell_id()).is_equal("sh_2")
	_bar.next_tab()
	assert_str(_bar.get_active_shell_id()).is_equal("sh_3")


## Three next_tab() calls produce exactly three tab_focused emissions.
func test_cycle_three_tabs_signal_count() -> void:
	_bar.next_tab()
	_bar.next_tab()
	_bar.next_tab()
	assert_int(_focused_ids.size()).is_equal(3)
