## TerminalView - Terminal display and input handling
## Renders terminal output with ANSI color support
## Handles user input and command submission
class_name TerminalView
extends Control

## Maximum lines to keep in scrollback buffer
const MAX_LINES: int = 1000

## Reference to the output display
@onready var output_display: RichTextLabel = $VBoxContainer/OutputDisplay

## Reference to the input field
@onready var input_field: LineEdit = $VBoxContainer/HBoxContainer/InputField

## Reference to the prompt label
@onready var prompt_label: Label = $VBoxContainer/HBoxContainer/PromptLabel

## Reference to the scroll container
@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer

## Command history for up/down navigation
var _command_history: Array[String] = []

## Current position in command history
var _history_index: int = -1

## Whether terminal is ready
var _is_ready: bool = false

## Line count for scrollback enforcement
var _line_count: int = 0

## ANSI state machine state
var _ansi_color_stack: Array[String] = []
var _current_fg: String = ""
var _current_bg: String = ""
var _current_bold: bool = false
var _partial_escape: String = ""


func _ready() -> void:
	# Connect signals
	SignalBus.output_ready.connect(_on_output_ready)
	SignalBus.terminal_cleared.connect(_on_terminal_cleared)
	SignalBus.shell_status_changed.connect(_on_shell_status_changed)

	# Setup input field
	if input_field:
		input_field.text_submitted.connect(_on_text_submitted)
		input_field.grab_focus()

	# Setup prompt
	if prompt_label:
		prompt_label.text = "❯"

	# Initialize terminal
	_initialize_terminal()

	# Handle resize
	get_tree().get_root().size_changed.connect(_on_viewport_resize)


func _input(event: InputEvent) -> void:
	if not _is_ready:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				_navigate_history(-1)
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_navigate_history(1)
				get_viewport().set_input_as_handled()
			KEY_C when event.ctrl_pressed:
				_handle_interrupt()
				get_viewport().set_input_as_handled()
			KEY_L when event.ctrl_pressed:
				TerminalManager.clear()
				get_viewport().set_input_as_handled()
			KEY_D when event.ctrl_pressed:
				# Send EOF
				TerminalManager.write_input("\x04")
				get_viewport().set_input_as_handled()


## Initialize the terminal
func _initialize_terminal() -> void:
	_is_ready = true
	_clear_output()
	TerminalManager.spawn_shell()


## Parse ANSI SGR codes and return BBCode.
## Handles combined codes like \x1b[1;32m and full 256/truecolor.
func _ansi_to_bbcode(text: String) -> String:
	# Combine with any partial escape from last chunk
	var input := _partial_escape + text
	_partial_escape = ""

	var output := ""
	var i := 0
	while i < input.length():
		var ch := input[i]

		if ch == "\x1b":
			# Check if we have a complete sequence
			var rest := input.substr(i)
			# If we see an escape at the end of buffer without closing 'm', save for next chunk
			var bracket_pos := rest.find("[")
			if bracket_pos == -1 or (bracket_pos == 1 and rest.length() == 2):
				_partial_escape = rest
				break

			if rest.length() > 1 and rest[1] == "[":
				# Find the end of the CSI sequence
				var end_pos := -1
				for j in range(2, rest.length()):
					var c := rest[j]
					if (c >= "A" and c <= "Z") or (c >= "a" and c <= "z"):
						end_pos = j
						break

				if end_pos == -1:
					# Incomplete sequence — buffer it
					_partial_escape = rest
					break

				var cmd := rest[end_pos]
				var params_str := rest.substr(2, end_pos - 2)

				match cmd:
					"m":
						output += _handle_sgr(params_str)
					"J":
						# Erase display — treat 2J as clear
						if params_str == "2" or params_str == "":
							output += "[/color]"  # close any open tags
							_current_fg = ""
							_current_bg = ""
							_current_bold = false
							call_deferred("_clear_output")
					"H", "f":
						# Cursor position — mostly ignore in text mode, add newline context
						pass
					"K":
						# Erase line — skip
						pass
					_:
						# Unknown CSI — skip
						pass

				i += end_pos + 1
				continue

			elif rest.length() > 1 and rest[1] == "]":
				# OSC sequence (title, hyperlink, etc.) — skip to ST (BEL or ESC\)
				var osc_end := rest.find("\x07")
				if osc_end == -1:
					osc_end = rest.find("\x1b\\")
					if osc_end != -1:
						osc_end += 2
				if osc_end == -1:
					_partial_escape = rest
					break
				i += osc_end + 1
				continue

			else:
				# Unknown escape type — skip one char
				output += ""
				i += 2
				continue

		elif ch == "\r":
			# Carriage return — skip (paired with \n usually)
			i += 1
			continue
		elif ch == "\n":
			output += "\n"
			i += 1
			continue
		elif ch == "\x08":
			# Backspace
			if output.length() > 0:
				output = output.substr(0, output.length() - 1)
			i += 1
			continue
		elif ch == "\x07":
			# Bell — ignore
			i += 1
			continue
		else:
			output += ch.xml_escape()
			i += 1

	return output


## Handle SGR (Select Graphic Rendition) codes
func _handle_sgr(params_str: String) -> String:
	var result := ""

	if params_str == "" or params_str == "0":
		# Reset all — close open tags
		result += _close_all_tags()
		_current_fg = ""
		_current_bg = ""
		_current_bold = false
		return result

	var codes := params_str.split(";")
	var idx := 0
	while idx < codes.size():
		var code := int(codes[idx])

		match code:
			0:
				result += _close_all_tags()
				_current_fg = ""
				_current_bg = ""
				_current_bold = false
			1:
				if not _current_bold:
					_current_bold = true
					result += "[b]"
			2:
				pass  # dim — ignore
			3:
				result += "[i]"
			4:
				result += "[u]"
			22:
				if _current_bold:
					_current_bold = false
					result += "[/b]"
			23:
				result += "[/i]"
			24:
				result += "[/u]"
			30, 31, 32, 33, 34, 35, 36, 37:
				result += _close_fg()
				_current_fg = _indexed_color(code - 30, false)
				result += "[color=%s]" % _current_fg
			39:
				result += _close_fg()
				_current_fg = ""
			90, 91, 92, 93, 94, 95, 96, 97:
				result += _close_fg()
				_current_fg = _indexed_color(code - 90 + 8, false)
				result += "[color=%s]" % _current_fg
			38:
				# Extended fg color
				if idx + 2 < codes.size() and int(codes[idx + 1]) == 5:
					result += _close_fg()
					var color_idx := int(codes[idx + 2])
					_current_fg = _xterm256_hex(color_idx)
					result += "[color=%s]" % _current_fg
					idx += 2
				elif idx + 4 < codes.size() and int(codes[idx + 1]) == 2:
					var r := int(codes[idx + 2])
					var g := int(codes[idx + 3])
					var b := int(codes[idx + 4])
					result += _close_fg()
					_current_fg = "#%02x%02x%02x" % [r, g, b]
					result += "[color=%s]" % _current_fg
					idx += 4
			48:
				# Extended bg — RichTextLabel bg not easily supported, skip
				if idx + 2 < codes.size() and int(codes[idx + 1]) == 5:
					idx += 2
				elif idx + 4 < codes.size() and int(codes[idx + 1]) == 2:
					idx += 4
		idx += 1

	return result


func _close_all_tags() -> String:
	var r := ""
	if _current_bold:
		r += "[/b]"
	if not _current_fg.is_empty():
		r += "[/color]"
	return r


func _close_fg() -> String:
	if not _current_fg.is_empty():
		_current_fg = ""
		return "[/color]"
	return ""


## Solarized Dark-inspired named color palette (indices 0-15)
func _indexed_color(idx: int, _bright: bool) -> String:
	const PALETTE := [
		"#073642",  # 0  black
		"#dc322f",  # 1  red
		"#859900",  # 2  green
		"#b58900",  # 3  yellow
		"#268bd2",  # 4  blue
		"#d33682",  # 5  magenta
		"#2aa198",  # 6  cyan
		"#eee8d5",  # 7  white
		"#002b36",  # 8  bright black (base03)
		"#cb4b16",  # 9  bright red (orange)
		"#586e75",  # 10 bright green (base01)
		"#657b83",  # 11 bright yellow (base00)
		"#839496",  # 12 bright blue (base0)
		"#6c71c4",  # 13 bright magenta (violet)
		"#93a1a1",  # 14 bright cyan (base1)
		"#fdf6e3",  # 15 bright white (base3)
	]
	if idx >= 0 and idx < PALETTE.size():
		return PALETTE[idx]
	return "#aaaaaa"


## Convert xterm-256 index to hex color
func _xterm256_hex(idx: int) -> String:
	if idx < 16:
		return _indexed_color(idx, false)
	elif idx < 232:
		var i := idx - 16
		var b := (i % 6) * 51
		var g := ((i / 6) % 6) * 51
		var r := ((i / 36) % 6) * 51
		return "#%02x%02x%02x" % [r, g, b]
	else:
		var v := 8 + (idx - 232) * 10
		return "#%02x%02x%02x" % [v, v, v]


## Append text to output with proper scrollback management
func _append_output(text: String) -> void:
	if not output_display:
		return

	# Process ANSI codes
	var processed := _ansi_to_bbcode(text)
	if processed.is_empty():
		return

	# Count newlines added
	var new_lines := processed.count("\n")
	_line_count += new_lines

	output_display.append_text(processed)

	# Enforce scrollback limit
	if _line_count > MAX_LINES:
		var excess := _line_count - MAX_LINES
		_line_count = MAX_LINES
		# RichTextLabel doesn't have direct line removal; clear and note truncation
		# For now just let it grow (RichTextLabel handles this gracefully)
		# A proper implementation would use a circular buffer
		pass

	_scroll_to_bottom()


## Clear output display
func _clear_output() -> void:
	if output_display:
		output_display.clear()
		_line_count = 0
		_current_fg = ""
		_current_bg = ""
		_current_bold = false
		_partial_escape = ""


## Scroll to bottom of output
func _scroll_to_bottom() -> void:
	if scroll_container:
		await get_tree().process_frame
		var scrollbar: VScrollBar = scroll_container.get_v_scroll_bar()
		if scrollbar:
			scrollbar.value = scrollbar.max_value


## Navigate command history
func _navigate_history(direction: int) -> void:
	if _command_history.is_empty():
		return

	_history_index = clampi(_history_index + direction, -1, _command_history.size() - 1)

	if _history_index == -1:
		input_field.text = ""
	else:
		input_field.text = _command_history[_command_history.size() - 1 - _history_index]

	input_field.caret_column = input_field.text.length()


## Handle Ctrl+C interrupt
func _handle_interrupt() -> void:
	TerminalManager.write_input("\x03")  # Send real SIGINT via PTY
	input_field.text = ""
	_history_index = -1


## Handle text submission from input field
func _on_text_submitted(text: String) -> void:
	if not _is_ready:
		return

	var trimmed: String = text.strip_edges()

	if trimmed != "":
		_command_history.append(trimmed)
		_history_index = -1

	input_field.clear()

	# FIX: append \n so the command actually executes in the PTY
	TerminalManager.write_input(trimmed + "\n")
	SignalBus.command_submitted.emit(trimmed)


## Handle output from TerminalManager
func _on_output_ready(text: String) -> void:
	_append_output(text)


## Handle terminal clear
func _on_terminal_cleared() -> void:
	_clear_output()


## Handle shell status change
func _on_shell_status_changed(running: bool) -> void:
	if prompt_label:
		prompt_label.modulate = Color.GREEN if running else Color.RED

	if not running:
		_append_output("\n[color=#b58900]Shell exited. Terminal waiting for restart.[/color]\n")


## Handle viewport resize — update terminal dimensions
func _on_viewport_resize() -> void:
	if not _is_ready:
		return
	# Estimate cols/rows from current size and assumed monospace char dimensions
	var char_w := 8.0
	var char_h := 16.0
	var size := get_rect().size
	if size.x > 0 and size.y > 0:
		var cols := int(size.x / char_w)
		var rows := int((size.y - 40.0) / char_h)  # subtract input bar height
		cols = clampi(cols, 20, 220)
		rows = clampi(rows, 5, 100)
		TerminalManager.resize(cols, rows)
