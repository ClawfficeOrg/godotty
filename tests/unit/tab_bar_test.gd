## GdUnit4 tests: TerminalTabBar node — add/close tabs, indicator, title (task 3.0.2).
##
## Spec: docs/todo-v3.md (task 3.0.2)
##
## Covers:
##   1. tab_shows_shell_name          — label reflects the provided title.
##   2. add_button_emits_new_tab      — + button emits new_tab_requested.
##   3. close_button_emits_tab_close  — close button emits tab_close_requested.
##   4. indicator_on_output           — notify_output sets indicator on inactive tab.
##   5. indicator_clears_on_focus     — focus_tab clears the indicator.
##   6. tab_removed_on_close          — remove_tab removes entry from _tabs.
##   7. close_signal_disconnected     — disconnect uses same Callable (no leak).
##
## All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite

const TAB_BAR_SCENE := preload("res://scenes/tab_bar.tscn")

var _bar: TerminalTabBar

var _last_signal: String = ""
var _last_shell_id: String = ""
var _signal_count: int = 0


func before_test() -> void:
	_bar = TAB_BAR_SCENE.instantiate() as TerminalTabBar
	add_child(_bar)
	_last_signal = ""
	_last_shell_id = ""
	_signal_count = 0
	_bar.new_tab_requested.connect(_on_new_tab_requested)
	_bar.tab_close_requested.connect(_on_tab_close_requested)
	_bar.tab_focused.connect(_on_tab_focused)


func after_test() -> void:
	if is_instance_valid(_bar):
		_bar.new_tab_requested.disconnect(_on_new_tab_requested)
		if _bar.tab_close_requested.is_connected(_on_tab_close_requested):
			_bar.tab_close_requested.disconnect(_on_tab_close_requested)
		if _bar.tab_focused.is_connected(_on_tab_focused):
			_bar.tab_focused.disconnect(_on_tab_focused)
		_bar.queue_free()
	_bar = null


func _on_new_tab_requested() -> void:
	_last_signal = "new_tab_requested"
	_signal_count += 1


func _on_tab_close_requested(shell_id: String) -> void:
	_last_signal = "tab_close_requested"
	_last_shell_id = shell_id
	_signal_count += 1


func _on_tab_focused(shell_id: String) -> void:
	_last_signal = "tab_focused"
	_last_shell_id = shell_id
	_signal_count += 1


## Tab label reflects the title passed to add_tab.
func test_tab_shows_shell_name() -> void:
	_bar.add_tab("sh_1", "mybash")
	var btn: TerminalTabButton = _bar._tabs["sh_1"] as TerminalTabButton
	assert_str(btn._label.text).is_equal("mybash")


## add_tab with an empty title falls back to TerminalTabBar.DEFAULT_TITLE.
func test_tab_falls_back_to_default_when_title_empty() -> void:
	_bar.add_tab("sh_2", "")
	var btn: TerminalTabButton = _bar._tabs["sh_2"] as TerminalTabButton
	assert_str(btn._label.text).is_equal(TerminalTabBar.DEFAULT_TITLE)


## set_tab_title updates the label on an existing tab.
func test_set_tab_title_updates_label() -> void:
	_bar.add_tab("sh_3", "bash")
	_bar.set_tab_title("sh_3", "vim")
	var btn: TerminalTabButton = _bar._tabs["sh_3"] as TerminalTabButton
	assert_str(btn._label.text).is_equal("vim")


## Pressing the + (add) button emits new_tab_requested.
func test_add_button_emits_new_tab_requested() -> void:
	_bar._add_button.pressed.emit()
	assert_str(_last_signal).is_equal("new_tab_requested")
	assert_int(_signal_count).is_equal(1)


## Pressing a tab's close button emits tab_close_requested with the correct id.
func test_close_button_emits_tab_close_requested() -> void:
	_bar.add_tab("sh_4", "zsh")
	var btn: TerminalTabButton = _bar._tabs["sh_4"] as TerminalTabButton
	btn._on_close_pressed()
	assert_str(_last_signal).is_equal("tab_close_requested")
	assert_str(_last_shell_id).is_equal("sh_4")


## notify_output sets the indicator visible on an inactive tab.
func test_indicator_toggles_on_output_since_last_focus() -> void:
	_bar.add_tab("sh_5", "bash")
	_bar.add_tab("sh_6", "zsh")
	_bar.focus_tab("sh_6")
	_bar.notify_output("sh_5")
	var btn5: TerminalTabButton = _bar._tabs["sh_5"] as TerminalTabButton
	assert_bool(btn5._indicator.visible).is_true()


## notify_output does NOT set the indicator on the currently active tab.
func test_indicator_not_set_on_active_tab() -> void:
	_bar.add_tab("sh_7", "bash")
	_bar.focus_tab("sh_7")
	_bar.notify_output("sh_7")
	var btn7: TerminalTabButton = _bar._tabs["sh_7"] as TerminalTabButton
	assert_bool(btn7._indicator.visible).is_false()


## focus_tab clears the indicator on the newly focused tab.
func test_indicator_clears_on_focus() -> void:
	_bar.add_tab("sh_8", "bash")
	# manually set indicator as if output arrived before first focus
	(_bar._tabs["sh_8"] as TerminalTabButton).set_indicator(true)
	_bar.focus_tab("sh_8")
	var btn8: TerminalTabButton = _bar._tabs["sh_8"] as TerminalTabButton
	assert_bool(btn8._indicator.visible).is_false()


## focus_tab emits tab_focused.
func test_focus_tab_emits_tab_focused() -> void:
	_bar.add_tab("sh_9", "bash")
	_bar.focus_tab("sh_9")
	assert_str(_last_signal).is_equal("tab_focused")
	assert_str(_last_shell_id).is_equal("sh_9")


## remove_tab removes the entry from _tabs.
func test_tab_removed_on_terminal_close() -> void:
	_bar.add_tab("sh_10", "bash")
	assert_bool(_bar._tabs.has("sh_10")).is_true()
	_bar.remove_tab("sh_10")
	assert_bool(_bar._tabs.has("sh_10")).is_false()


## After remove_tab, the TerminalTabButton's signals are disconnected (no Callable leak).
func test_close_signal_disconnected_on_remove() -> void:
	_bar.add_tab("sh_11", "bash")
	var btn: TerminalTabButton = _bar._tabs["sh_11"] as TerminalTabButton
	var before: int = btn.close_requested.get_connections().size()
	_bar.remove_tab("sh_11")
	# btn is queue_free()d but still valid within this frame
	var after: int = btn.close_requested.get_connections().size()
	assert_int(before).is_equal(1)
	assert_int(after).is_equal(0)
