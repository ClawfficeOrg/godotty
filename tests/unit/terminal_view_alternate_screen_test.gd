# GdUnit4 test: TerminalView alternate screen buffer switching.
#
# Spec: docs/todo-v1.md (task 1.0.2)
#
# Covers: CSI ?47h/l, ?1047h/l, ?1049h/l sequences emitted via
# SignalBus.output_ready; asserts buffer-switch flag and content
# isolation / restoration semantics.
#
# All tests run in mock mode -- no GDExtension required.
# Note: monitor_signals is NOT used on autoloads (see learnings INDEX).
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# ?1049h / ?1049l -- enter/exit with primary buffer save and restore
# ---------------------------------------------------------------------------


func test_enter_1049_sets_alternate_flag() -> void:
	SignalBus.output_ready.emit("\u001b[?1049h")
	assert_bool(_view._in_alternate_screen).is_true()


func test_exit_1049_clears_alternate_flag() -> void:
	SignalBus.output_ready.emit("\u001b[?1049h")
	SignalBus.output_ready.emit("\u001b[?1049l")
	assert_bool(_view._in_alternate_screen).is_false()


func test_enter_1049_clears_display() -> void:
	SignalBus.output_ready.emit("primary text\n")
	assert_bool(_view.output_display.get_parsed_text().contains("primary text")).is_true()
	SignalBus.output_ready.emit("\u001b[?1049h")
	assert_bool(_view.output_display.get_parsed_text().contains("primary text")).is_false()


func test_exit_1049_restores_primary_content() -> void:
	SignalBus.output_ready.emit("primary text\n")
	SignalBus.output_ready.emit("\u001b[?1049h")
	SignalBus.output_ready.emit("alternate content\n")
	SignalBus.output_ready.emit("\u001b[?1049l")
	assert_bool(_view.output_display.get_parsed_text().contains("primary text")).is_true()


func test_exit_1049_removes_alternate_content() -> void:
	SignalBus.output_ready.emit("primary text\n")
	SignalBus.output_ready.emit("\u001b[?1049h")
	SignalBus.output_ready.emit("alternate content\n")
	SignalBus.output_ready.emit("\u001b[?1049l")
	assert_bool(_view.output_display.get_parsed_text().contains("alternate content")).is_false()


# ---------------------------------------------------------------------------
# ?47h / ?47l -- enter/exit without save/restore
# ---------------------------------------------------------------------------


func test_enter_47_sets_alternate_flag() -> void:
	SignalBus.output_ready.emit("\u001b[?47h")
	assert_bool(_view._in_alternate_screen).is_true()


func test_exit_47_clears_alternate_flag() -> void:
	SignalBus.output_ready.emit("\u001b[?47h")
	SignalBus.output_ready.emit("\u001b[?47l")
	assert_bool(_view._in_alternate_screen).is_false()


func test_exit_47_does_not_restore_primary() -> void:
	SignalBus.output_ready.emit("primary text\n")
	SignalBus.output_ready.emit("\u001b[?47h")
	SignalBus.output_ready.emit("\u001b[?47l")
	# ?47 has no save/restore -- display is empty after exit
	assert_bool(_view.output_display.get_parsed_text().contains("primary text")).is_false()


# ---------------------------------------------------------------------------
# ?1047h / ?1047l -- treated like ?47 (no save/restore)
# ---------------------------------------------------------------------------


func test_enter_1047_sets_alternate_flag() -> void:
	SignalBus.output_ready.emit("\u001b[?1047h")
	assert_bool(_view._in_alternate_screen).is_true()


func test_exit_1047_clears_alternate_flag() -> void:
	SignalBus.output_ready.emit("\u001b[?1047h")
	SignalBus.output_ready.emit("\u001b[?1047l")
	assert_bool(_view._in_alternate_screen).is_false()


# ---------------------------------------------------------------------------
# Partial escape sequence split across two output_ready emissions
# ---------------------------------------------------------------------------


func test_partial_escape_split_enter_1049() -> void:
	SignalBus.output_ready.emit("\u001b[?10")
	assert_bool(_view._in_alternate_screen).is_false()
	SignalBus.output_ready.emit("49h")
	assert_bool(_view._in_alternate_screen).is_true()


func test_partial_escape_split_exit_1049() -> void:
	SignalBus.output_ready.emit("\u001b[?1049h")
	SignalBus.output_ready.emit("\u001b[?10")
	assert_bool(_view._in_alternate_screen).is_true()
	SignalBus.output_ready.emit("49l")
	assert_bool(_view._in_alternate_screen).is_false()


# ---------------------------------------------------------------------------
# Scroll to bottom called on restore (flag verifies restore path was taken)
# ---------------------------------------------------------------------------


func test_scroll_to_bottom_on_restore() -> void:
	SignalBus.output_ready.emit("scroll test\n")
	SignalBus.output_ready.emit("\u001b[?1049h")
	assert_bool(_view._in_alternate_screen).is_true()
	SignalBus.output_ready.emit("\u001b[?1049l")
	assert_bool(_view._in_alternate_screen).is_false()
	assert_bool(_view.output_display.get_parsed_text().contains("scroll test")).is_true()
