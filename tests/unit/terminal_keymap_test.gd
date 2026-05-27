## GdUnit4 tests for TerminalKeymap resource (task 2.3.1).
##
## Spec: docs/todo-v2.md (task 2.3.1)
##
## Covers:
##   - All twelve built-in actions are present in the default keymap.
##   - Default interrupt binding is Ctrl+C; eof is Ctrl+D.
##   - Rebinding the copy action updates the bindings dictionary.
##   - find_action() resolves the correct action for a matching key event.
##   - find_action() returns "" for an unbound key event.
extends GdUnitTestSuite

var _keymap: TerminalKeymap


func before_test() -> void:
	_keymap = TerminalKeymap.default()


func after_test() -> void:
	_keymap = null


## All twelve built-in action names are present in the default keymap.
func test_default_bindings_present() -> void:
	for action: String in TerminalKeymap.BUILTIN_ACTIONS:
		assert_bool(_keymap.bindings.has(action)).is_true()


## Default interrupt binding is Ctrl+C (no shift, no alt).
func test_default_interrupt_is_ctrl_c() -> void:
	var ev: InputEventKey = _keymap.bindings[TerminalKeymap.ACTION_INTERRUPT]
	assert_bool(ev.keycode == KEY_C).is_true()
	assert_bool(ev.ctrl_pressed).is_true()
	assert_bool(ev.shift_pressed).is_false()
	assert_bool(ev.alt_pressed).is_false()


## Default eof binding is Ctrl+D (no shift, no alt).
func test_default_eof_is_ctrl_d() -> void:
	var ev: InputEventKey = _keymap.bindings[TerminalKeymap.ACTION_EOF]
	assert_bool(ev.keycode == KEY_D).is_true()
	assert_bool(ev.ctrl_pressed).is_true()
	assert_bool(ev.shift_pressed).is_false()
	assert_bool(ev.alt_pressed).is_false()


## Rebinding copy to a new InputEventKey updates bindings[ACTION_COPY].
func test_rebind_copy_action() -> void:
	var new_key := InputEventKey.new()
	new_key.keycode = KEY_INSERT
	new_key.ctrl_pressed = true
	_keymap.bindings[TerminalKeymap.ACTION_COPY] = new_key
	var bound: InputEventKey = _keymap.bindings[TerminalKeymap.ACTION_COPY]
	assert_bool(bound.keycode == KEY_INSERT).is_true()
	assert_bool(bound.ctrl_pressed).is_true()


## find_action() returns the correct action name for a matching key event.
func test_find_action_resolves_interrupt() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_C
	ev.ctrl_pressed = true
	ev.shift_pressed = false
	ev.alt_pressed = false
	assert_str(_keymap.find_action(ev)).is_equal(TerminalKeymap.ACTION_INTERRUPT)


## find_action() returns "" when the event matches no binding.
func test_find_action_returns_empty_for_unbound_key() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_Z
	ev.ctrl_pressed = false
	assert_str(_keymap.find_action(ev)).is_equal("")


## find_action() resolves copy action after rebinding it to a new key.
func test_find_action_fires_on_new_key_after_rebind() -> void:
	var new_key := InputEventKey.new()
	new_key.keycode = KEY_INSERT
	new_key.ctrl_pressed = true
	_keymap.bindings[TerminalKeymap.ACTION_COPY] = new_key
	var ev := InputEventKey.new()
	ev.keycode = KEY_INSERT
	ev.ctrl_pressed = true
	ev.shift_pressed = false
	ev.alt_pressed = false
	ev.meta_pressed = false
	assert_str(_keymap.find_action(ev)).is_equal(TerminalKeymap.ACTION_COPY)
