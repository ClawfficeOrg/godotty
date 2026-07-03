## Unit tests for ShellDetector (fable_review.md Part 2, W2/W4).
##
## All probes are stubbed via ShellDetector.file_exists / find_executable so
## these tests are deterministic on every platform: _windows_profiles() and
## _unix_profiles() are exercised directly, bypassing the OS.has_feature gate
## in available_profiles().
extends GdUnitTestSuite

var _saved_comspec: String
var _saved_shell: String
var _saved_profile_name: String


func before_test() -> void:
	_saved_comspec = OS.get_environment("COMSPEC")
	_saved_shell = OS.get_environment("SHELL")
	_saved_profile_name = TerminalSettings.default_profile_name


func after_test() -> void:
	ShellDetector.reset_probes()
	OS.set_environment("COMSPEC", _saved_comspec)
	OS.set_environment("SHELL", _saved_shell)
	TerminalSettings.default_profile_name = _saved_profile_name


## Stub helper: find_executable returns mapping[name] or "".
func _stub_path_lookup(mapping: Dictionary) -> void:
	ShellDetector.find_executable = func(name: String) -> String:
		return mapping.get(name, "")


## Stub helper: file_exists returns true only for paths in the allowed list.
func _stub_files(allowed: Array) -> void:
	ShellDetector.file_exists = func(path: String) -> bool: return path in allowed


func test_powershell_prefers_pwsh() -> void:
	OS.set_environment("COMSPEC", "")
	_stub_path_lookup(
		{"pwsh.exe": "C:/tools/pwsh.exe", "powershell.exe": "C:/win/powershell.exe"}
	)
	_stub_files([])

	var profiles := ShellDetector._windows_profiles()

	assert_int(profiles.size()).is_equal(1)
	assert_str(profiles[0].display_name).is_equal("PowerShell")
	assert_str(profiles[0].executable).is_equal("C:/tools/pwsh.exe")
	assert_array(profiles[0].args).contains_exactly(["-NoLogo"])
	assert_str(profiles[0].env.get("POWERSHELL_TELEMETRY_OPTOUT", "")).is_equal("1")


func test_powershell_falls_back_to_5_1() -> void:
	OS.set_environment("COMSPEC", "")
	_stub_path_lookup({"powershell.exe": "C:/win/powershell.exe"})
	_stub_files([])

	var profiles := ShellDetector._windows_profiles()

	assert_int(profiles.size()).is_equal(1)
	assert_str(profiles[0].executable).is_equal("C:/win/powershell.exe")


func test_cmd_uses_comspec_with_utf8_codepage_args() -> void:
	OS.set_environment("COMSPEC", "C:/custom/cmd.exe")
	_stub_path_lookup({})
	_stub_files(["C:/custom/cmd.exe"])

	var profiles := ShellDetector._windows_profiles()

	assert_int(profiles.size()).is_equal(1)
	assert_str(profiles[0].display_name).is_equal("cmd")
	assert_str(profiles[0].executable).is_equal("C:/custom/cmd.exe")
	assert_array(profiles[0].args).contains_exactly(["/K", "chcp 65001>nul"])


func test_cmd_falls_back_to_system32() -> void:
	OS.set_environment("COMSPEC", "")
	_stub_path_lookup({})
	_stub_files(["C:\\Windows\\System32\\cmd.exe"])

	var profiles := ShellDetector._windows_profiles()

	assert_int(profiles.size()).is_equal(1)
	assert_str(profiles[0].executable).is_equal("C:\\Windows\\System32\\cmd.exe")


func test_git_bash_resolved_from_git_location() -> void:
	OS.set_environment("COMSPEC", "")
	_stub_path_lookup({"git.exe": "C:/Git/cmd/git.exe"})
	_stub_files(["C:/Git/bin/bash.exe"])

	var profiles := ShellDetector._windows_profiles()

	assert_int(profiles.size()).is_equal(1)
	assert_str(profiles[0].display_name).is_equal("Git Bash")
	assert_str(profiles[0].executable).is_equal("C:/Git/bin/bash.exe")
	assert_array(profiles[0].args).contains_exactly(["--login", "-i"])


func test_git_bash_falls_back_to_program_files() -> void:
	OS.set_environment("COMSPEC", "")
	_stub_path_lookup({})
	_stub_files(["C:\\Program Files\\Git\\bin\\bash.exe"])

	var profiles := ShellDetector._windows_profiles()

	assert_int(profiles.size()).is_equal(1)
	assert_str(profiles[0].executable).is_equal("C:\\Program Files\\Git\\bin\\bash.exe")


func test_all_windows_shells_detected_in_preference_order() -> void:
	OS.set_environment("COMSPEC", "C:/win/cmd.exe")
	_stub_path_lookup({"pwsh.exe": "C:/tools/pwsh.exe", "git.exe": "C:/Git/cmd/git.exe"})
	_stub_files(["C:/win/cmd.exe", "C:/Git/bin/bash.exe"])

	var profiles := ShellDetector._windows_profiles()

	assert_int(profiles.size()).is_equal(3)
	assert_str(profiles[0].display_name).is_equal("PowerShell")
	assert_str(profiles[1].display_name).is_equal("cmd")
	assert_str(profiles[2].display_name).is_equal("Git Bash")


func test_unix_profile_from_shell_env() -> void:
	OS.set_environment("SHELL", "/usr/bin/zsh")

	var profiles := ShellDetector._unix_profiles()

	assert_int(profiles.size()).is_equal(1)
	assert_str(profiles[0].display_name).is_equal("zsh")
	assert_str(profiles[0].executable).is_equal("/usr/bin/zsh")
	assert_int(profiles[0].args.size()).is_equal(0)


func test_unix_profile_defaults_to_bash() -> void:
	OS.set_environment("SHELL", "")

	var profiles := ShellDetector._unix_profiles()

	assert_int(profiles.size()).is_equal(1)
	assert_str(profiles[0].executable).is_equal("/bin/bash")


func test_profile_by_name_empty_returns_null() -> void:
	assert_object(ShellDetector.profile_by_name("")).is_null()


func test_profile_by_name_unknown_returns_null() -> void:
	OS.set_environment("SHELL", "/bin/bash")
	assert_object(ShellDetector.profile_by_name("Klingon Shell")).is_null()


func test_selected_profile_name_persists_in_settings() -> void:
	TerminalSettings.default_profile_name = "Git Bash"
	assert_str(TerminalSettings.default_profile_name).is_equal("Git Bash")
