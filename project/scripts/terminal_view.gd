## TerminalView - Terminal display and input handling
## Renders terminal output with ANSI color support
## Handles user input and command submission
class_name TerminalView
extends Control

## DECSCUSR cursor style values (CSI Ps SP q).
## Ps=0/1 → blinking block (default), Ps=2 → steady block,
## Ps=3 → blinking underline, Ps=4 → steady underline,
## Ps=5 → blinking bar, Ps=6 → steady bar.
enum CursorStyle {
	BLINKING_BLOCK = 0,
	STEADY_BLOCK = 2,
	BLINKING_UNDERLINE = 3,
	STEADY_UNDERLINE = 4,
	BLINKING_BAR = 5,
	STEADY_BAR = 6,
}

## Maximum lines to keep in scrollback buffer
const MAX_LINES: int = 1000
const PROMPT_SYMBOL: String = "❯"
const DEC_BRACKETED_PASTE: String = "?2004"
const CHAR_W: float = 8.0
const CHAR_H: float = 16.0
const BRACKETED_PASTE_START: String = "\u001b[200~"
const BRACKETED_PASTE_END: String = "\u001b[201~"

## Context menu item IDs for the right-click PopupMenu.
const MENU_ID_COPY: int = 0
const MENU_ID_PASTE: int = 1
const MENU_ID_CLEAR: int = 2

## Labels for the context menu items (avoid hard-coded strings in UI code).
const MENU_LABEL_COPY: String = "Copy"
const MENU_LABEL_PASTE: String = "Paste"
const MENU_LABEL_CLEAR: String = "Clear"

## Current cursor shape set by DECSCUSR (CSI Ps SP q).
var cursor_style: CursorStyle = CursorStyle.BLINKING_BLOCK

## Primary-screen cursor position (0-based). Updated on CSI H/f in primary mode.
var cursor_row: int = 0
var cursor_col: int = 0

## Active text selection start cell (col, row), inclusive. (-1,-1) = no selection.
var selection_start: Vector2i = Vector2i(-1, -1)

## Active text selection end cell (col, row), inclusive. (-1,-1) = no selection.
var selection_end: Vector2i = Vector2i(-1, -1)

## Command history for up/down navigation
var _command_history: Array[String] = []

## Current position in command history
var _history_index: int = -1

## Whether terminal is ready
var _is_ready: bool = false

## Line count for scrollback enforcement
var _line_count: int = 0

## ANSI parser state
var _current_fg: String = ""
var _current_bg: String = ""
var _current_bold: bool = false
var _partial_escape: String = ""

## Whether the alternate screen is currently active
var _in_alternate_screen: bool = false

## Saved primary buffer BBCode for ?1049 save/restore
var _primary_bbcode: String = ""

## Accumulated primary buffer BBCode (mirrors what has been appended in primary mode)
var _output_accumulator: String = ""

## Saved primary line count for save/restore
var _primary_line_count_saved: int = 0

## Alternate screen grid for cursor-positioned writing.
var _alt_grid: TerminalGrid = null

## Tracked terminal dimensions (cols x rows) for alt-screen grid sizing.
var _terminal_cols: int = 80
var _terminal_rows: int = 24

## Whether the cursor is currently visible in the blink cycle.
var _cursor_blink_visible: bool = true

## DEC private mode 25: true = cursor visible (default), false = cursor hidden.
## Controlled by CSI ?25h (show) and CSI ?25l (hide).
var _cursor_dec_visible: bool = true

## DEC private mode 2004: bracketed paste mode.
## Enabled by CSI ?2004h, disabled by CSI ?2004l.
var _bracketed_paste_mode: bool = false

## Last text copied to clipboard. Readable by tests in headless mode.
var _last_copied_text: String = ""

## When non-empty, _get_clipboard_text() returns this value instead of the
## system clipboard. Set this in tests to bypass headless clipboard limitations.
var _clipboard_override: String = ""

## Timer that drives cursor blinking (created in _setup_cursor_blink).
var _blink_timer: Timer = null

## Right-click context PopupMenu (created in _setup_context_menu).
var _context_menu: PopupMenu = null

## Set to true each time the context menu popup is requested (readable by tests).
var _context_menu_popup_requested: bool = false

## Raw ANSI text accumulator for primary screen (used for full theme re-render).
var _raw_accumulator: String = ""

## Saved raw accumulator when entering alternate screen with save=true (?1049).
var _primary_raw_saved: String = ""

## Set to true each time a theme change triggers a full re-render.
## Readable by tests to confirm the re-render was requested.
var _needs_full_rerender: bool = false

## Whether a left-button drag selection is currently in progress.
var _selecting: bool = false

## Selection highlight overlay (created programmatically in _ready).
var _selection_overlay: ColorRect = null

## Reference to the output display
@onready var output_display: RichTextLabel = $VBoxContainer/ScrollContainer/OutputDisplay

## Reference to the input field
@onready var input_field: LineEdit = $VBoxContainer/InputBar/HBoxContainer/InputField

## Reference to the prompt label
@onready var prompt_label: Label = $VBoxContainer/InputBar/HBoxContainer/PromptLabel

## Reference to the scroll container
@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer

## Block cursor overlay — floats above the text layer.
@onready var cursor_overlay: ColorRect = $VBoxContainer/ScrollContainer/CursorOverlay


func _ready() -> void:
	# Connect signals
	SignalBus.output_ready.connect(_on_output_ready)
	SignalBus.terminal_cleared.connect(_on_terminal_cleared)
	SignalBus.shell_status_changed.connect(_on_shell_status_changed)
	TerminalManager.theme_changed.connect(_on_theme_changed)

	# Setup input field
	if input_field:
		input_field.text_submitted.connect(_on_text_submitted)
		input_field.grab_focus()

	# Setup prompt
	if prompt_label:
		prompt_label.text = PROMPT_SYMBOL

	# Initialize terminal
	_initialize_terminal()

	# Handle resize
	get_tree().get_root().size_changed.connect(_on_viewport_resize)

	# Position cursor overlay at startup
	_update_cursor_overlay()

	# Set up cursor blinking timer
	_setup_cursor_blink()

	# Set up text-selection overlay
	_setup_selection_overlay()

	# Set up right-click context menu
	_setup_context_menu()


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
			KEY_C when event.ctrl_pressed and event.shift_pressed:
				copy_selected_to_clipboard()
				get_viewport().set_input_as_handled()
			KEY_C when event.ctrl_pressed:
				_handle_interrupt()
				get_viewport().set_input_as_handled()
			KEY_INSERT when event.ctrl_pressed:
				copy_selected_to_clipboard()
				get_viewport().set_input_as_handled()
			KEY_INSERT when event.shift_pressed:
				paste_text(_get_clipboard_text())
				get_viewport().set_input_as_handled()
			KEY_L when event.ctrl_pressed:
				TerminalManager.clear()
				get_viewport().set_input_as_handled()
			KEY_D when event.ctrl_pressed:
				# Send EOF
				TerminalManager.write_input("\u0004")
				get_viewport().set_input_as_handled()
			KEY_V when event.ctrl_pressed and event.shift_pressed:
				paste_text(_get_clipboard_text())
				get_viewport().set_input_as_handled()


## Handle GUI mouse events for click-drag text selection and right-click context menu.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				selection_start = _pixel_to_cell(mb.position)
				selection_end = selection_start
				_selecting = true
			else:
				_selecting = false
			_update_selection_overlay()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_show_context_menu(mb.global_position)
	elif event is InputEventMouseMotion and _selecting:
		var mm := event as InputEventMouseMotion
		selection_end = _pixel_to_cell(mm.position)
		_update_selection_overlay()


## Convert a local pixel position to a grid cell coordinate (col, row).
## Clamped to [0, _terminal_cols-1] × [0, _terminal_rows-1].
func _pixel_to_cell(pos: Vector2) -> Vector2i:
	var col := int(floor(pos.x / CHAR_W))
	var row := int(floor(pos.y / CHAR_H))
	col = clampi(col, 0, max(0, _terminal_cols - 1))
	row = clampi(row, 0, max(0, _terminal_rows - 1))
	return Vector2i(col, row)


## Create the semi-transparent ColorRect used to highlight selected text.
func _setup_selection_overlay() -> void:
	_selection_overlay = ColorRect.new()
	_selection_overlay.color = Color(0.3, 0.6, 1.0, 0.4)
	_selection_overlay.visible = false
	_selection_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if scroll_container:
		scroll_container.add_child(_selection_overlay)


## Create the right-click context PopupMenu with Copy, Paste, Clear items.
func _setup_context_menu() -> void:
	_context_menu = PopupMenu.new()
	_context_menu.add_item(MENU_LABEL_COPY, MENU_ID_COPY)
	_context_menu.add_item(MENU_LABEL_PASTE, MENU_ID_PASTE)
	_context_menu.add_item(MENU_LABEL_CLEAR, MENU_ID_CLEAR)
	add_child(_context_menu)
	_context_menu.id_pressed.connect(_on_context_menu_id_pressed)


## Enable/disable Copy based on current selection, then show the PopupMenu.
func _show_context_menu(at_pos: Vector2) -> void:
	var has_text: bool = not get_selected_text().is_empty()
	_context_menu.set_item_disabled(_context_menu.get_item_index(MENU_ID_COPY), not has_text)
	_context_menu_popup_requested = true
	_context_menu.popup(Rect2i(int(at_pos.x), int(at_pos.y), 0, 0))


## Dispatch the action for the selected context menu item.
func _on_context_menu_id_pressed(id: int) -> void:
	match id:
		MENU_ID_COPY:
			copy_selected_to_clipboard()
		MENU_ID_PASTE:
			paste_text(_get_clipboard_text())
		MENU_ID_CLEAR:
			TerminalManager.clear()


## Reposition and resize the selection overlay to cover the selected cells.
## Hides the overlay when no selection is active.
func _update_selection_overlay() -> void:
	if not _selection_overlay:
		return
	if selection_start == Vector2i(-1, -1):
		_selection_overlay.visible = false
		return
	var min_col: int = min(selection_start.x, selection_end.x)
	var max_col: int = max(selection_start.x, selection_end.x)
	var min_row: int = min(selection_start.y, selection_end.y)
	var max_row: int = max(selection_start.y, selection_end.y)
	_selection_overlay.position = Vector2(float(min_col) * CHAR_W, float(min_row) * CHAR_H)
	_selection_overlay.size = Vector2(
		float(max_col - min_col + 1) * CHAR_W, float(max_row - min_row + 1) * CHAR_H
	)
	_selection_overlay.visible = true


## Return the number of cells covered by the current selection (inclusive rect).
## Returns 0 when selection_start is (-1, -1).
func selected_cell_count() -> int:
	if selection_start == Vector2i(-1, -1):
		return 0
	var cols: int = abs(selection_end.x - selection_start.x) + 1
	var rows: int = abs(selection_end.y - selection_start.y) + 1
	return cols * rows


## Extract plain text from the currently selected region.
## In alternate screen, reads characters from _alt_grid cells.
## In primary screen, reads from the parsed RichTextLabel output.
## Returns "" when there is no active selection.
func get_selected_text() -> String:
	if selection_start == Vector2i(-1, -1):
		return ""
	var min_col: int = min(selection_start.x, selection_end.x)
	var max_col: int = max(selection_start.x, selection_end.x)
	var min_row: int = min(selection_start.y, selection_end.y)
	var max_row: int = max(selection_start.y, selection_end.y)
	if _in_alternate_screen and _alt_grid != null:
		var result := ""
		for row in range(min_row, max_row + 1):
			if row > min_row:
				result += "\n"
			for col in range(min_col, max_col + 1):
				var cell := _alt_grid.get_cell(row, col)
				result += cell.get("char", " ")
		return result
	if not output_display:
		return ""
	var lines := output_display.get_parsed_text().split("\n")
	var result := ""
	for row in range(min_row, min(max_row + 1, lines.size())):
		if row > min_row:
			result += "\n"
		var line: String = lines[row]
		var end_c: int = min(max_col + 1, line.length())
		if min_col < line.length():
			result += line.substr(min_col, end_c - min_col)
	return result


## Copy the currently selected text to the system clipboard.
## Stores the text in _last_copied_text for test visibility in headless mode.
## Does nothing when the selection is empty.
func copy_selected_to_clipboard() -> void:
	var text := get_selected_text()
	if text.is_empty():
		return
	DisplayServer.clipboard_set(text)
	_last_copied_text = text


## Initialize the terminal
func _initialize_terminal() -> void:
	_is_ready = true
	_in_alternate_screen = false
	_primary_bbcode = ""
	_primary_raw_saved = ""
	_output_accumulator = ""
	_raw_accumulator = ""
	_primary_line_count_saved = 0
	cursor_row = 0
	cursor_col = 0
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

		if ch == "\u001b":
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
						# Erase display. Alt screen: route to grid. Primary: full clear only.
						var mode_j := 0
						if params_str != "":
							mode_j = int(params_str)
						if _in_alternate_screen and _alt_grid != null:
							_alt_grid.erase_display(mode_j)
						elif mode_j == 2 or params_str == "":
							output += "[/color]"  # close any open tags
							_current_fg = ""
							_current_bg = ""
							_current_bold = false
							call_deferred("_clear_output")
					"H", "f":
						# Cursor home / position (1-based params → 0-based grid).
						if _in_alternate_screen and _alt_grid != null:
							var r := 1
							var c := 1
							if params_str != "":
								var parts := params_str.split(";")
								if parts.size() >= 1 and parts[0] != "":
									r = max(1, int(parts[0]))
								if parts.size() >= 2 and parts[1] != "":
									c = max(1, int(parts[1]))
							_alt_grid.set_cursor(r - 1, c - 1)
						else:
							# Primary screen — track cursor_row/cursor_col.
							var r := 1
							var c := 1
							if params_str != "":
								var parts := params_str.split(";")
								if parts.size() >= 1 and parts[0] != "":
									r = max(1, int(parts[0]))
								if parts.size() >= 2 and parts[1] != "":
									c = max(1, int(parts[1]))
							cursor_row = r - 1
							cursor_col = c - 1
						_update_cursor_overlay()
					"A":
						# Cursor up.
						if _in_alternate_screen and _alt_grid != null:
							var n := 1
							if params_str != "":
								n = max(1, int(params_str))
							_alt_grid.move_cursor(-n, 0)
					"B":
						# Cursor down.
						if _in_alternate_screen and _alt_grid != null:
							var n := 1
							if params_str != "":
								n = max(1, int(params_str))
							_alt_grid.move_cursor(n, 0)
					"C":
						# Cursor right.
						if _in_alternate_screen and _alt_grid != null:
							var n := 1
							if params_str != "":
								n = max(1, int(params_str))
							_alt_grid.move_cursor(0, n)
					"D":
						# Cursor left.
						if _in_alternate_screen and _alt_grid != null:
							var n := 1
							if params_str != "":
								n = max(1, int(params_str))
							_alt_grid.move_cursor(0, -n)
					"K":
						# Erase line. Alt screen: route to grid.
						if _in_alternate_screen and _alt_grid != null:
							var mode_k := 0
							if params_str != "":
								mode_k = int(params_str)
							_alt_grid.erase_line(mode_k)
					"h":
						_handle_private_mode_set(params_str)
					"l":
						_handle_private_mode_reset(params_str)
					"q":
						_handle_decscusr(params_str)
					_:
						pass

				i += end_pos + 1
				continue

			elif rest.length() > 1 and rest[1] == "]":
				# OSC sequence (title, hyperlink, etc.) — skip to ST (BEL or ESC\)
				var osc_end := rest.find("\u0007")
				if osc_end == -1:
					osc_end = rest.find("\u001b\\")
					if osc_end != -1:
						osc_end += 2
				if osc_end == -1:
					_partial_escape = rest
					break
				i += osc_end + 1
				continue

			else:
				# Unknown escape type — skip one char
				i += 2
				continue

		elif ch == "\r":
			i += 1
			continue
		elif ch == "\n":
			output += "\n"
			i += 1
			continue
		elif ch == "\u0008":
			# Backspace
			if output.length() > 0:
				output = output.substr(0, output.length() - 1)
			i += 1
			continue
		elif ch == "\u0007":
			# Bell — ignore
			i += 1
			continue
		else:
			output += ch.xml_escape()
			if _in_alternate_screen and _alt_grid != null:
				_alt_grid.write_at_cursor(_make_cell_from_state(ch))
			i += 1

	return output


## Handle SGR (Select Graphic Rendition) codes
func _handle_sgr(params_str: String) -> String:
	var result := ""

	if params_str == "" or params_str == "0":
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
				pass
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


## Build a TerminalGrid cell dictionary from the current SGR rendering state.
func _make_cell_from_state(ch: String) -> Dictionary:
	var fg := Color.WHITE
	if not _current_fg.is_empty():
		fg = Color.html(_current_fg)
	var bg := Color.BLACK
	if not _current_bg.is_empty():
		bg = Color.html(_current_bg)
	return {
		"char": ch,
		"fg": fg,
		"bg": bg,
		"bold": _current_bold,
		"italic": false,
		"underline": false,
		"url": "",
	}


## Returns the 16-entry ANSI color palette from the active TerminalTheme.
## Used by _indexed_color() to map ANSI color indices to hex strings.
func get_effective_palette() -> Array[Color]:
	return TerminalManager.current_theme.palette


## Map an ANSI color index (0-15) to a hex color string using the active theme palette.
func _indexed_color(idx: int, _bright: bool) -> String:
	var palette: Array[Color] = get_effective_palette()
	if idx >= 0 and idx < palette.size():
		return "#" + palette[idx].to_html(false)
	return "#aaaaaa"


## Convert xterm-256 index to hex color
func _xterm256_hex(idx: int) -> String:
	if idx < 16:
		return _indexed_color(idx, false)
	if idx < 232:
		var i := idx - 16
		var b := (i % 6) * 51
		var g := ((i / 6) % 6) * 51
		var r := ((i / 36) % 6) * 51
		return "#%02x%02x%02x" % [r, g, b]
	var v := 8 + (idx - 232) * 10
	return "#%02x%02x%02x" % [v, v, v]


## Append text to output with proper scrollback management
func _append_output(text: String) -> void:
	if not output_display:
		return

	var processed := _ansi_to_bbcode(text)
	if processed.is_empty():
		return

	var new_lines := processed.count("\n")
	_line_count += new_lines

	output_display.append_text(processed)
	if not _in_alternate_screen:
		_output_accumulator += processed
		_raw_accumulator += text
	if _line_count > MAX_LINES:
		_line_count = MAX_LINES

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
		if not _in_alternate_screen:
			_output_accumulator = ""
			_raw_accumulator = ""


## Scroll to bottom of output
func _scroll_to_bottom() -> void:
	if scroll_container:
		await get_tree().process_frame
		var scrollbar: VScrollBar = scroll_container.get_v_scroll_bar()
		if scrollbar:
			scrollbar.value = scrollbar.max_value


## Dispatch CSI private mode set (?-prefixed params with 'h' command).
func _handle_private_mode_set(params_str: String) -> void:
	match params_str:
		"?25":
			_cursor_dec_visible = true
			if cursor_overlay:
				cursor_overlay.visible = _cursor_blink_visible
			_update_cursor_overlay()
		"?47", "?1047":
			_enter_alternate_screen(false)
		"?1049":
			_enter_alternate_screen(true)
		DEC_BRACKETED_PASTE:
			_bracketed_paste_mode = true


## Dispatch CSI private mode reset (?-prefixed params with 'l' command).
func _handle_private_mode_reset(params_str: String) -> void:
	match params_str:
		"?25":
			_cursor_dec_visible = false
			if cursor_overlay:
				cursor_overlay.visible = false
		"?47", "?1047":
			_exit_alternate_screen(false)
		"?1049":
			_exit_alternate_screen(true)
		DEC_BRACKETED_PASTE:
			_bracketed_paste_mode = false


## Enter alternate screen buffer.
## If save is true (?1049 semantics), primary buffer is saved for later restore.
## If save is false (?47/?1047 semantics), display is cleared without saving.
func _enter_alternate_screen(save: bool) -> void:
	if _in_alternate_screen:
		return
	if save:
		_primary_bbcode = _output_accumulator
		_primary_raw_saved = _raw_accumulator
		_primary_line_count_saved = _line_count
	_in_alternate_screen = true
	if output_display:
		output_display.clear()
	_line_count = 0
	_current_fg = ""
	_current_bg = ""
	_current_bold = false
	_partial_escape = ""
	_alt_grid = TerminalGrid.new()
	_alt_grid.resize(_terminal_cols, _terminal_rows)


## Exit alternate screen buffer.
## If restore is true (?1049 semantics), primary buffer content is restored.
## If restore is false (?47/?1047 semantics), display is cleared without restore.
func _exit_alternate_screen(restore: bool) -> void:
	if not _in_alternate_screen:
		return
	_in_alternate_screen = false
	_alt_grid = null
	if output_display:
		output_display.clear()
	_line_count = 0
	_current_fg = ""
	_current_bg = ""
	_current_bold = false
	_partial_escape = ""
	var saved: String = _primary_bbcode
	_primary_bbcode = ""
	if restore and not saved.is_empty():
		output_display.append_text(saved)
		_line_count = _primary_line_count_saved
		_output_accumulator = saved
		_raw_accumulator = _primary_raw_saved
	else:
		_output_accumulator = ""
		_raw_accumulator = ""
	_scroll_to_bottom()


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
	TerminalManager.write_input("\u0003")  # Send real SIGINT via PTY
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

	# Clear input field and grab focus back
	input_field.clear()
	input_field.call_deferred("grab_focus")

	# FIX: append \n so the command actually executes in the PTY
	TerminalManager.write_input(trimmed + "\n")
	SignalBus.command_submitted.emit(trimmed)


## Handle output from TerminalManager
func _on_output_ready(text: String) -> void:
	_append_output(text)
	# Re-grab focus after output (RichTextLabel might steal it)
	if input_field:
		input_field.call_deferred("grab_focus")


## Handle terminal clear
func _on_terminal_cleared() -> void:
	_clear_output()


## Re-render the primary screen with the new palette when the active theme changes.
func _on_theme_changed(_theme: TerminalTheme) -> void:
	_needs_full_rerender = true
	if _in_alternate_screen or not output_display:
		return
	var raw := _raw_accumulator
	_clear_output()
	if not raw.is_empty():
		_append_output(raw)


## Handle shell status change
func _on_shell_status_changed(running: bool) -> void:
	if prompt_label:
		prompt_label.modulate = Color.GREEN if running else Color.RED

	if not running:
		_append_output("\n[color=#b58900]Shell exited. Terminal waiting for restart.[/color]\n")


## Handle viewport resize — compute cols/rows from pixel size and font_size,
## emit SignalBus.terminal_resized, then update TerminalManager.
func _on_viewport_resize() -> void:
	if not _is_ready:
		return
	var char_w := float(TerminalSettings.font_size) * 0.5
	var line_h := float(TerminalSettings.font_size)
	var size := get_rect().size
	if size.x > 0 and size.y > 0:
		var cols := int(floor(size.x / char_w))
		var rows := int(floor(size.y / line_h))
		SignalBus.terminal_resized.emit(cols, rows)
		cols = clampi(cols, 20, 220)
		rows = clampi(rows, 5, 100)
		_terminal_cols = cols
		_terminal_rows = rows
		if _alt_grid != null:
			_alt_grid.resize(cols, rows)
		TerminalManager.resize(cols, rows)


## Handle DECSCUSR — set cursor style (CSI Ps SP q).
## The intermediate byte (SP) is absorbed into params_str by the CSI scanner;
## strip it before parsing the numeric Ps value.
func _handle_decscusr(params_str: String) -> void:
	var ps_str := params_str.strip_edges()
	var ps := 0
	if ps_str != "":
		ps = int(ps_str)
	match ps:
		1:
			cursor_style = CursorStyle.BLINKING_BLOCK
		2:
			cursor_style = CursorStyle.STEADY_BLOCK
		3:
			cursor_style = CursorStyle.BLINKING_UNDERLINE
		4:
			cursor_style = CursorStyle.STEADY_UNDERLINE
		5:
			cursor_style = CursorStyle.BLINKING_BAR
		6:
			cursor_style = CursorStyle.STEADY_BAR
		_:
			# 0 and unknown → default blinking block
			cursor_style = CursorStyle.BLINKING_BLOCK
	_update_cursor_overlay()


## Update the cursor overlay position to match the tracked cursor.
## In alternate screen, syncs from _alt_grid; otherwise uses cursor_row/cursor_col.
## Also updates overlay size/offset to reflect the current cursor_style.
func _update_cursor_overlay() -> void:
	if not cursor_overlay:
		return
	var row := cursor_row
	var col := cursor_col
	if _in_alternate_screen and _alt_grid != null:
		row = _alt_grid.cursor_row
		col = _alt_grid.cursor_col
	var base_pos := Vector2(col * CHAR_W, row * CHAR_H)
	match cursor_style:
		CursorStyle.BLINKING_BLOCK, CursorStyle.STEADY_BLOCK:
			cursor_overlay.size = Vector2(CHAR_W, CHAR_H)
			cursor_overlay.position = base_pos
		CursorStyle.BLINKING_UNDERLINE, CursorStyle.STEADY_UNDERLINE:
			cursor_overlay.size = Vector2(CHAR_W, 2.0)
			cursor_overlay.position = base_pos + Vector2(0.0, CHAR_H - 2.0)
		CursorStyle.BLINKING_BAR, CursorStyle.STEADY_BAR:
			cursor_overlay.size = Vector2(2.0, CHAR_H)
			cursor_overlay.position = base_pos


## Create a child Timer and start cursor blinking.
## Rate comes from TerminalSettings.cursor_blink_rate.
func _setup_cursor_blink() -> void:
	_blink_timer = Timer.new()
	_blink_timer.wait_time = TerminalSettings.cursor_blink_rate
	_blink_timer.one_shot = false
	add_child(_blink_timer)
	_blink_timer.timeout.connect(_on_blink_timeout)
	if input_field:
		input_field.focus_entered.connect(_on_input_focus_entered)
		input_field.focus_exited.connect(_on_input_focus_exited)
	_start_blinking()


## Toggle cursor visibility on each timer tick.
## Steady cursor styles are unaffected — they remain always visible.
## DEC mode 25 (off) keeps cursor hidden regardless of blink state.
func _on_blink_timeout() -> void:
	if not _cursor_dec_visible:
		if cursor_overlay:
			cursor_overlay.visible = false
		return
	match cursor_style:
		CursorStyle.STEADY_BLOCK, CursorStyle.STEADY_UNDERLINE, CursorStyle.STEADY_BAR:
			_cursor_blink_visible = true
		_:
			_cursor_blink_visible = not _cursor_blink_visible
	if cursor_overlay:
		cursor_overlay.visible = _cursor_blink_visible


func _on_input_focus_entered() -> void:
	_start_blinking()


func _on_input_focus_exited() -> void:
	_stop_blinking()


## Start the blink timer; cursor is set to visible immediately.
## Respects DEC mode 25: cursor stays hidden if _cursor_dec_visible is false.
func _start_blinking() -> void:
	_cursor_blink_visible = true
	if cursor_overlay:
		cursor_overlay.visible = _cursor_dec_visible
	if _blink_timer:
		_blink_timer.start()


## Stop the blink timer; cursor is held visible (steady while unfocused).
## Respects DEC mode 25: cursor stays hidden if _cursor_dec_visible is false.
func _stop_blinking() -> void:
	if _blink_timer:
		_blink_timer.stop()
	_cursor_blink_visible = true
	if cursor_overlay:
		cursor_overlay.visible = _cursor_dec_visible


## Returns the current clipboard text.
## When _clipboard_override is set (non-empty), returns that value instead of
## the system clipboard — allows unit tests to bypass headless clipboard limits.
func _get_clipboard_text() -> String:
	if not _clipboard_override.is_empty():
		return _clipboard_override
	return DisplayServer.clipboard_get()


## Send text to the terminal as a paste operation.
## When bracketed paste mode is active, wraps text with the DEC markers
## ESC[200~ … ESC[201~ so the receiving shell can distinguish a paste from
## manually typed input and suppress premature execution of embedded newlines.
## The wrapped payload is sent as a single write_input call.
func paste_text(text: String) -> void:
	if not _is_ready or text.is_empty():
		return
	var payload: String
	if _bracketed_paste_mode:
		payload = BRACKETED_PASTE_START + text + BRACKETED_PASTE_END
	else:
		payload = text
	TerminalManager.write_input(payload)


func _exit_tree() -> void:
	# Disconnect signals to avoid leaking callbacks if this node is freed
	if _blink_timer and _blink_timer.timeout.is_connected(_on_blink_timeout):
		_blink_timer.timeout.disconnect(_on_blink_timeout)
	if input_field:
		if input_field.focus_entered.is_connected(_on_input_focus_entered):
			input_field.focus_entered.disconnect(_on_input_focus_entered)
		if input_field.focus_exited.is_connected(_on_input_focus_exited):
			input_field.focus_exited.disconnect(_on_input_focus_exited)
	if SignalBus.output_ready.is_connected(_on_output_ready):
		SignalBus.output_ready.disconnect(_on_output_ready)
	if SignalBus.terminal_cleared.is_connected(_on_terminal_cleared):
		SignalBus.terminal_cleared.disconnect(_on_terminal_cleared)
	if SignalBus.shell_status_changed.is_connected(_on_shell_status_changed):
		SignalBus.shell_status_changed.disconnect(_on_shell_status_changed)
	if TerminalManager.theme_changed.is_connected(_on_theme_changed):
		TerminalManager.theme_changed.disconnect(_on_theme_changed)
	if input_field and input_field.text_submitted.is_connected(_on_text_submitted):
		input_field.text_submitted.disconnect(_on_text_submitted)
	if (
		get_tree()
		and get_tree().get_root()
		and get_tree().get_root().size_changed.is_connected(_on_viewport_resize)
	):
		get_tree().get_root().size_changed.disconnect(_on_viewport_resize)
	if _context_menu and _context_menu.id_pressed.is_connected(_on_context_menu_id_pressed):
		_context_menu.id_pressed.disconnect(_on_context_menu_id_pressed)
