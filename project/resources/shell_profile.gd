## ShellProfile -- describes one launchable shell (executable + arguments).
##
## Produced by ShellDetector.available_profiles() and consumed by
## TerminalManager.spawn_shell(profile). A null/absent profile means
## "platform default shell" (the pre-profile behavior).
class_name ShellProfile
extends Resource

## Human-readable name shown in the shell picker ("PowerShell", "Git Bash", "cmd").
@export var display_name: String = ""

## Executable to launch: absolute path or bare name resolved via PATH.
@export var executable: String = ""

## Arguments passed to the executable.
@export var args: PackedStringArray = []

## Extra environment variables set on top of the inherited environment.
@export var env: Dictionary = {}

## Working directory; empty string inherits the process cwd.
@export var cwd: String = ""
