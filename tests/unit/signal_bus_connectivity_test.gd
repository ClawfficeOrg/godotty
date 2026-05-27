# GdUnit4 test: SignalBus exposes the expected signals with the
# expected arity / argument names.
#
# Spec: .ralph/specs/0002-gdunit4-test-harness.md
#
# These contracts are referenced from `TerminalManager` and `TerminalView`,
# so any rename or arity change here must break this test loudly.
#
# Note: We deliberately avoid `monitor_signals` against the SignalBus
# autoload. In GdUnit4 v6.1.x the signal monitor expects to be able to
# free the watched object between tests, which corrupts the autoload
# singleton. Contract-shape checks via `get_signal_list` cover the
# regression risk we care about (rename/arity drift) without that
# fragility.
extends GdUnitTestSuite


# Helper: returns the argument-name array for a named signal, or [] if
# the signal is missing.
func _signal_arg_names(bus: Node, signal_name: String) -> Array:
	for sig in bus.get_signal_list():
		if sig.name == signal_name:
			var names: Array = []
			for arg in sig.args:
				names.append(arg.name)
			return names
	return []


func test_command_submitted_arity() -> void:
	assert_bool(SignalBus.has_signal("command_submitted")).is_true()
	assert_array(_signal_arg_names(SignalBus, "command_submitted")).is_equal(["command"])


func test_output_ready_arity() -> void:
	assert_bool(SignalBus.has_signal("output_ready")).is_true()
	assert_array(_signal_arg_names(SignalBus, "output_ready")).is_equal(["text"])


func test_terminal_cleared_arity() -> void:
	assert_bool(SignalBus.has_signal("terminal_cleared")).is_true()
	assert_array(_signal_arg_names(SignalBus, "terminal_cleared")).is_equal([])


func test_addon_status_changed_arity() -> void:
	assert_bool(SignalBus.has_signal("addon_status_changed")).is_true()
	assert_array(_signal_arg_names(SignalBus, "addon_status_changed")).is_equal(["available"])


func test_shell_status_changed_arity() -> void:
	assert_bool(SignalBus.has_signal("shell_status_changed")).is_true()
	assert_array(_signal_arg_names(SignalBus, "shell_status_changed")).is_equal(["running"])


# Sanity: the bus exposes _exactly_ the documented signal set. Drift
# (extra signals slipping in undocumented) is itself a smell.
func test_signal_set_is_complete() -> void:
	var expected := [
		"command_submitted",
		"output_ready",
		"terminal_cleared",
		"addon_status_changed",
		"shell_status_changed",
	]
	var actual: Array = []
	for sig in SignalBus.get_signal_list():
		# Skip Godot-built-in Node signals (script_changed, etc.).
		if sig.name in expected:
			actual.append(sig.name)
	actual.sort()
	expected.sort()
	assert_array(actual).is_equal(expected)


# Round-trip via local connection — does not require monitor_signals.
func test_command_submitted_round_trip() -> void:
	var received: Array[String] = []
	var cb := func(cmd: String) -> void: received.append(cmd)
	SignalBus.command_submitted.connect(cb)
	SignalBus.command_submitted.emit("ls -la")
	SignalBus.command_submitted.disconnect(cb)
	assert_array(received).is_equal(["ls -la"])
