# GdUnit4 test: SignalBus round-trip and disconnect coverage.
#
# Spec: .ralph/specs/0003-unit-test-coverage.md  (task 0.4.3)
#
# The existing signal_bus_connectivity_test.gd covers signal arity and the
# command_submitted round-trip. This file adds round-trip tests for the four
# remaining signals and verifies that disconnect prevents further calls.
#
# Note: monitor_signals is intentionally avoided -- it corrupts autoload
# singletons in GdUnit4 v6.1.x (see .ralph/learnings/INDEX.md).
extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# output_ready
# ---------------------------------------------------------------------------


func test_output_ready_round_trip() -> void:
	var received: Array[String] = []
	var cb := func(text: String) -> void: received.append(text)
	SignalBus.output_ready.connect(cb)
	SignalBus.output_ready.emit("hello world")
	SignalBus.output_ready.disconnect(cb)
	assert_array(received).is_equal(["hello world"])


# ---------------------------------------------------------------------------
# terminal_cleared
# ---------------------------------------------------------------------------


func test_terminal_cleared_round_trip() -> void:
	var fired: Array[bool] = [false]
	var cb := func() -> void: fired[0] = true
	SignalBus.terminal_cleared.connect(cb)
	SignalBus.terminal_cleared.emit()
	SignalBus.terminal_cleared.disconnect(cb)
	assert_bool(fired[0]).is_true()


# ---------------------------------------------------------------------------
# addon_status_changed
# ---------------------------------------------------------------------------


func test_addon_status_changed_round_trip_true() -> void:
	var states: Array[bool] = []
	var cb := func(available: bool) -> void: states.append(available)
	SignalBus.addon_status_changed.connect(cb)
	SignalBus.addon_status_changed.emit(true)
	SignalBus.addon_status_changed.disconnect(cb)
	assert_array(states).is_equal([true])


func test_addon_status_changed_round_trip_false() -> void:
	var states: Array[bool] = []
	var cb := func(available: bool) -> void: states.append(available)
	SignalBus.addon_status_changed.connect(cb)
	SignalBus.addon_status_changed.emit(false)
	SignalBus.addon_status_changed.disconnect(cb)
	assert_array(states).is_equal([false])


# ---------------------------------------------------------------------------
# shell_status_changed
# ---------------------------------------------------------------------------


func test_shell_status_changed_round_trip_running() -> void:
	var states: Array[bool] = []
	var cb := func(running: bool) -> void: states.append(running)
	SignalBus.shell_status_changed.connect(cb)
	SignalBus.shell_status_changed.emit(true)
	SignalBus.shell_status_changed.disconnect(cb)
	assert_array(states).is_equal([true])


func test_shell_status_changed_round_trip_stopped() -> void:
	var states: Array[bool] = []
	var cb := func(running: bool) -> void: states.append(running)
	SignalBus.shell_status_changed.connect(cb)
	SignalBus.shell_status_changed.emit(false)
	SignalBus.shell_status_changed.disconnect(cb)
	assert_array(states).is_equal([false])


# ---------------------------------------------------------------------------
# disconnect prevents further calls
# ---------------------------------------------------------------------------


func test_disconnect_prevents_output_ready_calls() -> void:
	var count: Array[int] = [0]
	var cb := func(_text: String) -> void: count[0] += 1
	SignalBus.output_ready.connect(cb)
	SignalBus.output_ready.emit("first")
	SignalBus.output_ready.disconnect(cb)
	SignalBus.output_ready.emit("second")
	assert_int(count[0]).is_equal(1)


func test_disconnect_prevents_shell_status_calls() -> void:
	var count: Array[int] = [0]
	var cb := func(_running: bool) -> void: count[0] += 1
	SignalBus.shell_status_changed.connect(cb)
	SignalBus.shell_status_changed.emit(true)
	SignalBus.shell_status_changed.disconnect(cb)
	SignalBus.shell_status_changed.emit(false)
	assert_int(count[0]).is_equal(1)


# ---------------------------------------------------------------------------
# Multiple listeners fire independently
# ---------------------------------------------------------------------------


func test_multiple_listeners_both_called() -> void:
	var a: Array[String] = []
	var b: Array[String] = []
	var cb_a := func(text: String) -> void: a.append(text)
	var cb_b := func(text: String) -> void: b.append(text)
	SignalBus.output_ready.connect(cb_a)
	SignalBus.output_ready.connect(cb_b)
	SignalBus.output_ready.emit("ping")
	SignalBus.output_ready.disconnect(cb_a)
	SignalBus.output_ready.disconnect(cb_b)
	assert_array(a).is_equal(["ping"])
	assert_array(b).is_equal(["ping"])


func test_multiple_listeners_can_be_removed_independently() -> void:
	var a: Array[String] = []
	var b: Array[String] = []
	var cb_a := func(text: String) -> void: a.append(text)
	var cb_b := func(text: String) -> void: b.append(text)
	SignalBus.output_ready.connect(cb_a)
	SignalBus.output_ready.connect(cb_b)
	SignalBus.output_ready.emit("first")
	SignalBus.output_ready.disconnect(cb_a)
	SignalBus.output_ready.emit("second")
	SignalBus.output_ready.disconnect(cb_b)
	assert_array(a).is_equal(["first"])
	assert_array(b).is_equal(["first", "second"])
