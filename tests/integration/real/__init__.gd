## RealIntegrationBase -- shared helpers for real-terminal integration tests.
##
## Subclass this in every test file under tests/integration/real/.
## Each test must begin with:
##
##     if not _require_real_mode():
##         return
##
## to skip gracefully when the godotty-node GDExtension is absent.
##
## Helper contract:
##   run_and_await(cmd, predicate) -- send cmd+\n, return first matching output line.
##   _require_real_mode()          -- pending+return-false in mock mode.
class_name RealIntegrationBase
extends GdUnitTestSuite

## Seconds to wait after spawn_shell() before the PTY prompt settles.
const SETTLE_DELAY_SEC := 0.3
## Maximum milliseconds to wait for expected terminal output.
const CMD_TIMEOUT_MS := 5000
## Polling granularity when waiting for output.
const POLL_INTERVAL_MS := 50

var _output_cb: Callable = Callable()


## Spawn a fresh shell before each test (no-op in mock mode).
func before_test() -> void:
	if TerminalManager.is_mock_mode:
		return
	TerminalManager.spawn_shell()
	# Wait for the PTY to emit its initial prompt before the test sends input.
	await get_tree().create_timer(SETTLE_DELAY_SEC).timeout


## Send "exit" and pause briefly to let the shell process close (no-op in mock mode).
func after_test() -> void:
	if _output_cb.is_valid() and TerminalManager.output_received.is_connected(_output_cb):
		TerminalManager.output_received.disconnect(_output_cb)
	if not TerminalManager.is_mock_mode:
		TerminalManager.write_input("exit\n")
		await get_tree().create_timer(0.5).timeout


## Returns true when the real backend is present.
## Marks the test pending and returns false in mock mode so the caller can `return`.
func _require_real_mode() -> bool:
	if TerminalManager.is_mock_mode:
		print("[skip] real terminal (godotty-node GDExtension) not available")
		return false
	return true


## Send `cmd` (newline appended) and wait for the first output line matching
## `predicate`. Returns the matched line, or "" when the timeout expires.
func run_and_await(cmd: String, predicate: Callable, timeout_ms: int = CMD_TIMEOUT_MS) -> String:
	var matched := ""
	var done := false

	_output_cb = func(text: String) -> void:
		if not done and predicate.call(text):
			done = true
			matched = text

	if _output_cb != null and TerminalManager.output_received.is_connected(_output_cb):
		TerminalManager.output_received.disconnect(_output_cb)
	TerminalManager.output_received.connect(_output_cb)
	TerminalManager.write_input(cmd + "\n")

	var elapsed := 0
	while not done and elapsed < timeout_ms:
		await get_tree().create_timer(float(POLL_INTERVAL_MS) / 1000.0).timeout
		elapsed += POLL_INTERVAL_MS

	if _output_cb.is_valid() and TerminalManager.output_received.is_connected(_output_cb):
		TerminalManager.output_received.disconnect(_output_cb)
		_output_cb = Callable()

	return matched
