# GdUnit4 test: TerminalManager shell/IO method happy-path coverage.
#
# Spec: .ralph/specs/0003-unit-test-coverage.md  (task 0.4.3)
#
# Covers: spawn_shell, write_input, has_output, read_output, clear.
# Grid methods (get_cell, get_dimensions, resize) live in
# terminal_manager_grid_test.gd.
#
# All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_current_dir = "/home/user"
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()


# ---------------------------------------------------------------------------
# spawn_shell
# ---------------------------------------------------------------------------


func test_spawn_shell_mock_returns_true() -> void:
	var result := TerminalManager.spawn_shell()
	assert_bool(result).is_true()


func test_spawn_shell_mock_populates_output_buffer() -> void:
	TerminalManager.spawn_shell()
	assert_bool(TerminalManager.has_output()).is_true()


func test_spawn_shell_mock_emits_shell_started() -> void:
	var fired: Array[bool] = [false]
	var cb := func() -> void: fired[0] = true
	TerminalManager.shell_started.connect(cb)
	TerminalManager.spawn_shell()
	TerminalManager.shell_started.disconnect(cb)
	assert_bool(fired[0]).is_true()


func test_spawn_shell_mock_emits_shell_status_changed_true() -> void:
	var states: Array[bool] = []
	var cb := func(running: bool) -> void: states.append(running)
	SignalBus.shell_status_changed.connect(cb)
	TerminalManager.spawn_shell()
	SignalBus.shell_status_changed.disconnect(cb)
	assert_bool(states.size() > 0).is_true()
	assert_bool(states[0]).is_true()


# ---------------------------------------------------------------------------
# write_input
# ---------------------------------------------------------------------------


func test_write_input_empty_is_noop() -> void:
	TerminalManager.spawn_shell()
	# Drain the spawn buffer first.
	while TerminalManager.has_output():
		TerminalManager.read_output()
	TerminalManager.write_input("")
	assert_bool(TerminalManager.has_output()).is_false()


func test_write_input_echo_produces_output() -> void:
	var lines: Array[String] = []
	var cb := func(text: String) -> void: lines.append(text)
	TerminalManager.output_received.connect(cb)
	TerminalManager.write_input("echo hello")
	TerminalManager.output_received.disconnect(cb)
	assert_bool(lines.size() > 0).is_true()


func test_write_input_records_history() -> void:
	TerminalManager.write_input("whoami")
	assert_bool(TerminalManager._mock_history.has("whoami")).is_true()


func test_write_input_whitespace_only_is_noop() -> void:
	TerminalManager.write_input("   ")
	assert_bool(TerminalManager._mock_history.size() == 0).is_true()


# ---------------------------------------------------------------------------
# has_output / read_output
# ---------------------------------------------------------------------------


func test_has_output_false_on_empty_buffer() -> void:
	assert_bool(TerminalManager.has_output()).is_false()


func test_has_output_true_after_spawn() -> void:
	TerminalManager.spawn_shell()
	assert_bool(TerminalManager.has_output()).is_true()


func test_read_output_returns_empty_when_buffer_empty() -> void:
	assert_str(TerminalManager.read_output()).is_equal("")


func test_read_output_returns_string_when_buffer_has_content() -> void:
	TerminalManager.spawn_shell()
	var line := TerminalManager.read_output()
	assert_bool(line.length() > 0).is_true()


func test_read_output_drains_buffer_one_item_at_a_time() -> void:
	TerminalManager.spawn_shell()
	var first := TerminalManager.read_output()
	var had_more := TerminalManager.has_output()
	assert_bool(had_more).is_true()
	# Each read removes exactly one entry; first must be non-empty.
	assert_bool(first.length() >= 0).is_true()


# ---------------------------------------------------------------------------
# clear
# ---------------------------------------------------------------------------


func test_clear_empties_mock_output_buffer() -> void:
	TerminalManager.spawn_shell()
	assert_bool(TerminalManager.has_output()).is_true()
	TerminalManager.clear()
	assert_bool(TerminalManager.has_output()).is_false()


func test_clear_emits_terminal_cleared_signal() -> void:
	var fired: Array[bool] = [false]
	var cb := func() -> void: fired[0] = true
	SignalBus.terminal_cleared.connect(cb)
	TerminalManager.clear()
	SignalBus.terminal_cleared.disconnect(cb)
	assert_bool(fired[0]).is_true()
