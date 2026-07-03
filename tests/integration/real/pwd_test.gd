## Integration test: real terminal working-directory query returns a valid path.
##
## Unix: sends `pwd`, expects an absolute path starting with "/".
## Windows (cmd.exe): sends `cd`, expects a drive-letter path like "C:\...".
##
## Requires: godotty-node GDExtension present (real mode).
## Skips:    gracefully when GDExtension is absent (mock mode).
extends RealIntegrationBase

## Matches a drive-letter absolute path (e.g. "C:\Users\...") anywhere in text.
var _win_path_re := RegEx.create_from_string("[A-Za-z]:\\\\")


func test_pwd_returns_valid_path() -> void:
	if not _require_real_mode():
		return

	if OS.has_feature("windows"):
		var output := await run_and_await(
			"cd", func(text: String) -> bool: return _win_path_re.search(text) != null
		)
		assert_str(output.strip_edges()).is_not_empty()
		assert_bool(_win_path_re.search(output) != null).is_true()
	else:
		var output := await run_and_await(
			"pwd", func(line: String) -> bool: return line.strip_edges().begins_with("/")
		)
		assert_str(output.strip_edges()).is_not_empty()
		assert_bool(output.strip_edges().begins_with("/")).is_true()
