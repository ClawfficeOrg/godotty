## TerminalView - Terminal display and input handling
## Renders terminal output with ANSI color support
## Handles user input and command submission
class_name TerminalView
extends Control

## Maximum lines to display before scrolling
const MAX_LINES: int = 500

## Reference to the output display
@onready var output_display: RichTextLabel = $VBoxContainer/ScrollContainer/OutputDisplay

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
		prompt_label.text = "$"
	
	# Initialize terminal
	_initialize_terminal()


func _input(event: InputEvent) -> void:
	if not _is_ready:
		return
	
	# Handle up/down arrow for command history
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				_navigate_history(-1)
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_navigate_history(1)
				get_viewport().set_input_as_handled()
			KEY_C when event.ctrl_pressed:
				# Ctrl+C to interrupt
				_handle_interrupt()
				get_viewport().set_input_as_handled()


## Initialize the terminal
func _initialize_terminal() -> void:
	_is_ready = true
	
	# Clear and show welcome
	_clear_output()
	
	# Start shell
	TerminalManager.spawn_shell()


## Process output text with ANSI color codes
func _process_ansi_text(text: String) -> String:
	# Basic ANSI color code processing
	# Convert to BBCode for RichTextLabel
	
	var result: String = text
	var esc: String = char(27)  # ANSI escape character
	
	# Reset
	result = result.replace(esc + "[0m", "[/color]")
	
	# Standard colors
	result = result.replace(esc + "[30m", "[color=black]")
	result = result.replace(esc + "[31m", "[color=red]")
	result = result.replace(esc + "[32m", "[color=green]")
	result = result.replace(esc + "[33m", "[color=yellow]")
	result = result.replace(esc + "[34m", "[color=blue]")
	result = result.replace(esc + "[35m", "[color=magenta]")
	result = result.replace(esc + "[36m", "[color=cyan]")
	result = result.replace(esc + "[37m", "[color=white]")
	
	# Bright colors
	result = result.replace(esc + "[90m", "[color=gray]")
	result = result.replace(esc + "[91m", "[color=#ff6666]")
	result = result.replace(esc + "[92m", "[color=#66ff66]")
	result = result.replace(esc + "[93m", "[color=#ffff66]")
	result = result.replace(esc + "[94m", "[color=#6666ff]")
	result = result.replace(esc + "[95m", "[color=#ff66ff]")
	result = result.replace(esc + "[96m", "[color=#66ffff]")
	result = result.replace(esc + "[97m", "[color=white]")
	
	return result


## Append text to output
func _append_output(text: String) -> void:
	if not output_display:
		return
	
	# Process ANSI codes
	var processed: String = _process_ansi_text(text)
	
	# Append to display
	output_display.append_text(processed + "\n")
	
	# Scroll to bottom
	_scroll_to_bottom()


## Clear output display
func _clear_output() -> void:
	if output_display:
		output_display.clear()


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
	
	# Move cursor to end
	input_field.caret_column = input_field.text.length()


## Handle Ctrl+C interrupt
func _handle_interrupt() -> void:
	_append_output("^C")
	input_field.text = ""
	_history_index = -1


## Handle text submission from input field
func _on_text_submitted(text: String) -> void:
	if not _is_ready:
		return
	
	var trimmed: String = text.strip_edges()
	
	# Add to history if not empty
	if trimmed != "":
		_command_history.append(trimmed)
		_history_index = -1
	
	# Clear input field and grab focus back
	input_field.clear()
	input_field.call_deferred("grab_focus")
	
	# Send command
	SignalBus.command_submitted.emit(trimmed)
	TerminalManager.write_input(trimmed)


## Handle output from TerminalManager
func _on_output_ready(text: String) -> void:
	_append_output(text)
	# Re-grab focus after output (RichTextLabel might steal it)
	if input_field:
		input_field.call_deferred("grab_focus")


## Handle terminal clear
func _on_terminal_cleared() -> void:
	_clear_output()


## Handle shell status change
func _on_shell_status_changed(running: bool) -> void:
	if prompt_label:
		prompt_label.modulate = Color.GREEN if running else Color.RED
	
	# If shell stopped, offer to restart
	if not running:
		_append_output("[color=yellow]Shell exited. Type 'exit' again to close, or any command to restart.[/color]")
