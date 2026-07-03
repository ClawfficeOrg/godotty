## TerminalView - Terminal display and input handling
## Renders terminal output with ANSI color support
## Handles user input and command submission
class_name TerminalView
extends Control

## Emitted when the user triggers the new_tab keymap action.
signal tab_new_requested

## Emitted when the user triggers the close_tab keymap action.
signal tab_close_requested

## Emitted when the user triggers the next_tab keymap action.
signal tab_next_requested

## Emitted when an OSC 0 or OSC 2 sequence sets the window/tab title.
signal tab_title_changed(title: String)

## DECSCUSR cursor style values (CSI Ps SP q).
## Ps=0/1 -> blinking block (default), Ps=2 -> steady block,
## Ps=3 -> blinking underline, Ps=4 -> steady underline,
## Ps=5 -> blinking bar, Ps=6 -> steady bar.
enum CursorStyle {
	BLINKING_BLOCK = 0,
	STEADY_BLOCK = 2,
	BLINKING_UNDERLINE = 3,
	STEADY_UNDERLINE = 4,
	BLINKING_BAR = 5,
	STEADY_BAR = 6,
}
const PROMPT_SYMBOL: String = "?"
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

## BBCode background colour used to highlight search matches.
const SEARCH_HIGHLIGHT_BG: String = "#3a3a00"

## BBCode background colour for the currently-selected (navigated) search match.
const SEARCH_ACCENT_BG: String = "#b58900"

## Duration of the visual bell flash in seconds.
const BELL_DURATION: float = 0.15

## The colour applied to self_modulate when a BEL (\u0007) character is received.
## Tween flashes the terminal to this colour then restores the original modulate.
@export var bell_color: Color = Color.WHITE

## Injected terminal manager instance. When null, falls back to the TerminalManager autoload.
## Set before adding to the scene tree to use a per-tab manager instead of the global one.
@export var manager: Node = null

## Computed character cell width in pixels (TerminalSettings.font_size ? 0.5).
## Updated by apply_font_settings(). Used for cursor and selection positioning.
var char_width: float = CHAR_W

## Computed line height in pixels (TerminalSettings.font_size ? 1.0).
## Updated by apply_font_settings(). Used for cursor and selection positioning.
var line_height: float = CHAR_H

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

## Streaming ANSI -> BBCode converter. Owns SGR state, partial-escape
## buffering, and the standalone-CR line-rewrite flag (see AnsiParser).
var _parser: AnsiParser = AnsiParser.new()

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

## Number of active search highlights in the terminal output.
## Set to 0 when the search bar is dismissed. Readable by tests.
var _search_highlight_count: int = 0

## Positions (line, col) of all current search matches in the scrollback.
var _search_matches: Array[Vector2i] = []

## Index of the currently-selected (accent-highlighted) search match.
## -1 means no match is selected.
var _search_match_index: int = -1

## Query string from the last search_scrollback() call (used when re-rendering).
var _last_search_query: String = ""

## Whether the last search_scrollback() call used regex mode.
var _last_search_use_regex: bool = false

## Reference to the output display
@onready
var output_display: RichTextLabel = $PaddingContainer/VBoxContainer/ScrollContainer/OutputDisplay

## Reference to the input field
@onready
var input_field: LineEdit = $PaddingContainer/VBoxContainer/InputBar/HBoxContainer/InputField

## Reference to the prompt label
@onready var prompt_label: Label = $PaddingContainer/VBoxContainer/InputBar/HBoxContainer/PromptLabel

## Reference to the scroll container
@onready var scroll_container: ScrollContainer = $PaddingContainer/VBoxContainer/ScrollContainer

## Block cursor overlay -- floats above the text layer.
@onready
var cursor_overlay: ColorRect = $PaddingContainer/VBoxContainer/ScrollContainer/CursorOverlay

## Overlay search bar anchored to the top-right of this control.
@onready var search_bar: SearchBar = $SearchBar

## MarginContainer that applies TerminalSettings.padding as insets.
@onready var padding_container: MarginContainer = $PaddingContainer
@onready var _theme_menu: MenuButton = $PaddingContainer/VBoxContainer/TitleBar/ThemeMenu
@onready var _font_option: OptionButton = $PaddingContainer/VBoxContainer/TitleBar/FontOptionButton
@onready var _font_spinbox: SpinBox = $PaddingContainer/VBoxContainer/TitleBar/FontSizeSpinBox
@onready var _input_bar: PanelContainer = $PaddingContainer/VBoxContainer/InputBar


func _ready() -> void:
	# Connect signals. With an injected per-tab manager, subscribe to that
	# manager's own signals; the SignalBus fan-out belongs to the app-wide
	# default TerminalManager autoload only (subscribing every view to the
	# bus would make each tab render every other tab's output).
	if manager != null:
		manager.output_received.connect(_on_output_ready)
		manager.shell_started.connect(_on_shell_started)
		manager.shell_stopped.connect(_on_shell_stopped)
		if manager.has_signal("terminal_cleared"):
			manager.terminal_cleared.connect(_on_terminal_cleared)
	else:
		SignalBus.output_ready.connect(_on_output_ready)
		SignalBus.terminal_cleared.connect(_on_terminal_cleared)
		SignalBus.shell_status_changed.connect(_on_shell_status_changed)
	SignalBus.addon_status_changed.connect(_on_addon_status_changed)
	_get_manager().theme_changed.connect(_on_theme_changed)

	# Wire the ANSI parser: it converts text and signals everything that
	# concerns the view (cursor, erase, private modes, titles, bell,
	# alt-screen mirroring). Godot signals are synchronous, so dispatch
	# order matches the old inline implementation.
	_parser.palette_provider = get_effective_palette
	_parser.csi_received.connect(_on_parser_csi)
	_parser.osc_received.connect(_handle_osc)
	_parser.bell_received.connect(_trigger_visual_bell)
	_parser.alt_char_written.connect(_on_parser_alt_char)

	# Setup input field
	if input_field:
		input_field.text_submitted.connect(_on_text_submitted)
		input_field.grab_focus()

	# Setup prompt
	if prompt_label:
		prompt_label.text = PROMPT_SYMBOL

	# Load the selected bundled font before spawning the shell. Doing this
	# here (rather than lazily inside apply_font_settings) ensures the main
	# thread is not blocked on ResourceLoader.load() AFTER the PTY reader
	# thread has started -- that would create a reliable race window where
	# godot-rust 'safeguards balanced' fires SIGTRAP on the cross-thread
	# output_received emit.
	if TerminalSettings.font == null and TerminalSettings.selected_font_name != "Default":
		var fpath: String = TerminalSettings.BUNDLED_FONT_PATHS.get(
			TerminalSettings.selected_font_name, ""
		)
		if fpath != "":
			TerminalSettings.font = load(fpath)

	# Initialize terminal (spawns the shell / PTY reader thread).
	_setup_theme_picker()
	_initialize_terminal()
	# Apply font settings after terminal is initialized so output_display is ready
	apply_font_settings()
	_setup_font_panel()
	apply_background_opacity()
	apply_padding()

	# Handle resize: window size changes (root signal) and per-control
	# layout changes (tab/split) both need to recalculate cols/rows.
	resized.connect(_on_viewport_resize)
	get_tree().get_root().size_changed.connect(_on_viewport_resize)

	# Position cursor overlay at startup
	_update_cursor_overlay()

	# Set up cursor blinking timer
	_setup_cursor_blink()

	# Set up text-selection overlay
	_setup_selection_overlay()

	# Set up right-click context menu
	_setup_context_menu()

	# Connect search bar dismissed signal
	if search_bar:
		search_bar.search_canceled.connect(_on_search_canceled)
		search_bar.search_submitted.connect(_on_search_submitted)
		search_bar.navigate_next.connect(_on_navigate_next)
		search_bar.navigate_prev.connect(_on_navigate_prev)


func _input(event: InputEvent) -> void:
	if not _is_ready:
		return

	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var ev := event as InputEventKey

	# Terminal-level keymap actions (copy, paste, new tab, etc.) always fire
	# regardless of mode so the user can manage the emulator window.
	var action: String = _get_manager().keymap.find_action(ev)
	if action != "":
		_execute_action(action)
		get_viewport().set_input_as_handled()
		return

	# Legacy clipboard shortcuts (Ctrl/Shift+Insert).
	if ev.keycode == KEY_INSERT and ev.ctrl_pressed:
		copy_selected_to_clipboard()
		get_viewport().set_input_as_handled()
		return
	if ev.keycode == KEY_INSERT and ev.shift_pressed:
		paste_text(_get_clipboard_text())
		get_viewport().set_input_as_handled()
		return

	if not _get_manager().is_mock_mode:
		# Real PTY: forward every keystroke as raw bytes. The shell (readline /
		# ZLE) handles echo, line editing, history, and tab completion inline.
		var seq := _key_to_pty_seq(ev)
		if seq != "":
			_get_manager().write_input(seq)
			get_viewport().set_input_as_handled()
		return

	# Mock mode: history navigation + let LineEdit handle printable chars.
	match ev.keycode:
		KEY_TAB:
			_get_manager().write_input("\t")
			get_viewport().set_input_as_handled()
		KEY_UP:
			_navigate_history(-1)
			get_viewport().set_input_as_handled()
		KEY_DOWN:
			_navigate_history(1)
			get_viewport().set_input_as_handled()


## Dispatch a keymap action by name.
func _execute_action(action: String) -> void:
	match action:
		TerminalKeymap.ACTION_COPY:
			copy_selected_to_clipboard()
		TerminalKeymap.ACTION_PASTE:
			paste_text(_get_clipboard_text())
		TerminalKeymap.ACTION_CLEAR:
			_get_manager().clear()
		TerminalKeymap.ACTION_SEARCH:
			show_search_bar()
		TerminalKeymap.ACTION_INTERRUPT:
			_handle_interrupt()
		TerminalKeymap.ACTION_EOF:
			_get_manager().write_input("\u0004")
		TerminalKeymap.ACTION_SCROLL_PAGE_UP:
			if scroll_container:
				scroll_container.scroll_vertical -= int(scroll_container.size.y)
		TerminalKeymap.ACTION_SCROLL_PAGE_DOWN:
			if scroll_container:
				scroll_container.scroll_vertical += int(scroll_container.size.y)
		TerminalKeymap.ACTION_NEW_TAB:
			tab_new_requested.emit()
		TerminalKeymap.ACTION_CLOSE_TAB:
			tab_close_requested.emit()
		TerminalKeymap.ACTION_NEXT_TAB:
			tab_next_requested.emit()


## Convert a key event to the byte sequence a real terminal sends to the PTY.
## Returns "" for keys that should be silently ignored.
## Early returns per key are the clearest shape for this lookup table.
# gdlint: disable=max-returns
func _key_to_pty_seq(ev: InputEventKey) -> String:
	const ESC := "\u001b"

	# Ctrl+letter -> control character (e.g. Ctrl+C = \x03)
	if ev.ctrl_pressed and not ev.alt_pressed and not ev.meta_pressed:
		match ev.keycode:
			KEY_A:
				return "\u0001"
			KEY_B:
				return "\u0002"
			KEY_C:
				return "\u0003"
			KEY_D:
				return "\u0004"
			KEY_E:
				return "\u0005"
			KEY_F:
				return "\u0006"
			KEY_G:
				return "\u0007"
			KEY_H:
				return "\u0008"
			KEY_K:
				return "\u000b"
			KEY_L:
				return "\u000c"
			KEY_N:
				return "\u000e"
			KEY_P:
				return "\u0010"
			KEY_R:
				return "\u0012"
			KEY_T:
				return "\u0014"
			KEY_U:
				return "\u0015"
			KEY_W:
				return "\u0017"
			KEY_Y:
				return "\u0019"
			KEY_Z:
				return "\u001a"
			KEY_BRACKETLEFT:
				return "\u001b"  # Ctrl+[ = ESC
			KEY_BACKSLASH:
				return "\u001c"
			KEY_BRACKETRIGHT:
				return "\u001d"

	# Special / navigation keys
	match ev.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			return "\r"
		KEY_BACKSPACE:
			return "\u007f"
		KEY_TAB:
			return "\t"
		KEY_ESCAPE:
			return ESC
		KEY_DELETE:
			return ESC + "[3~"
		KEY_HOME:
			return ESC + "[H"
		KEY_END:
			return ESC + "[F"
		KEY_INSERT:
			return ESC + "[2~"
		KEY_UP:
			return ESC + "[A"
		KEY_DOWN:
			return ESC + "[B"
		KEY_RIGHT:
			return ESC + "[C"
		KEY_LEFT:
			return ESC + "[D"
		KEY_PAGEUP:
			return ESC + "[5~"
		KEY_PAGEDOWN:
			return ESC + "[6~"
		KEY_F1:
			return ESC + "OP"
		KEY_F2:
			return ESC + "OQ"
		KEY_F3:
			return ESC + "OR"
		KEY_F4:
			return ESC + "OS"
		KEY_F5:
			return ESC + "[15~"
		KEY_F6:
			return ESC + "[17~"
		KEY_F7:
			return ESC + "[18~"
		KEY_F8:
			return ESC + "[19~"
		KEY_F9:
			return ESC + "[20~"
		KEY_F10:
			return ESC + "[21~"
		KEY_F11:
			return ESC + "[23~"
		KEY_F12:
			return ESC + "[24~"

	# Printable unicode character
	if ev.unicode > 0 and not ev.ctrl_pressed and not ev.meta_pressed:
		return char(ev.unicode)

	return ""


# gdlint: enable=max-returns


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
## In primary mode the vertical scroll offset is added so rows index into the
## scrollback content (which is what selection extraction reads), and rows may
## exceed the viewport when the scrollback is longer than one screen.
## In alternate-screen mode rows are clamped to [0, _terminal_rows-1].
func _pixel_to_cell(pos: Vector2) -> Vector2i:
	var y := pos.y
	var max_row := maxi(0, _terminal_rows - 1)
	if not _in_alternate_screen:
		if scroll_container:
			y += scroll_container.scroll_vertical
		max_row = maxi(_line_count, max_row)
	var col := int(floor(pos.x / char_width))
	var row := int(floor(y / line_height))
	col = clampi(col, 0, max(0, _terminal_cols - 1))
	row = clampi(row, 0, max_row)
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
			_get_manager().clear()


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
	_selection_overlay.position = Vector2(float(min_col) * char_width, float(min_row) * line_height)
	_selection_overlay.size = Vector2(
		float(max_col - min_col + 1) * char_width, float(max_row - min_row + 1) * line_height
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


## Show the search bar overlay and give focus to its query field.
## Called by the Ctrl+Shift+F shortcut.
func show_search_bar() -> void:
	if search_bar:
		search_bar.show_search()


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
	# Hide the typed-input bar in real PTY mode -- the shell echoes keystrokes
	# inline so a separate LineEdit would be redundant and confusing.
	if _input_bar:
		_input_bar.visible = _get_manager().is_mock_mode
	_load_and_apply_theme(TerminalSettings.selected_theme_name)
	_get_manager().spawn_shell()


## Returns the active manager: the injected one if set, otherwise the TerminalManager autoload.
func _get_manager() -> Node:
	return manager if manager != null else TerminalManager


## Returns the 16-entry ANSI color palette from the active TerminalTheme.
## Used by _indexed_color() to map ANSI color indices to hex strings.
func get_effective_palette() -> Array[Color]:
	return _get_manager().current_theme.palette

## Dispatch non-SGR CSI sequences signalled by the AnsiParser.
func _on_parser_csi(cmd: String, params_str: String) -> void:
	match cmd:
		"J":
			# Erase display. Alt screen: route to grid. Primary mode:
			#   mode 2 = intentional full clear (Ctrl+L / clear) -> wipe display.
			#   modes 0/1 are no-ops in a streaming primary buffer -- ZLE/
			#   readline emit mode 0 on prompt redraws and acting on it would
			#   wipe the just-rendered output.
			var mode_j := 0
			if params_str != "":
				mode_j = int(params_str)
			if _in_alternate_screen and _alt_grid != null:
				_alt_grid.erase_display(mode_j)
			elif mode_j == 2:
				call_deferred("_clear_output")
		"H", "f":
			# Cursor home / position (1-based params -> 0-based grid).
			var r := 1
			var c := 1
			if params_str != "":
				var parts := params_str.split(";")
				if parts.size() >= 1 and parts[0] != "":
					r = maxi(1, int(parts[0]))
				if parts.size() >= 2 and parts[1] != "":
					c = maxi(1, int(parts[1]))
			if _in_alternate_screen and _alt_grid != null:
				_alt_grid.set_cursor(r - 1, c - 1)
			else:
				cursor_row = r - 1
				cursor_col = c - 1
			_update_cursor_overlay()
		"A":
			if _in_alternate_screen and _alt_grid != null:
				_alt_grid.move_cursor(-_csi_count(params_str), 0)
		"B":
			if _in_alternate_screen and _alt_grid != null:
				_alt_grid.move_cursor(_csi_count(params_str), 0)
		"C":
			if _in_alternate_screen and _alt_grid != null:
				_alt_grid.move_cursor(0, _csi_count(params_str))
		"D":
			if _in_alternate_screen and _alt_grid != null:
				_alt_grid.move_cursor(0, -_csi_count(params_str))
		"K":
			# Erase line -- only meaningful in the alt-screen grid.
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


## Parse a CSI count parameter (default 1, minimum 1).
func _csi_count(params_str: String) -> int:
	if params_str == "":
		return 1
	return maxi(1, int(params_str))


## Write a parser-built cell into the alternate-screen grid.
func _on_parser_alt_char(cell: Dictionary) -> void:
	if _alt_grid != null:
		_alt_grid.write_at_cursor(cell)


## Append text to output with proper scrollback management
func _append_output(text: String) -> void:
	if not output_display:
		return

	var processed := _parser.parse(text)

	# A standalone CR in `text` may span a PTY-read-chunk boundary: the partial
	# line that was already written to _output_accumulator / output_display in an
	# earlier chunk must be cleared before appending the rewritten content.
	# Tags in the accumulator are line-local (see _ansi_to_bbcode), so cutting
	# at the last newline never dangles BBCode -- no re-parse of the raw ANSI
	# stream is needed (that re-parse used to make every prompt redraw O(N)).
	if _parser.pending_line_clear and not _in_alternate_screen:
		_parser.pending_line_clear = false
		var had_partial := (
			not _output_accumulator.is_empty() and not _output_accumulator.ends_with("\n")
		)
		var raw_nl := _raw_accumulator.rfind("\n")
		_raw_accumulator = _raw_accumulator.substr(0, raw_nl + 1) + text
		var acc_nl := _output_accumulator.rfind("\n")
		_output_accumulator = _output_accumulator.substr(0, acc_nl + 1) + processed
		var removed := true
		if had_partial:
			var last_par := output_display.get_paragraph_count() - 1
			removed = last_par >= 0 and output_display.remove_paragraph(last_par)
		if removed:
			output_display.append_text(processed)
		else:
			# Fallback: rebuild the display from the already-generated BBCode.
			output_display.clear()
			output_display.append_text(_output_accumulator)
		_line_count = _output_accumulator.count("\n")
		var clear_limit: int = clampi(TerminalSettings.scrollback_lines, 1, 100000)
		if _line_count > clear_limit:
			_enforce_scrollback_limit(clear_limit)
		_scroll_to_bottom()
		return

	if processed.is_empty():
		return

	var new_lines := processed.count("\n")
	_line_count += new_lines

	output_display.append_text(processed)
	if not _in_alternate_screen:
		_output_accumulator += processed
		_raw_accumulator += text
	var limit: int = clampi(TerminalSettings.scrollback_lines, 1, 100000)
	if _line_count > limit and not _in_alternate_screen:
		_enforce_scrollback_limit(limit)

	_scroll_to_bottom()


## Trim the primary scrollback to `limit` lines, discarding the oldest content.
## Cuts both accumulators at line boundaries (tags are line-local, so the cut
## is BBCode-safe) and removes the corresponding display paragraphs -- the raw
## ANSI text is never re-parsed. Only call when not in alternate-screen mode.
func _enforce_scrollback_limit(limit: int) -> void:
	var excess := _line_count - limit
	_raw_accumulator = _cut_leading_lines(_raw_accumulator, excess)
	_output_accumulator = _cut_leading_lines(_output_accumulator, excess)
	_line_count = limit
	var removed_ok := true
	for _i in range(excess):
		if not output_display.remove_paragraph(0):
			removed_ok = false
			break
	if not removed_ok:
		# Fallback: rebuild the display from the already-generated BBCode.
		output_display.clear()
		output_display.append_text(_output_accumulator)

	# Adjust selection coordinates: lines removed from the front shift all
	# subsequent row indices downward. Reset selection when it falls off.
	if selection_start != Vector2i(-1, -1):
		var new_start_y := selection_start.y - excess
		var new_end_y := selection_end.y - excess
		if new_end_y < 0:
			selection_start = Vector2i(-1, -1)
			selection_end = Vector2i(-1, -1)
		else:
			selection_start.y = maxi(0, new_start_y)
			selection_end.y = maxi(0, new_end_y)
	_update_selection_overlay()


## Return `s` with its first `count` lines (including each trailing newline)
## removed.
func _cut_leading_lines(s: String, count: int) -> String:
	var pos := 0
	var found := 0
	while found < count and pos < s.length():
		if s[pos] == "\n":
			found += 1
		pos += 1
	return s.substr(pos)


## Clear output display
func _clear_output() -> void:
	if output_display:
		output_display.clear()
		_line_count = 0
		_parser.reset_state()
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


## Handle OSC (Operating System Command) sequences.
## Emits tab_title_changed for OSC 0 and OSC 2 window-title sequences.
func _handle_osc(body: String) -> void:
	var sep := body.find(";")
	if sep == -1:
		return
	var code_str := body.substr(0, sep)
	var title := body.substr(sep + 1)
	if code_str == "0" or code_str == "2":
		tab_title_changed.emit(title)


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
	_parser.in_alternate_screen = true
	_parser.reset_state()
	if output_display:
		output_display.clear()
	_line_count = 0
	_alt_grid = TerminalGrid.new()
	_alt_grid.resize(_terminal_cols, _terminal_rows)


## Exit alternate screen buffer.
## If restore is true (?1049 semantics), primary buffer content is restored.
## If restore is false (?47/?1047 semantics), display is cleared without restore.
func _exit_alternate_screen(restore: bool) -> void:
	if not _in_alternate_screen:
		return
	_in_alternate_screen = false
	_parser.in_alternate_screen = false
	_alt_grid = null
	_parser.reset_state()
	if output_display:
		output_display.clear()
	_line_count = 0
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
	_get_manager().write_input("\u0003")  # Send real SIGINT via PTY
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
	_get_manager().write_input(trimmed + "\n")
	SignalBus.command_submitted.emit(trimmed)


## Handle output from TerminalManager
func _on_output_ready(text: String) -> void:
	_append_output(text)
	# In mock mode the LineEdit is the input surface and must keep focus;
	# in real PTY mode the input bar is hidden so there's nothing to focus.
	if input_field and _get_manager().is_mock_mode:
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


## Adapter: injected manager's shell_started -> shared status handler.
func _on_shell_started() -> void:
	_on_shell_status_changed(true)


## Adapter: injected manager's shell_stopped -> shared status handler.
func _on_shell_stopped() -> void:
	_on_shell_status_changed(false)


## Handle shell status change
func _on_shell_status_changed(running: bool) -> void:
	if prompt_label:
		prompt_label.modulate = Color.GREEN if running else Color.RED

	if not running:
		_append_output("\n[color=#b58900]Shell exited. Terminal waiting for restart.[/color]\n")


## Update input bar visibility when addon availability is confirmed.
## Guards against a race where _initialize_terminal ran before the autoload
## finished _check_addon_availability and is_mock_mode was still the default.
func _on_addon_status_changed(_available: bool) -> void:
	if _input_bar:
		_input_bar.visible = _get_manager().is_mock_mode


## Apply TerminalSettings font properties to OutputDisplay and recompute
## char_width / line_height for cursor and selection positioning.
## Call this whenever TerminalSettings.font_size or font changes.
func apply_font_settings() -> void:
	# Font must already be loaded before this is called (see _ready).
	# Do NOT call ResourceLoader.load() here -- this function runs after
	# spawn_shell() and blocking the main thread post-spawn races the PTY
	# reader thread in the Rust extension.
	if TerminalSettings.font != null:
		char_width = TerminalSettings.font.get_string_size(
			"M", HORIZONTAL_ALIGNMENT_LEFT, -1, TerminalSettings.font_size
		).x
	else:
		char_width = float(TerminalSettings.font_size) * 0.5
	line_height = float(TerminalSettings.font_size)
	if output_display:
		# Override every RichTextLabel font slot so that bold ([b]), italic ([i]),
		# and mono text all use the same Nerd Font family. Without this, only
		# unstyled text picks up the override; bold segments fall back to the
		# system bold font and display in the wrong typeface.
		const FONT_SLOTS: Array[StringName] = [
			&"normal_font",
			&"bold_font",
			&"italics_font",
			&"bold_italics_font",
			&"mono_font",
		]
		const SIZE_SLOTS: Array[StringName] = [
			&"normal_font_size",
			&"bold_font_size",
			&"italics_font_size",
			&"bold_italics_font_size",
			&"mono_font_size",
		]
		for slot: StringName in FONT_SLOTS:
			if TerminalSettings.font != null:
				output_display.add_theme_font_override(slot, TerminalSettings.font)
			else:
				output_display.remove_theme_font_override(slot)
		for slot: StringName in SIZE_SLOTS:
			output_display.add_theme_font_size_override(slot, TerminalSettings.font_size)
	_update_cursor_overlay()


## Apply TerminalSettings.background_opacity to self_modulate.a.
## Values are clamped to [0.0, 1.0]. Call this whenever the opacity setting changes.
## Note: OS-level window transparency also requires display/window/transparent = true
## in Project Settings, which must be configured manually.
func apply_background_opacity() -> void:
	var c := self_modulate
	c.a = clampf(TerminalSettings.background_opacity, 0.0, 1.0)
	self_modulate = c


## Flash the terminal background to bell_color for BELL_DURATION seconds, then
## restore the previous self_modulate. Optionally emits an audio beep when
## TerminalSettings.audio_bell is true.
func _trigger_visual_bell() -> void:
	if TerminalSettings.audio_bell:
		DisplayServer.beep()
	var original := self_modulate
	self_modulate = bell_color
	var tween := create_tween()
	tween.tween_property(self, "self_modulate", original, BELL_DURATION)


## Apply TerminalSettings.padding as margin insets on the PaddingContainer.
## x maps to left and right; y maps to top and bottom.
func apply_padding() -> void:
	if not padding_container:
		return
	padding_container.add_theme_constant_override("margin_left", TerminalSettings.padding.x)
	padding_container.add_theme_constant_override("margin_right", TerminalSettings.padding.x)
	padding_container.add_theme_constant_override("margin_top", TerminalSettings.padding.y)
	padding_container.add_theme_constant_override("margin_bottom", TerminalSettings.padding.y)


## Handle viewport resize -- compute cols/rows from pixel size and font_size,
## emit SignalBus.terminal_resized, then update TerminalManager.
func _on_viewport_resize() -> void:
	if not _is_ready:
		return
	var size := get_rect().size
	if size.x > 0 and size.y > 0:
		var cols := int(floor(size.x / char_width))
		var rows := int(floor(size.y / line_height))
		cols = clampi(cols, 20, 220)
		rows = clampi(rows, 5, 100)
		_terminal_cols = cols
		_terminal_rows = rows
		SignalBus.terminal_resized.emit(cols, rows)
		if _alt_grid != null:
			_alt_grid.resize(cols, rows)
		_get_manager().resize(cols, rows)


## Handle DECSCUSR -- set cursor style (CSI Ps SP q).
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
			# 0 and unknown -> default blinking block
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
	var base_pos := Vector2(col * char_width, row * line_height)
	match cursor_style:
		CursorStyle.BLINKING_BLOCK, CursorStyle.STEADY_BLOCK:
			cursor_overlay.size = Vector2(char_width, line_height)
			cursor_overlay.position = base_pos
		CursorStyle.BLINKING_UNDERLINE, CursorStyle.STEADY_UNDERLINE:
			cursor_overlay.size = Vector2(char_width, 2.0)
			cursor_overlay.position = base_pos + Vector2(0.0, line_height - 2.0)
		CursorStyle.BLINKING_BAR, CursorStyle.STEADY_BAR:
			cursor_overlay.size = Vector2(2.0, line_height)
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
## Steady cursor styles are unaffected -- they remain always visible.
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
		_blink_timer.wait_time = TerminalSettings.cursor_blink_rate
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
## the system clipboard -- allows unit tests to bypass headless clipboard limits.
func _get_clipboard_text() -> String:
	if not _clipboard_override.is_empty():
		return _clipboard_override
	return DisplayServer.clipboard_get()


## Send text to the terminal as a paste operation.
## When bracketed paste mode is active, wraps text with the DEC markers
## ESC[200~ ... ESC[201~ so the receiving shell can distinguish a paste from
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
	_get_manager().write_input(payload)


func _setup_theme_picker() -> void:
	if not _theme_menu:
		return
	var popup := _theme_menu.get_popup()
	# Ensure a clean popup (avoid duplicate items on scene reloads)
	popup.clear()
	for tname: String in TerminalSettings.BUNDLED_THEME_NAMES:
		popup.add_item(tname)
	if not popup.index_pressed.is_connected(_on_theme_menu_index_pressed):
		popup.index_pressed.connect(_on_theme_menu_index_pressed)


func _setup_font_panel() -> void:
	if _font_option:
		_font_option.clear()
		for fname: String in TerminalSettings.BUNDLED_FONT_NAMES:
			_font_option.add_item(fname)
		var idx: int = TerminalSettings.BUNDLED_FONT_NAMES.find(TerminalSettings.selected_font_name)
		if idx < 0:
			idx = 0
		_font_option.selected = idx
		if not _font_option.item_selected.is_connected(_on_font_family_selected):
			_font_option.item_selected.connect(_on_font_family_selected)
	if _font_spinbox:
		_font_spinbox.min_value = 8.0
		_font_spinbox.max_value = 72.0
		_font_spinbox.step = 1.0
		_font_spinbox.set_value_no_signal(float(TerminalSettings.font_size))
		if not _font_spinbox.value_changed.is_connected(_on_font_size_changed):
			_font_spinbox.value_changed.connect(_on_font_size_changed)


## Update TerminalSettings.font_size from the SpinBox and reflow the terminal.
func _on_font_size_changed(value: float) -> void:
	TerminalSettings.font_size = int(value)
	apply_font_settings()


## Update TerminalSettings.font from the OptionButton selection and reflow.
func _on_font_family_selected(index: int) -> void:
	var fname: String = TerminalSettings.BUNDLED_FONT_NAMES[index]
	TerminalSettings.selected_font_name = fname
	if fname == "Default":
		TerminalSettings.font = null
	else:
		var path: String = TerminalSettings.BUNDLED_FONT_PATHS.get(fname, "")
		if path != "":
			TerminalSettings.font = load(path)
		else:
			TerminalSettings.font = null
	apply_font_settings()


func _on_theme_menu_index_pressed(index: int) -> void:
	TerminalSettings.selected_theme_name = TerminalSettings.BUNDLED_THEME_NAMES[index]
	_load_and_apply_theme(TerminalSettings.selected_theme_name)


func _load_and_apply_theme(tname: String) -> void:
	if tname.is_empty():
		tname = TerminalSettings.BUNDLED_THEME_NAMES[0]
	var slug: String = tname.to_lower().replace(" ", "_")
	if tname == TerminalSettings.BUNDLED_THEME_NAMES[0]:
		slug = "default_theme"
	var path: String = "res://resources/themes/%s.tres" % slug
	var t := ResourceLoader.load(path) as TerminalTheme
	if t != null:
		_get_manager().current_theme = t


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
	if SignalBus.addon_status_changed.is_connected(_on_addon_status_changed):
		SignalBus.addon_status_changed.disconnect(_on_addon_status_changed)
	if manager != null and is_instance_valid(manager):
		if manager.output_received.is_connected(_on_output_ready):
			manager.output_received.disconnect(_on_output_ready)
		if manager.shell_started.is_connected(_on_shell_started):
			manager.shell_started.disconnect(_on_shell_started)
		if manager.shell_stopped.is_connected(_on_shell_stopped):
			manager.shell_stopped.disconnect(_on_shell_stopped)
		if (
			manager.has_signal("terminal_cleared")
			and manager.terminal_cleared.is_connected(_on_terminal_cleared)
		):
			manager.terminal_cleared.disconnect(_on_terminal_cleared)
	var mgr := _get_manager()
	if mgr.theme_changed.is_connected(_on_theme_changed):
		mgr.theme_changed.disconnect(_on_theme_changed)
	if input_field and input_field.text_submitted.is_connected(_on_text_submitted):
		input_field.text_submitted.disconnect(_on_text_submitted)
	var root = null
	if get_tree():
		root = get_tree().get_root()
	if is_connected("resized", _on_viewport_resize):
		resized.disconnect(_on_viewport_resize)
	if root and root.size_changed.is_connected(_on_viewport_resize):
		root.size_changed.disconnect(_on_viewport_resize)
	if _context_menu and _context_menu.id_pressed.is_connected(_on_context_menu_id_pressed):
		_context_menu.id_pressed.disconnect(_on_context_menu_id_pressed)
	if _theme_menu:
		var popup := _theme_menu.get_popup()
		if popup.index_pressed.is_connected(_on_theme_menu_index_pressed):
			popup.index_pressed.disconnect(_on_theme_menu_index_pressed)
	if _font_option and _font_option.item_selected.is_connected(_on_font_family_selected):
		_font_option.item_selected.disconnect(_on_font_family_selected)
	if _font_spinbox and _font_spinbox.value_changed.is_connected(_on_font_size_changed):
		_font_spinbox.value_changed.disconnect(_on_font_size_changed)
	if search_bar and search_bar.search_canceled.is_connected(_on_search_canceled):
		search_bar.search_canceled.disconnect(_on_search_canceled)
	if search_bar and search_bar.search_submitted.is_connected(_on_search_submitted):
		search_bar.search_submitted.disconnect(_on_search_submitted)
	if search_bar and search_bar.navigate_next.is_connected(_on_navigate_next):
		search_bar.navigate_next.disconnect(_on_navigate_next)
	if search_bar and search_bar.navigate_prev.is_connected(_on_navigate_prev):
		search_bar.navigate_prev.disconnect(_on_navigate_prev)


## Called when the search bar emits search_canceled (Escape or hide_search()).
## Clears the search highlight count and restores the un-highlighted rendering.
func _on_search_canceled() -> void:
	_search_highlight_count = 0
	_search_matches.clear()
	_search_match_index = -1
	_last_search_query = ""
	if output_display and not _in_alternate_screen:
		output_display.clear()
		output_display.append_text(_output_accumulator)


## Called when the search bar emits search_submitted (query text changed or Enter pressed).
## Runs search_scrollback and updates the match-count display on the SearchBar.
func _on_search_submitted(query: String) -> void:
	var use_regex: bool = false
	if search_bar:
		use_regex = search_bar.regex_enabled
	var matches: Array[Vector2i] = search_scrollback(query, use_regex)
	if search_bar:
		search_bar.set_match_display(0, matches.size())


## Advance to the next search match (wraps from last to first).
func _on_navigate_next() -> void:
	_navigate_search_match(1)


## Move to the previous search match (wraps from first to last).
func _on_navigate_prev() -> void:
	_navigate_search_match(-1)


## Advance or retreat the current match by direction (+1 or -1), wrap around,
## re-render with accent on the selected match, scroll to its line, and
## update the SearchBar match-count label.
func _navigate_search_match(direction: int) -> void:
	var total: int = _search_matches.size()
	if total == 0:
		return
	if _search_match_index == -1:
		_search_match_index = 0 if direction > 0 else total - 1
	else:
		_search_match_index = (_search_match_index + direction + total) % total
	_render_highlighted_scrollback()
	_scroll_to_match_line(_search_matches[_search_match_index].x)
	if search_bar:
		search_bar.set_match_display(_search_match_index + 1, total)


## Scroll the ScrollContainer so the given line index is visible.
func _scroll_to_match_line(line_idx: int) -> void:
	if scroll_container:
		scroll_container.scroll_vertical = int(float(line_idx) * line_height)


## Search the scrollback buffer for all occurrences of query.
## Plain search is case-insensitive by default. Set use_regex=true for regex mode.
## Returns an Array[Vector2i] where each entry is (line_index, col_index).
## Also re-renders the output with match highlights and updates _search_highlight_count.
## Resets _search_match_index to -1 (no match selected) on each new search.
func search_scrollback(query: String, use_regex: bool = false) -> Array[Vector2i]:
	_search_matches.clear()
	_search_match_index = -1
	_last_search_query = query
	_last_search_use_regex = use_regex
	if query.is_empty():
		_search_highlight_count = 0
		return _search_matches
	var re: RegEx = null
	if use_regex:
		re = RegEx.new()
		if re.compile(query) != OK:
			_search_highlight_count = 0
			return _search_matches
	var lines := _raw_accumulator.split("\n")
	for line_idx: int in range(lines.size()):
		var plain: String = AnsiParser.strip_ansi(lines[line_idx])
		if use_regex and re != null:
			for m: RegExMatch in re.search_all(plain):
				_search_matches.append(Vector2i(line_idx, m.get_start()))
		else:
			var lower_plain: String = plain.to_lower()
			var lower_query: String = query.to_lower()
			var q_len: int = lower_query.length()
			var pos: int = 0
			while true:
				var idx: int = lower_plain.find(lower_query, pos)
				if idx == -1:
					break
				_search_matches.append(Vector2i(line_idx, idx))
				pos = idx + q_len
	_search_highlight_count = _search_matches.size()
	_render_highlighted_scrollback()
	return _search_matches


## Return a BBCode string for line_text with [bgcolor=][/bgcolor] tags wrapped
## around every occurrence of query. Uses case-insensitive plain search by
## default; set use_regex=true for regex mode. Non-matching text is xml_escaped.
## accent_col: column of the match to highlight with SEARCH_ACCENT_BG; all
## other matches use SEARCH_HIGHLIGHT_BG. Pass -1 (default) for no accent.
func get_highlighted_line(
	line_text: String, query: String, use_regex: bool = false, accent_col: int = -1
) -> String:
	if query.is_empty() or line_text.is_empty():
		return AnsiParser.escape_bbcode_text(line_text)
	if use_regex:
		var re := RegEx.new()
		if re.compile(query) != OK:
			return AnsiParser.escape_bbcode_text(line_text)
		var result := ""
		var pos: int = 0
		for m: RegExMatch in re.search_all(line_text):
			result += AnsiParser.escape_bbcode_text(line_text.substr(pos, m.get_start() - pos))
			var bg: String = (
				SEARCH_ACCENT_BG if m.get_start() == accent_col else SEARCH_HIGHLIGHT_BG
			)
			result += "[bgcolor=%s]" % bg
			result += AnsiParser.escape_bbcode_text(m.get_string())
			result += "[/bgcolor]"
			pos = m.get_start() + m.get_string().length()
		result += AnsiParser.escape_bbcode_text(line_text.substr(pos))
		return result
	# Plain case-insensitive search
	var lower_line: String = line_text.to_lower()
	var lower_query: String = query.to_lower()
	var q_len: int = lower_query.length()
	var result := ""
	var pos: int = 0
	while true:
		var idx: int = lower_line.find(lower_query, pos)
		if idx == -1:
			result += AnsiParser.escape_bbcode_text(line_text.substr(pos))
			break
		result += AnsiParser.escape_bbcode_text(line_text.substr(pos, idx - pos))
		var bg: String = SEARCH_ACCENT_BG if idx == accent_col else SEARCH_HIGHLIGHT_BG
		result += "[bgcolor=%s]" % bg
		result += AnsiParser.escape_bbcode_text(line_text.substr(idx, q_len))
		result += "[/bgcolor]"
		pos = idx + q_len
	return result


## Re-render the primary scrollback with search highlights injected.
## Matching lines are shown as plain text with [bgcolor=] tags; non-matching
## lines are also shown as plain text (ANSI colour is dropped while a search
## is active, which keeps the renderer simple and allocation-free).
## The match at _search_match_index is highlighted with SEARCH_ACCENT_BG.
func _render_highlighted_scrollback() -> void:
	if not output_display or _in_alternate_screen:
		return
	output_display.clear()
	if _search_matches.is_empty():
		output_display.append_text(_output_accumulator)
		return
	var current_line: int = -1
	var current_col: int = -1
	if _search_match_index >= 0 and _search_match_index < _search_matches.size():
		current_line = _search_matches[_search_match_index].x
		current_col = _search_matches[_search_match_index].y
	var matched_lines: Dictionary = {}
	for m: Vector2i in _search_matches:
		matched_lines[m.x] = true
	var lines := _raw_accumulator.split("\n")
	for line_idx: int in range(lines.size()):
		var plain: String = AnsiParser.strip_ansi(lines[line_idx])
		if matched_lines.has(line_idx):
			var accent: int = current_col if line_idx == current_line else -1
			output_display.append_text(
				get_highlighted_line(plain, _last_search_query, _last_search_use_regex, accent)
			)
		else:
			output_display.append_text(AnsiParser.escape_bbcode_text(plain))
		if line_idx < lines.size() - 1:
			output_display.append_text("\n")
