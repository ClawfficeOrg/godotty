## GdUnit4 tests: Ctrl+T / Ctrl+W / Ctrl+Tab tab keybindings (task 3.0.3).
##
## Spec: docs/todo-v3.md (task 3.0.3)
##
## Covers:
##   1. test_ctrl_t_emits_tab_new_requested      — Ctrl+T dispatches tab_new_requested.
##   2. test_ctrl_w_emits_tab_close_requested     — Ctrl+W dispatches tab_close_requested.
##   3. test_ctrl_tab_emits_tab_next_requested    — Ctrl+Tab dispatches tab_next_requested.
##   4. test_remap_new_tab_binding               — remap new_tab; new key works, old does not.
##   5. test_remap_close_tab_binding             — remap close_tab; new key works, old does not.
##   6. test_default_new_tab_binding_is_ctrl_t   — default binding is Ctrl+T (no shift).
##   7. test_default_close_tab_binding_is_ctrl_w — default binding is Ctrl+W (no shift).
##   8. test_default_next_tab_binding_is_ctrl_tab — default binding is Ctrl+Tab.
##
## All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _original_keymap: TerminalKeymap

var _tab_new_count: int = 0
var _tab_close_count: int = 0
var _tab_next_count: int = 0


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()
	_original_keymap = TerminalManager.keymap
	TerminalManager.keymap = TerminalKeymap.default()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)
	_tab_new_count = 0
	_tab_close_count = 0
	_tab_next_count = 0
	_view.tab_new_requested.connect(_on_tab_new_requested)
	_view.tab_close_requested.connect(_on_tab_close_requested)
	_view.tab_next_requested.connect(_on_tab_next_requested)


func after_test() -> void:
	if is_instance_valid(_view):
		if _view.tab_new_requested.is_connected(_on_tab_new_requested):
			_view.tab_new_requested.disconnect(_on_tab_new_requested)
		if _view.tab_close_requested.is_connected(_on_tab_close_requested):
			_view.tab_close_requested.disconnect(_on_tab_close_requested)
		if _view.tab_next_requested.is_connected(_on_tab_next_requested):
			_view.tab_next_requested.disconnect(_on_tab_next_requested)
		_view.queue_free()
	_view = null
	TerminalManager.keymap = _original_keymap
	_original_keymap = null


func _on_tab_new_requested() -> void:
	_tab_new_count += 1


func _on_tab_close_requested() -> void:
	_tab_close_count += 1


func _on_tab_next_requested() -> void:
	_tab_next_count += 1


func _make_key_event(keycode: Key, ctrl: bool, shift: bool = false) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	ev.ctrl_pressed = ctrl
	ev.shift_pressed = shift
	return ev


## Default new_tab binding is Ctrl+T (no shift).
func test_default_new_tab_binding_is_ctrl_t() -> void:
	var ev: InputEventKey = TerminalManager.keymap.bindings[TerminalKeymap.ACTION_NEW_TAB]
	assert_bool(ev.keycode == KEY_T).is_true()
	assert_bool(ev.ctrl_pressed).is_true()
	assert_bool(ev.shift_pressed).is_false()


## Default close_tab binding is Ctrl+W (no shift).
func test_default_close_tab_binding_is_ctrl_w() -> void:
	var ev: InputEventKey = TerminalManager.keymap.bindings[TerminalKeymap.ACTION_CLOSE_TAB]
	assert_bool(ev.keycode == KEY_W).is_true()
	assert_bool(ev.ctrl_pressed).is_true()
	assert_bool(ev.shift_pressed).is_false()


## Default next_tab binding is Ctrl+Tab (no shift).
func test_default_next_tab_binding_is_ctrl_tab() -> void:
	var ev: InputEventKey = TerminalManager.keymap.bindings[TerminalKeymap.ACTION_NEXT_TAB]
	assert_bool(ev.keycode == KEY_TAB).is_true()
	assert_bool(ev.ctrl_pressed).is_true()
	assert_bool(ev.shift_pressed).is_false()


## Ctrl+T emits tab_new_requested signal from TerminalView.
func test_ctrl_t_emits_tab_new_requested() -> void:
	_view._input(_make_key_event(KEY_T, true))
	assert_int(_tab_new_count).is_equal(1)
	assert_int(_tab_close_count).is_equal(0)
	assert_int(_tab_next_count).is_equal(0)


## Ctrl+W emits tab_close_requested signal from TerminalView.
func test_ctrl_w_emits_tab_close_requested() -> void:
	_view._input(_make_key_event(KEY_W, true))
	assert_int(_tab_close_count).is_equal(1)
	assert_int(_tab_new_count).is_equal(0)
	assert_int(_tab_next_count).is_equal(0)


## Ctrl+Tab emits tab_next_requested signal from TerminalView.
func test_ctrl_tab_emits_tab_next_requested() -> void:
	_view._input(_make_key_event(KEY_TAB, true))
	assert_int(_tab_next_count).is_equal(1)
	assert_int(_tab_new_count).is_equal(0)
	assert_int(_tab_close_count).is_equal(0)


## Rebinding new_tab to Ctrl+N: new key fires signal, old Ctrl+T does not.
func test_remap_new_tab_binding() -> void:
	var new_key := InputEventKey.new()
	new_key.keycode = KEY_N
	new_key.ctrl_pressed = true
	TerminalManager.keymap.bindings[TerminalKeymap.ACTION_NEW_TAB] = new_key

	_view._input(_make_key_event(KEY_N, true))
	assert_int(_tab_new_count).is_equal(1)

	_view._input(_make_key_event(KEY_T, true))
	assert_int(_tab_new_count).is_equal(1)


## Rebinding close_tab to Ctrl+Shift+W: new key fires signal, old Ctrl+W does not.
func test_remap_close_tab_binding() -> void:
	var new_key := InputEventKey.new()
	new_key.keycode = KEY_W
	new_key.ctrl_pressed = true
	new_key.shift_pressed = true
	TerminalManager.keymap.bindings[TerminalKeymap.ACTION_CLOSE_TAB] = new_key

	_view._input(_make_key_event(KEY_W, true, true))
	assert_int(_tab_close_count).is_equal(1)

	_view._input(_make_key_event(KEY_W, true))
	assert_int(_tab_close_count).is_equal(1)
