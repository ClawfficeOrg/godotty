## Integration test: real terminal `pwd` returns a valid filesystem path.
##
## Sends `pwd` to the real PTY-backed shell and asserts the output line
## is a non-empty absolute path (starts with "/").
##
## Requires: godotty-node GDExtension present (real mode).
## Skips:    gracefully when GDExtension is absent (mock mode).
extends RealIntegrationBase


func test_pwd_returns_valid_path() -> void:
	if not _require_real_mode():
		return

	var output := await run_and_await(
		"pwd", func(line: String) -> bool: return line.strip_edges().begins_with("/")
	)

	assert_str(output.strip_edges()).is_not_empty()
	assert_bool(output.strip_edges().begins_with("/")).is_true()
