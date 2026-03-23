## TerminalManager - Manages terminal backend (real or mock)
## Detects godotty-node availability and provides fallback
class_name TerminalManager
extends Node

## Whether godotty-node GDExtension is available
var is_addon_available: bool = false

## Whether we're in mock mode
var is_mock_mode: bool = false

## Mock terminal state
var _mock_output_buffer: Array[String] = []
var _mock_history: Array[String] = []
var _mock_current_dir: String = "/home/user"

# Reference to real terminal (if available)
var _real_terminal: Node = null

# Signals
signal output_received(text: String)
signal shell_started()
signal shell_stopped()


func _ready() -> void:
	_check_addon_availability()


## Check if godotty-node GDExtension is available
func _check_addon_availability() -> void:
	# Try to load the GDExtension class
	var terminal_class = ClassDB.class_get_method_list("TerminalNode2D")
	
	if terminal_class != null and terminal_class.size() > 0:
		is_addon_available = true
		is_mock_mode = false
		print("GodottyNode GDExtension detected - using real terminal")
	else:
		is_addon_available = false
		is_mock_mode = true
		print("GodottyNode GDExtension not found - using mock terminal")
	
	SignalBus.addon_status_changed.emit(is_addon_available)


## Spawn a shell (real or mock)
func spawn_shell() -> bool:
	if is_mock_mode:
		return _mock_spawn_shell()
	else:
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
		return _mock_output_buffer.size() > 0
	else:
		return _real_has_output()


## Read output from terminal
func read_output() -> String:
	if is_mock_mode:
		return _mock_read_output()
	else:
		return _real_read_output()


## Clear terminal
func clear() -> void:
	if is_mock_mode:
		_mock_clear()
	else:
		_real_clear()
	
	SignalBus.terminal_cleared.emit()


# === Mock Terminal Implementation ===

func _mock_spawn_shell() -> bool:
	_mock_output_buffer.clear()
	_mock_output_buffer.append("\x1b[32mGodotty Mock Terminal v1.0\x1b[0m")
	_mock_output_buffer.append("\x1b[90mType 'help' for available commands\x1b[0m")
	_mock_output_buffer.append("")
	shell_started.emit()
	SignalBus.shell_status_changed.emit(true)
	return true


func _mock_write_input(text: String) -> void:
	if text.strip_edges() == "":
		return
	
	# Add to history
	_mock_history.append(text)
	
	# Echo the command
	_mock_output_buffer.append("\x1b[36m%s\x1b[0m" % text)
	
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
		SignalBus.output_ready.emit(line)


func _mock_process_command(cmd: String, args: String) -> String:
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
		
		"clear":
			_mock_output_buffer.clear()
			return ""
		
		"echo":
			return args
		
		"pwd":
			return _mock_current_dir
		
		"cd":
			if args == "" or args == "~":
				_mock_current_dir = "/home/user"
			elif args == "..":
				var parts = _mock_current_dir.split("/")
				if parts.size() > 2:
					_mock_current_dir = "/".join(parts.slice(0, -1))
					if _mock_current_dir == "":
						_mock_current_dir = "/"
			else:
				if args.begins_with("/"):
					_mock_current_dir = args
				else:
					_mock_current_dir = _mock_current_dir.path_join(args)
			return ""
		
		"ls":
			if _mock_current_dir == "/home/user":
				return """\x1b[34mdocuments\x1b[0m
\x1b[34mdownloads\x1b[0m
\x1b[34mprojects\x1b[0m
\x1b[32mconfig.txt\x1b[0m
\x1b[32mreadme.md\x1b[0m"""
			elif _mock_current_dir == "/":
				return """\x1b[34mhome\x1b[0m
\x1b[34metc\x1b[0m
\x1b[34musr\x1b[0m
\x1b[34mvar\x1b[0m"""
			else:
				return "(empty directory)"
		
		"cat":
			if args == "readme.md" and _mock_current_dir == "/home/user":
				return """# Godotty Reference App

This is a demonstration terminal for the godotty-node GDExtension.

Currently running in \x1b[33mMOCK MODE\x1b[0m.

Build the godotty-node extension for real terminal emulation!"""
			elif args == "config.txt" and _mock_current_dir == "/home/user":
				return """theme=retro
font=monospace
size=16"""
			else:
				return "cat: %s: No such file or directory" % args
		
		"date":
			return Time.get_datetime_string_from_system()
		
		"whoami":
			return "user"
		
		"exit":
			_mock_output_buffer.append("\x1b[33mGoodbye!\x1b[0m")
			shell_stopped.emit()
			SignalBus.shell_status_changed.emit(false)
			return ""
		
		_:
			return "\x1b[31mCommand not found: %s\x1b[0m" % cmd


func _mock_has_output() -> bool:
	return _mock_output_buffer.size() > 0


func _mock_read_output() -> String:
	if _mock_output_buffer.size() > 0:
		return _mock_output_buffer.pop_front()
	return ""


func _mock_clear() -> void:
	_mock_output_buffer.clear()


# === Real Terminal Implementation (stubbed) ===

func _real_spawn_shell() -> bool:
	if not is_addon_available:
		push_error("Cannot spawn real shell: addon not available")
		return false
	
	# Will be implemented when godotty-node is ready
	# if _real_terminal:
	#     return _real_terminal.spawn_shell()
	
	push_warning("Real terminal not yet implemented - falling back to mock")
	is_mock_mode = true
	return _mock_spawn_shell()


func _real_write_input(text: String) -> void:
	if not is_addon_available:
		return
	
	# Will be implemented when godotty-node is ready
	# if _real_terminal:
	#     _real_terminal.write_input(text)


func _real_has_output() -> bool:
	if not is_addon_available:
		return false
	
	# Will be implemented when godotty-node is ready
	# if _real_terminal:
	#     return _real_terminal.has_output()
	
	return false


func _real_read_output() -> String:
	if not is_addon_available:
		return ""
	
	# Will be implemented when godotty-node is ready
	# if _real_terminal:
	#     return _real_terminal.read_output()
	
	return ""


func _real_clear() -> void:
	if not is_addon_available:
		return
	
	# Will be implemented when godotty-node is ready
	# if _real_terminal:
	#     _real_terminal.clear()
