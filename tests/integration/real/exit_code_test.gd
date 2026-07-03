## Integration test: sub-process exit code propagates through the shell.
##
## Unix: runs `sh -c 'exit 42'`, then reads it back with `echo $?`.
## Windows (cmd.exe): runs `cmd /c exit 42`, then `echo %errorlevel%`.
## Asserts the output contains a line "42", proving that non-zero exit codes
## are tracked and accessible via the terminal output stream.
##
## Requires: godotty-node GDExtension present (real mode).
## Skips:    gracefully when GDExtension is absent (mock mode).
extends RealIntegrationBase

## "42" directly before a newline. ConPTY wraps output lines in OSC title and
## cursor-move sequences, so line-start anchoring never matches; the echoed
## command text is followed by escape sequences rather than a bare newline,
## so requiring "42\r\n" isolates the result line.
var _result_re := RegEx.create_from_string("(^|\\D)42\\r?\\n")


func test_exit_code_propagates() -> void:
	if not _require_real_mode():
		return

	var sub_exit := "cmd /c exit 42" if OS.has_feature("windows") else "sh -c 'exit 42'"
	var query := "echo %errorlevel%" if OS.has_feature("windows") else "echo $?"

	# Run a sub-shell that exits with code 42, then capture the status.
	TerminalManager.write_input(sub_exit + "\r")
	# Brief pause so the sub-shell finishes before we query the exit code.
	await get_tree().create_timer(0.15).timeout

	var output := await run_and_await(
		query, func(text: String) -> bool: return _result_re.search(text) != null
	)

	assert_bool(_result_re.search(output) != null).is_true()
