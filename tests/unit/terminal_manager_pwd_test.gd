# GdUnit4 test: TerminalManager mock-mode `pwd` returns /home/user.
#
# Spec: .ralph/specs/0002-gdunit4-test-harness.md
#
# This is the first canonical autonomous-loop test. It pins the contract
# that mock-mode `pwd` always reports `/home/user` on a fresh shell, which
# is the baseline assumption for every other mock-mode behavior test.
extends GdUnitTestSuite


func before_test() -> void:
	# Force mock mode so this test is deterministic regardless of whether
	# the godotty-node GDExtension is installed.
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_current_dir = "/home/user"
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()


func test_pwd_returns_home_user_on_fresh_shell() -> void:
	var output: String = TerminalManager._mock_process_command("pwd", "")
	assert_str(output).is_equal("/home/user")


func test_pwd_after_cd_absolute_path() -> void:
	TerminalManager._mock_process_command("cd", "/etc")
	var output: String = TerminalManager._mock_process_command("pwd", "")
	assert_str(output).is_equal("/etc")


func test_pwd_after_cd_dotdot_from_home() -> void:
	TerminalManager._mock_process_command("cd", "..")
	var output: String = TerminalManager._mock_process_command("pwd", "")
	assert_str(output).is_equal("/home")


func test_cd_no_args_returns_home() -> void:
	TerminalManager._mock_process_command("cd", "/etc")
	TerminalManager._mock_process_command("cd", "")
	var output: String = TerminalManager._mock_process_command("pwd", "")
	assert_str(output).is_equal("/home/user")
