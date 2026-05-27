## GdUnit4 tests: TerminalTabBar tab ordering and cycling (task 3.0.3).
##
## Spec: docs/todo-v3.md (task 3.0.3)
##
## Covers:
##   1. test_get_tab_count_empty              — get_tab_count() returns 0 with no tabs.
##   2. test_get_tab_count_with_tabs          — get_tab_count() returns correct count.
##   3. test_get_active_shell_id_default      — get_active_shell_id() returns "" initially.
##   4. test_get_active_shell_id_after_focus  — get_active_shell_id() returns focused tab's id.
##   5. test_next_tab_cycles_to_second        — next_tab() advances from first to second tab.
##   6. test_next_tab_wraps_around            — next_tab() wraps from last back to first tab.
##   7. test_next_tab_single_tab              — next_tab() with one tab stays on same tab.
##   8. test_next_tab_emits_tab_focused       — next_tab() emits tab_focused with next shell_id.
##   9. test_next_tab_no_tabs                 — next_tab() is no-op when no tabs exist.
##
## All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite

const TAB_BAR_SCENE := preload("res://scenes/tab_bar.tscn")

var _bar: TerminalTabBar
var _last_focused: String = ""
var _focus_count: int = 0


func before_test() -> void:
	_bar = TAB_BAR_SCENE.instantiate() as TerminalTabBar
	add_child(_bar)
	_last_focused = ""
	_focus_count = 0
	_bar.tab_focused.connect(_on_tab_focused)


func after_test() -> void:
	if is_instance_valid(_bar):
		if _bar.tab_focused.is_connected(_on_tab_focused):
			_bar.tab_focused.disconnect(_on_tab_focused)
		_bar.queue_free()
	_bar = null


func _on_tab_focused(shell_id: String) -> void:
	_last_focused = shell_id
	_focus_count += 1


## get_tab_count() returns 0 when no tabs have been added.
func test_get_tab_count_empty() -> void:
	assert_int(_bar.get_tab_count()).is_equal(0)


## get_tab_count() returns the number of tabs currently present.
func test_get_tab_count_with_tabs() -> void:
	_bar.add_tab("sh_1", "bash")
	_bar.add_tab("sh_2", "zsh")
	assert_int(_bar.get_tab_count()).is_equal(2)
	_bar.remove_tab("sh_1")
	assert_int(_bar.get_tab_count()).is_equal(1)


## get_active_shell_id() returns "" before any tab is focused.
func test_get_active_shell_id_default() -> void:
	assert_str(_bar.get_active_shell_id()).is_equal("")


## get_active_shell_id() returns the shell_id of the most recently focused tab.
func test_get_active_shell_id_after_focus() -> void:
	_bar.add_tab("sh_a", "bash")
	_bar.add_tab("sh_b", "zsh")
	_bar.focus_tab("sh_b")
	assert_str(_bar.get_active_shell_id()).is_equal("sh_b")


## next_tab() with no active tab focuses the first tab in insertion order.
func test_next_tab_cycles_to_second() -> void:
	_bar.add_tab("sh_1", "bash")
	_bar.add_tab("sh_2", "zsh")
	_bar.focus_tab("sh_1")
	_focus_count = 0
	_bar.next_tab()
	assert_str(_last_focused).is_equal("sh_2")
	assert_int(_focus_count).is_equal(1)


## next_tab() wraps from the last tab back to the first.
func test_next_tab_wraps_around() -> void:
	_bar.add_tab("sh_1", "bash")
	_bar.add_tab("sh_2", "zsh")
	_bar.focus_tab("sh_2")
	_focus_count = 0
	_bar.next_tab()
	assert_str(_last_focused).is_equal("sh_1")
	assert_int(_focus_count).is_equal(1)


## next_tab() with a single tab still emits tab_focused (stays on same tab).
func test_next_tab_single_tab() -> void:
	_bar.add_tab("only", "bash")
	_bar.focus_tab("only")
	_focus_count = 0
	_bar.next_tab()
	assert_str(_last_focused).is_equal("only")
	assert_int(_focus_count).is_equal(1)


## next_tab() emits tab_focused with the next shell_id.
func test_next_tab_emits_tab_focused() -> void:
	_bar.add_tab("first", "bash")
	_bar.add_tab("second", "zsh")
	_bar.add_tab("third", "sh")
	_bar.focus_tab("first")
	_focus_count = 0
	_bar.next_tab()
	assert_str(_last_focused).is_equal("second")
	_bar.next_tab()
	assert_str(_last_focused).is_equal("third")
	_bar.next_tab()
	assert_str(_last_focused).is_equal("first")
	assert_int(_focus_count).is_equal(3)


## next_tab() is a no-op when no tabs have been added.
func test_next_tab_no_tabs() -> void:
	_bar.next_tab()
	assert_int(_focus_count).is_equal(0)
	assert_str(_last_focused).is_equal("")
