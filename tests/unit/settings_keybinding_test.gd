## GdUnit4 tests: keybinding editor panel (task 2.3.3).
##
## Spec: docs/todo-v2.md (task 2.3.3)
##
## Covers:
##   - Settings dialog instantiates and lists all built-in action rows.
##   - Clicking Edit then pressing F5 rebinds the action to F5.
##   - save_keymap() writes user://keymap.tres; load_keymap() restores it.
##   - When user://keymap.tres is absent, load_keymap() installs the defaults.
##   - Rebinding "copy" via the UI and saving survives a simulated restart.
##
## All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite

const SETTINGS_SCENE := preload("res://scenes/settings_dialog.tscn")
const KEYMAP_PATH: String = "user://keymap.tres"

var _dialog: SettingsDialog
var _original_keymap: TerminalKeymap


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	_original_keymap = TerminalManager.keymap
	TerminalManager.keymap = TerminalKeymap.default()
	_remove_keymap_file()
	_dialog = SETTINGS_SCENE.instantiate() as SettingsDialog
	add_child(_dialog)


func after_test() -> void:
	if is_instance_valid(_dialog):
		_dialog.queue_free()
	_dialog = null
	TerminalManager.keymap = _original_keymap
	_original_keymap = null
	_remove_keymap_file()


func _remove_keymap_file() -> void:
	if ResourceLoader.exists(KEYMAP_PATH):
		var dir: DirAccess = DirAccess.open("user://")
		if dir != null:
			dir.remove("keymap.tres")


func _make_key_event(keycode: Key, ctrl: bool = false, shift: bool = false) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	ev.ctrl_pressed = ctrl
	ev.shift_pressed = shift
	return ev


# ---------------------------------------------------------------------------
# Row population
# ---------------------------------------------------------------------------


## Settings dialog creates a row for every built-in action.
func test_settings_shows_action_rows() -> void:
	var count: int = _dialog._rows_container.get_child_count()
	assert_int(count).is_equal(TerminalKeymap.BUILTIN_ACTIONS.size())


# ---------------------------------------------------------------------------
# Edit capture
# ---------------------------------------------------------------------------


## Clicking Edit then pressing F5 rebinds the action to F5.
func test_click_edit_and_press_f5_binds_action() -> void:
	_dialog._on_edit_pressed(TerminalKeymap.ACTION_COPY)
	_dialog._input(_make_key_event(KEY_F5))
	var bound: InputEventKey = TerminalManager.keymap.bindings[TerminalKeymap.ACTION_COPY]
	assert_bool(bound.keycode == KEY_F5).is_true()
	assert_bool(bound.ctrl_pressed).is_false()
	assert_bool(bound.shift_pressed).is_false()


## After capture the dialog stops capturing (second key press is ignored).
func test_capturing_resets_after_one_key() -> void:
	_dialog._on_edit_pressed(TerminalKeymap.ACTION_COPY)
	_dialog._input(_make_key_event(KEY_F5))
	# A second key press should NOT overwrite the binding.
	_dialog._input(_make_key_event(KEY_F6))
	var bound: InputEventKey = TerminalManager.keymap.bindings[TerminalKeymap.ACTION_COPY]
	assert_bool(bound.keycode == KEY_F5).is_true()


## Bare modifier-only key events are ignored during capture.
func test_modifier_only_keypress_is_ignored() -> void:
	_dialog._on_edit_pressed(TerminalKeymap.ACTION_COPY)
	_dialog._input(_make_key_event(KEY_CTRL, true))
	# Still capturing — binding unchanged from default (Ctrl+Shift+C).
	var bound: InputEventKey = TerminalManager.keymap.bindings[TerminalKeymap.ACTION_COPY]
	assert_bool(bound.keycode == KEY_C).is_true()
	assert_bool(bound.shift_pressed).is_true()


# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------


## save_keymap() writes user://keymap.tres; load_keymap() restores the binding.
func test_save_writes_user_keymap_and_persists() -> void:
	_dialog._on_edit_pressed(TerminalKeymap.ACTION_COPY)
	_dialog._input(_make_key_event(KEY_F5))
	_dialog.save_keymap()
	# Simulate a fresh start by resetting the in-memory keymap.
	TerminalManager.keymap = TerminalKeymap.default()
	_dialog.load_keymap()
	var bound: InputEventKey = TerminalManager.keymap.bindings[TerminalKeymap.ACTION_COPY]
	assert_bool(bound.keycode == KEY_F5).is_true()


## When user://keymap.tres is absent, load_keymap() installs the default keymap.
func test_missing_user_keymap_loads_default() -> void:
	# Mutate the in-memory keymap so we can tell if it was replaced.
	var custom_key := InputEventKey.new()
	custom_key.keycode = KEY_Z
	TerminalManager.keymap.bindings[TerminalKeymap.ACTION_COPY] = custom_key
	# No file on disk — load_keymap() must reset to default.
	_dialog.load_keymap()
	var bound: InputEventKey = TerminalManager.keymap.bindings[TerminalKeymap.ACTION_COPY]
	assert_bool(bound.keycode == KEY_C).is_true()
	assert_bool(bound.ctrl_pressed).is_true()
	assert_bool(bound.shift_pressed).is_true()


## Rebinding "copy" via the UI, saving, then reloading restores the custom key.
## This is the release-gate test for 2.3.0.
func test_rebind_copy_survives_restart() -> void:
	_dialog._on_edit_pressed(TerminalKeymap.ACTION_COPY)
	_dialog._input(_make_key_event(KEY_F8))
	_dialog.save_keymap()
	# Simulate a game restart: reset to default, then reload from user://.
	TerminalManager.keymap = TerminalKeymap.default()
	_dialog.load_keymap()
	var bound: InputEventKey = TerminalManager.keymap.bindings[TerminalKeymap.ACTION_COPY]
	assert_bool(bound.keycode == KEY_F8).is_true()
