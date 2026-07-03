## TerminalManagerNode -- instanceable per-tab terminal manager.
## Contains real and mock terminal logic. Can be instantiated per-tab for
## multi-terminal layouts. Does not auto-subscribe to SignalBus.terminal_resized
## and does NOT broadcast on SignalBus -- consumers connect to this instance's
## own signals (output_received, shell_started/stopped, terminal_cleared).
## The application-wide default is the TerminalManager autoload, which is the
## only SignalBus publisher.
class_name TerminalManagerNode
extends Node

## Emitted when terminal produces output.
signal output_received(text: String)

## Emitted when a shell process starts.
signal shell_started

## Emitted when a shell process stops.
signal shell_stopped

## Emitted when the terminal is cleared.
signal terminal_cleared

## Emitted when the active color theme changes.
signal theme_changed(theme: TerminalTheme)

## Whether godotty-node GDExtension is available
var is_addon_available: bool = false

## Whether we're in mock mode
var is_mock_mode: bool = false

## Active keymap for terminal actions. Assign a new TerminalKeymap to rebind keys at runtime.
var keymap: TerminalKeymap = TerminalKeymap.default()

## Active terminal color theme. Assign a new TerminalTheme to change the palette
## at runtime; emits theme_changed so TerminalView can re-render.
var current_theme: TerminalTheme:
	set(value):
		_current_theme = value if value != null else TerminalTheme.new()
		theme_changed.emit(_current_theme)
	get:
		return _current_theme

var _current_theme: TerminalTheme = null

## Mock terminal state
var _mock_output_buffer: Array[String] = []
var _mock_history: Array[String] = []
var _mock_current_dir: String = "/home/user"
var _mock_cols: int = 80
var _mock_rows: int = 24

# Reference to real terminal (if available)
var _real_terminal: Node = null


func _ready() -> void:
	if _current_theme == null:
		_current_theme = TerminalTheme.new()
	_check_addon_availability()


## Check if godotty-node GDExtension is available
func _check_addon_availability() -> void:
	# GODOTTY_FORCE_MOCK=1 lets you bypass the extension even when the dylib is present.
	if OS.get_environment("GODOTTY_FORCE_MOCK") == "1":
		is_addon_available = false
		is_mock_mode = true
		print("GODOTTY_FORCE_MOCK=1 set - using mock terminal")
		return

	# Windows defaults to mock mode until the ConPTY build of godotty-node is
	# verified (portable_pty DLL init failure 0xc0000142 with stale builds).
	# Set GODOTTY_WINDOWS_REAL=1 to opt in to the real terminal on Windows.
	if OS.has_feature("windows") and OS.get_environment("GODOTTY_WINDOWS_REAL") != "1":
		is_addon_available = false
		is_mock_mode = true
		print("Windows detected - using mock terminal (PTY issues)")
		return

	var terminal_class = ClassDB.class_get_method_list("TerminalNode2D")

	if terminal_class != null and terminal_class.size() > 0:
		is_addon_available = true
		is_mock_mode = false
		print("GodottyNode GDExtension detected - using real terminal")
	else:
		is_addon_available = false
		is_mock_mode = true
		print("GodottyNode GDExtension not found - using mock terminal")


## Spawn a shell (real or mock)
func spawn_shell() -> bool:
	if is_mock_mode:
		return _mock_spawn_shell()
	return _real_spawn_shell()


## Write input to terminal
func write_input(text: String) -> void:
	if is_mock_mode:
		_mock_write_input(text)
	else:
		_real_write_input(text)


## Check if there's output available
func has_output() -> bool:
	if is_mock_mode:
		return _mock_has_output()
	return _real_has_output()


## Read output from terminal
func read_output() -> String:
	if is_mock_mode:
		return _mock_read_output()
	return _real_read_output()


## Clear terminal
func clear() -> void:
	if is_mock_mode:
		_mock_clear()
	else:
		_real_clear()

	terminal_cleared.emit()


## Get a cell from the real terminal grid (used by grid-based renderers).
## Returns a Dictionary with keys: char, fg, bg, bold, italic.
func get_cell(row: int, col: int) -> Dictionary:
	if _real_terminal and not is_mock_mode:
		return _real_terminal.get_cell(row, col)
	return {"char": " ", "fg": Color.WHITE, "bg": Color.BLACK, "bold": false, "italic": false}


## Get terminal grid dimensions. Returns [cols, rows].
func get_dimensions() -> Array[int]:
	if _real_terminal and not is_mock_mode:
		return [_real_terminal.cols, _real_terminal.rows]
	return [_mock_cols, _mock_rows]


## Resize the real terminal.
func resize(cols: int, rows: int) -> void:
	if _real_terminal and not is_mock_mode:
		_real_terminal.resize(cols, rows)


## Handle terminal_resized signal: update mock state or forward to real terminal.
func _on_terminal_resized(cols: int, rows: int) -> void:
	if is_mock_mode:
		_mock_cols = cols
		_mock_rows = rows
	elif _real_terminal:
		_real_terminal.resize(cols, rows)


# === Mock Terminal Implementation ===


func _mock_spawn_shell() -> bool:
	_mock_output_buffer.clear()
	var esc: String = char(27)  # ANSI escape character
	_mock_output_buffer.append(esc + "[32mGodotty Mock Terminal v1.0" + esc + "[0m")
	_mock_output_buffer.append(esc + "[90mType 'help' for available commands" + esc + "[0m")
	_mock_output_buffer.append("")
	shell_started.emit()
	return true


func _mock_write_input(text: String) -> void:
	if text.strip_edges() == "":
		return

	# Add to history
	_mock_history.append(text)

	# Echo the command
	var esc: String = char(27)
	_mock_output_buffer.append(esc + "[36m%s%s[0m" % [text, esc])

	# Process command
	var parts: PackedStringArray = text.strip_edges().split(" ", false, 1)
	var cmd: String = parts[0].to_lower() if parts.size() > 0 else ""
	var args: String = parts[1] if parts.size() > 1 else ""

	var output: String = _mock_process_command(cmd, args)
	if output != "":
		for line in output.split("\n"):
			_mock_output_buffer.append(line)

	# Notify output ready
	while _mock_output_buffer.size() > 0:
		var line = _mock_output_buffer.pop_front()
		output_received.emit(line)


## Dispatch mock command to the appropriate handler.
## Handles stateful commands (clear, cd, exit) and file commands (ls, cat)
## directly; delegates simple informational commands to _mock_cmd_basic.
func _mock_process_command(cmd: String, args: String) -> String:
	match cmd:
		"clear":
			_mock_output_buffer.clear()
			return ""
		"cd":
			_mock_cmd_cd(args)
			return ""
		"exit":
			_mock_cmd_exit()
			return ""
		"ls":
			return _mock_cmd_ls()
		"cat":
			return _mock_cmd_cat(args)
		_:
			return _mock_cmd_basic(cmd, args)


## Handle simple informational commands: help, echo, pwd, date, whoami, unknown.
func _mock_cmd_basic(cmd: String, args: String) -> String:
	match cmd:
		"help":
			return """Available commands:
  help     - Show this help message
  clear    - Clear the terminal
  echo     - Echo text back
  pwd      - Print working directory
  cd       - Change directory (mock)
  ls       - List files (mock)
  cat      - Show file contents (mock)
  date     - Show current date/time
  whoami   - Show current user
  exit     - Exit the shell"""
		"echo":
			return args
		"pwd":
			return _mock_current_dir
		"date":
			return Time.get_datetime_string_from_system()
		"whoami":
			return "user"
		_:
			var esc := char(27)
			return "%s[31mCommand not found: %s%s[0m" % [esc, cmd, esc]


## Handle mock cd command; updates _mock_current_dir in place.
func _mock_cmd_cd(args: String) -> void:
	if args == "" or args == "~":
		_mock_current_dir = "/home/user"
	elif args == "..":
		var parts := _mock_current_dir.split("/")
		if parts.size() > 2:
			_mock_current_dir = "/".join(parts.slice(0, -1))
			if _mock_current_dir == "":
				_mock_current_dir = "/"
		elif _mock_current_dir != "/":
			_mock_current_dir = "/"
	else:
		if args.begins_with("/"):
			_mock_current_dir = args
		else:
			_mock_current_dir = _mock_current_dir.path_join(args)


## Handle mock ls command; returns directory listing for current dir.
func _mock_cmd_ls() -> String:
	var esc := char(27)
	if _mock_current_dir == "/home/user":
		return (
			"""{esc}[34mdocuments{esc}[0m
{esc}[34mdownloads{esc}[0m
{esc}[34mprojects{esc}[0m
{esc}[32mconfig.txt{esc}[0m
{esc}[32mreadme.md{esc}[0m"""
			. format({"esc": esc})
		)
	if _mock_current_dir == "/":
		return (
			"""{esc}[34mhome{esc}[0m
{esc}[34metc{esc}[0m
{esc}[34musr{esc}[0m
{esc}[34mvar{esc}[0m"""
			. format({"esc": esc})
		)
	return "(empty directory)"


## Handle mock cat command; returns file contents for known mock files.
func _mock_cmd_cat(args: String) -> String:
	var esc := char(27)
	if args == "readme.md" and _mock_current_dir == "/home/user":
		return (
			"""# Godotty Reference App

This is a demonstration terminal for the godotty-node GDExtension.

Currently running in {esc}[33mMOCK MODE{esc}[0m.

Build the godotty-node extension for real terminal emulation!"""
			. format({"esc": esc})
		)
	if args == "config.txt" and _mock_current_dir == "/home/user":
		return """theme=retro
font=monospace
size=16"""
	return "cat: %s: No such file or directory" % args


## Handle mock exit command; emits shell_stopped and updates shell status.
func _mock_cmd_exit() -> void:
	var esc := char(27)
	_mock_output_buffer.append(esc + "[33mGoodbye!" + esc + "[0m")
	shell_stopped.emit()


func _mock_has_output() -> bool:
	return _mock_output_buffer.size() > 0


func _mock_read_output() -> String:
	if _mock_output_buffer.size() > 0:
		return _mock_output_buffer.pop_front()
	return ""


func _mock_clear() -> void:
	_mock_output_buffer.clear()


# === Real Terminal Implementation ===


func _real_spawn_shell() -> bool:
	if not is_addon_available:
		push_error("TerminalManagerNode: cannot spawn real shell -- addon not available")
		return false

	var term_class = ClassDB.instantiate("TerminalNode2D")
	if term_class == null:
		push_error("TerminalManagerNode: ClassDB.instantiate('TerminalNode2D') returned null")
		is_mock_mode = true
		return _mock_spawn_shell()

	_real_terminal = term_class
	add_child(_real_terminal)

	if _real_terminal.has_signal("output_received"):
		_real_terminal.output_received.connect(_on_real_output_received)
	if _real_terminal.has_signal("shell_exited"):
		_real_terminal.shell_exited.connect(_on_real_shell_exited)

	_real_terminal.spawn_shell()
	shell_started.emit()
	return true


func _real_write_input(text: String) -> void:
	if _real_terminal:
		_real_terminal.write_input(text)


func _real_has_output() -> bool:
	if _real_terminal:
		return _real_terminal.has_output()
	return false


func _real_read_output() -> String:
	if _real_terminal:
		return _real_terminal.read_output()
	return ""


func _real_clear() -> void:
	# Clearing is a view-side operation: clear() emits terminal_cleared and the
	# view wipes its display. Writing "clear\n" into the PTY would type the word
	# into whatever is running (vim, htop) and breaks on non-POSIX shells (cmd).
	pass


func _on_real_output_received(text: String) -> void:
	output_received.emit(text)


func _on_real_shell_exited(code: int) -> void:
	print("TerminalManagerNode: shell exited with code ", code)
	_real_terminal = null
	shell_stopped.emit()
