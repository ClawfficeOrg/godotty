## ShellDetector -- discovers launchable shells on the host system.
##
## All filesystem/PATH probes go through the injectable statics `file_exists`
## and `find_executable` so unit tests can stub them without touching the
## real system (see shell_detector_test.gd). Leave them invalid (default) to
## use the real implementations.
##
## Detection matrix (fable_review.md Part 2, W2):
##   PowerShell : pwsh.exe on PATH (PS 7) -> powershell.exe (5.1, always present)
##   cmd        : %COMSPEC% -> C:\Windows\System32\cmd.exe
##   Git Bash   : <where git>\..\..\bin\bash.exe -> well-known install paths
##   non-Windows: $SHELL -> /bin/bash
class_name ShellDetector


## Injectable probe: does a file exist at this absolute path?
## Tests assign a stub Callable; invalid (default) hits the real filesystem.
static var file_exists: Callable = Callable()

## Injectable probe: resolve a bare executable name via PATH; "" = not found.
## Tests assign a stub Callable; invalid (default) shells out to where/which.
static var find_executable: Callable = Callable()

## Cached available_profiles() result. Detection shells out to where/which
## (blocking, ~100ms per probe); installed shells do not change within a
## process lifetime, so probe once and reuse.
static var _cached_profiles: Array[ShellProfile] = []
static var _cache_valid: bool = false


## Reset injected probes back to the real implementations and drop the cache.
static func reset_probes() -> void:
	file_exists = Callable()
	find_executable = Callable()
	_cached_profiles = []
	_cache_valid = false


static func _file_exists(path: String) -> bool:
	if file_exists.is_valid():
		return file_exists.call(path)
	return FileAccess.file_exists(path)


static func _find_executable(name: String) -> String:
	if find_executable.is_valid():
		return find_executable.call(name)
	var tool_name := "where" if OS.has_feature("windows") else "which"
	var output: Array = []
	var code := OS.execute(tool_name, [name], output, true)
	if code != 0 or output.is_empty():
		return ""
	# `where` can return multiple matches, one per line; take the first.
	return str(output[0]).split("\n")[0].strip_edges()


## Build the list of shells detected on this machine, most preferred first.
## Always returns at least one profile (the platform default).
## The result is cached for the process lifetime (see _cached_profiles).
static func available_profiles() -> Array[ShellProfile]:
	if _cache_valid:
		return _cached_profiles
	if OS.has_feature("windows"):
		_cached_profiles = _windows_profiles()
	else:
		_cached_profiles = _unix_profiles()
	_cache_valid = true
	return _cached_profiles


## Find a detected profile by display name; null when absent (or name empty).
static func profile_by_name(name: String) -> ShellProfile:
	if name == "":
		return null
	for profile in available_profiles():
		if profile.display_name == name:
			return profile
	return null


static func _windows_profiles() -> Array[ShellProfile]:
	var profiles: Array[ShellProfile] = []

	# PowerShell: prefer PS7 (pwsh), fall back to Windows PowerShell 5.1.
	var pwsh := _find_executable("pwsh.exe")
	if pwsh == "":
		pwsh = _find_executable("powershell.exe")
	if pwsh != "":
		profiles.append(
			_make_profile(
				"PowerShell",
				pwsh,
				PackedStringArray(["-NoLogo"]),
				{"POWERSHELL_TELEMETRY_OPTOUT": "1"}
			)
		)

	# cmd: COMSPEC, falling back to the canonical System32 path.
	var comspec := OS.get_environment("COMSPEC")
	if comspec == "" or not _file_exists(comspec):
		var fallback := "C:\\Windows\\System32\\cmd.exe"
		comspec = fallback if _file_exists(fallback) else ""
	if comspec != "":
		# /K chcp 65001>nul: force the UTF-8 codepage (cmd defaults to the
		# OEM codepage, which garbles non-ASCII ConPTY output).
		profiles.append(
			_make_profile("cmd", comspec, PackedStringArray(["/K", "chcp 65001>nul"]), {})
		)

	var git_bash := _find_git_bash()
	if git_bash != "":
		profiles.append(
			_make_profile("Git Bash", git_bash, PackedStringArray(["--login", "-i"]), {})
		)

	return profiles


static func _find_git_bash() -> String:
	# git.exe lives in <gitroot>\cmd\ or <gitroot>\bin\; bash.exe in <gitroot>\bin\.
	var git_path := _find_executable("git.exe")
	if git_path != "":
		var git_root := git_path.get_base_dir().get_base_dir()
		var bash := git_root.path_join("bin").path_join("bash.exe")
		if _file_exists(bash):
			return bash
	var local_appdata := OS.get_environment("LOCALAPPDATA")
	var fallbacks: Array[String] = ["C:\\Program Files\\Git\\bin\\bash.exe"]
	if local_appdata != "":
		fallbacks.append(local_appdata.path_join("Programs\\Git\\bin\\bash.exe"))
	for candidate: String in fallbacks:
		if _file_exists(candidate):
			return candidate
	return ""


static func _unix_profiles() -> Array[ShellProfile]:
	var shell := OS.get_environment("SHELL")
	if shell == "":
		shell = "/bin/bash"
	var profiles: Array[ShellProfile] = [
		_make_profile(shell.get_file(), shell, PackedStringArray(), {})
	]
	return profiles


static func _make_profile(
	display_name: String, executable: String, args: PackedStringArray, env: Dictionary
) -> ShellProfile:
	var profile := ShellProfile.new()
	profile.display_name = display_name
	profile.executable = executable
	profile.args = args
	profile.env = env
	return profile
