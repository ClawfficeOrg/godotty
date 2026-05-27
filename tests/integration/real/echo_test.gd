## Integration test: real terminal `echo hello` delivers "hello" in output.
##
## Sends `echo hello` to the real PTY-backed shell and asserts the output
## stream contains a line with "hello". Proves stdout is captured and
## forwarded intact through TerminalManager.output_received.
##
## Requires: godotty-node GDExtension present (real mode).
## Skips:    gracefully when GDExtension is absent (mock mode).
extends RealIntegrationBase


func test_echo_hello_returns_hello() -> void:
	if not _require_real_mode():
		return

	var output := await run_and_await(
		"echo hello", func(line: String) -> bool: return "hello" in line
	)

	assert_str(output).contains("hello")
