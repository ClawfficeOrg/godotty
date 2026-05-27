## Integration test: sub-process exit code propagates through the shell.
##
## Runs `sh -c 'exit 42'` inside the real PTY shell, then queries `echo $?`
## to read the exit code back through TerminalManager.output_received.
## Asserts the output contains "42", proving that non-zero exit codes are
## tracked and accessible via the terminal output stream.
##
## Requires: godotty-node GDExtension present (real mode).
## Skips:    gracefully when GDExtension is absent (mock mode).
extends RealIntegrationBase


func test_exit_code_propagates() -> void:
	if not _require_real_mode():
		return

	# Run a sub-shell that exits with code 42, then capture $?.
	TerminalManager.write_input("sh -c 'exit 42'\n")
	# Brief pause so the sub-shell finishes before we run echo $?.
	await get_tree().create_timer(0.15).timeout

	var output := await run_and_await(
		"echo $?",
		func(line: String) -> bool:
			return line.strip_edges() == "42"
	)

	assert_str(output.strip_edges()).is_equal("42")
