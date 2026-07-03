## AnsiParser -- streaming ANSI/VT100 to BBCode converter.
##
## Extracted from TerminalView (fable_review.md section 3.3) so the parser can
## be unit-tested without a scene and reused by future renderers.
##
## Owns the SGR rendering state (colors, bold, italic, underline, reverse,
## strikethrough), cross-chunk partial-escape buffering, and the line-rewrite
## (standalone CR) detection flag. Emits signals for everything that concerns
## the view (cursor movement, erase, private modes, OSC titles, bell,
## alt-screen character mirroring); signals are synchronous in Godot, so the
## dispatch order is identical to the previous inline implementation.
##
## BBCode tag invariant: generated tags are line-local and chunk-local --
## closed before every newline and at the end of every parse() call, reopened
## after / at the start of the next call. Consumers may therefore cut the
## generated BBCode at any newline boundary without dangling tags.
class_name AnsiParser
extends RefCounted

## Emitted for CSI commands the parser does not consume itself
## (J, K, H, f, A, B, C, D, h, l, q). params is the raw parameter string.
signal csi_received(cmd: String, params: String)

## Emitted for OSC sequences; body is the text between ESC] and the terminator.
signal osc_received(body: String)

## Emitted when a BEL (0x07) control character is received.
signal bell_received

## Emitted for every printable character while in_alternate_screen is true.
## cell is a TerminalGrid-compatible cell dictionary built from current state.
signal alt_char_written(cell: Dictionary)

const ESC: String = char(27)
const BEL: String = char(7)
const BS: String = char(8)

## Cached compiled RegEx for strip_ansi (compiled on first use).
static var _strip_re: RegEx = null

## Set true by the consumer while the alternate screen is active. Gates the
## line-rewrite flag and alt_char_written emission.
var in_alternate_screen: bool = false

## Set when a standalone CR (line-rewrite intent) is parsed in primary mode.
## The consumer checks and resets this after each parse() call.
var pending_line_clear: bool = false

## Returns the active 16-entry ANSI palette (Array[Color]). Assigned by the
## consumer; when invalid, a fallback gray is used for indexed colors.
var palette_provider: Callable = Callable()

var _current_fg: String = ""
var _current_bg: String = ""
var _current_bold: bool = false
var _current_italic: bool = false
var _current_underline: bool = false
var _current_strike: bool = false
var _current_reverse: bool = false
var _partial_escape: String = ""


## Reset all SGR state and drop any buffered partial escape and pending flags.
func reset_state() -> void:
	_current_fg = ""
	_current_bg = ""
	_current_bold = false
	_current_italic = false
	_current_underline = false
	_current_strike = false
	_current_reverse = false
	_partial_escape = ""
	pending_line_clear = false


## Parse a chunk of terminal output and return the BBCode to append.
## Handles combined SGR codes like ESC[1;32m and full 256/truecolor.
func parse(text: String) -> String:
	# Combine with any partial escape from the last chunk.
	var input := _partial_escape + text
	_partial_escape = ""

	# Reopen the tags that were textually closed at the previous chunk
	# boundary (see the tag invariant in the class docstring).
	var output := _open_active_tags()
	var i := 0
	while i < input.length():
		var ch := input[i]

		if ch == ESC:
			var rest := input.substr(i)
			# Buffer bare ESC or ESC[ with nothing following (incomplete CSI
			# prefix). Do NOT buffer OSC (ESC]) or other 2+ char sequences
			# here -- the specific branches below handle them.
			if rest.length() == 1 or (rest[1] == "[" and rest.length() == 2):
				_partial_escape = rest
				break

			if rest.length() > 1 and rest[1] == "[":
				var end_pos := -1
				for j in range(2, rest.length()):
					var c := rest[j]
					if (c >= "A" and c <= "Z") or (c >= "a" and c <= "z"):
						end_pos = j
						break
				if end_pos == -1:
					# Incomplete sequence -- buffer it.
					_partial_escape = rest
					break
				var cmd := rest[end_pos]
				var params_str := rest.substr(2, end_pos - 2)
				if cmd == "m":
					output += _handle_sgr(params_str)
				else:
					# Erase-display mode 2 in primary mode wipes the display;
					# close open tags in the output stream first (this also
					# resets the SGR state, matching a fresh screen).
					if cmd == "J" and not in_alternate_screen:
						var mode_j := 0
						if params_str != "":
							mode_j = int(params_str)
						if mode_j == 2:
							output += _close_all_tags()
					csi_received.emit(cmd, params_str)
				i += end_pos + 1
				continue

			elif rest.length() > 1 and rest[1] == "]":
				# OSC sequence -- find ST (BEL or ESC-backslash).
				var osc_content_end := rest.find(BEL)
				var st_len := 1
				if osc_content_end == -1:
					var st_pos := rest.find(ESC + "\\")
					if st_pos != -1:
						osc_content_end = st_pos
						st_len = 2
				if osc_content_end == -1:
					_partial_escape = rest
					break
				var osc_body := rest.substr(2, osc_content_end - 2)
				osc_received.emit(osc_body)
				i += osc_content_end + st_len
				continue

			else:
				# Unknown escape type -- skip one char.
				i += 2
				continue

		elif ch == "\r":
			# Carriage return: CRLF is an ordinary line ending; a bare CR
			# means the shell is rewriting the current line (ZSH/readline/
			# Starship prompt redraws). Clear the current output line so the
			# replacement overwrites rather than appends.
			if i + 1 < input.length() and input[i + 1] == "\n":
				i += 1
				continue
			var last_newline := output.rfind("\n")
			if last_newline != -1:
				output = output.substr(0, last_newline + 1)
			else:
				output = ""
			# The truncation dropped any tag-opens on the discarded text;
			# re-emit the active tags so subsequent text stays styled.
			output += _open_active_tags()
			if not in_alternate_screen:
				pending_line_clear = true
			i += 1
			continue
		elif ch == "\n":
			# Close open tags before the newline and reopen after it so every
			# line of generated BBCode is self-contained (safe to trim).
			output += _emit_closing_tags() + "\n" + _open_active_tags()
			i += 1
			continue
		elif ch == BS:
			if output.length() > 0:
				output = output.substr(0, output.length() - 1)
			i += 1
			continue
		elif ch == BEL:
			bell_received.emit()
			i += 1
			continue
		else:
			# xml_escape handles &<>" but not [ or ], which Godot treats as
			# BBCode tag delimiters -- escape them so literal brackets in
			# terminal output never leak as (or break) BBCode tags.
			output += escape_bbcode_text(ch)
			if in_alternate_screen:
				alt_char_written.emit(make_cell(ch))
			i += 1

	# Close any open tags at the chunk boundary; the next call reopens them.
	return output + _emit_closing_tags()


## Handle SGR (Select Graphic Rendition) codes.
## Two-pass: first compute the fully-desired new state from all codes in the
## sequence, then emit a single close-all / reopen diff. This prevents
## orphaned tags from compound sequences (e.g. bgcolor + fgcolor in one CSI).
func _handle_sgr(params_str: String) -> String:
	var new_fg := _current_fg
	var new_bg := _current_bg
	var new_bold := _current_bold
	var new_italic := _current_italic
	var new_underline := _current_underline
	var new_strike := _current_strike
	var new_reverse := _current_reverse

	if params_str == "" or params_str == "0":
		new_fg = ""
		new_bg = ""
		new_bold = false
		new_italic = false
		new_underline = false
		new_strike = false
		new_reverse = false
	else:
		var codes := params_str.split(";")
		var idx := 0
		while idx < codes.size():
			var code := int(codes[idx])
			match code:
				0:
					new_fg = ""
					new_bg = ""
					new_bold = false
					new_italic = false
					new_underline = false
					new_strike = false
					new_reverse = false
				1:
					new_bold = true
				3:
					new_italic = true
				4:
					new_underline = true
				7:
					new_reverse = true
				9:
					new_strike = true
				22:
					new_bold = false
				23:
					new_italic = false
				24:
					new_underline = false
				27:
					new_reverse = false
				29:
					new_strike = false
				30, 31, 32, 33, 34, 35, 36, 37:
					new_fg = _indexed_color(code - 30)
				39:
					new_fg = ""
				40, 41, 42, 43, 44, 45, 46, 47:
					new_bg = _indexed_color(code - 40)
				49:
					new_bg = ""
				90, 91, 92, 93, 94, 95, 96, 97:
					new_fg = _indexed_color(code - 90 + 8)
				38:
					if idx + 2 < codes.size() and int(codes[idx + 1]) == 5:
						new_fg = xterm256_hex(int(codes[idx + 2]))
						idx += 2
					elif idx + 4 < codes.size() and int(codes[idx + 1]) == 2:
						new_fg = (
							"#%02x%02x%02x"
							% [int(codes[idx + 2]), int(codes[idx + 3]), int(codes[idx + 4])]
						)
						idx += 4
				48:
					if idx + 2 < codes.size() and int(codes[idx + 1]) == 5:
						new_bg = xterm256_hex(int(codes[idx + 2]))
						idx += 2
					elif idx + 4 < codes.size() and int(codes[idx + 1]) == 2:
						new_bg = (
							"#%02x%02x%02x"
							% [int(codes[idx + 2]), int(codes[idx + 3]), int(codes[idx + 4])]
						)
						idx += 4
				100, 101, 102, 103, 104, 105, 106, 107:
					new_bg = _indexed_color(code - 100 + 8)
			idx += 1

	var changed: bool = (
		new_fg != _current_fg
		or new_bg != _current_bg
		or new_bold != _current_bold
		or new_italic != _current_italic
		or new_underline != _current_underline
		or new_strike != _current_strike
		or new_reverse != _current_reverse
	)
	if not changed:
		return ""

	# Close all open tags in LIFO order, apply new state, reopen in FIFO order.
	var result := _close_all_tags()
	_current_fg = new_fg
	_current_bg = new_bg
	_current_bold = new_bold
	_current_italic = new_italic
	_current_underline = new_underline
	_current_strike = new_strike
	_current_reverse = new_reverse
	result += _open_active_tags()
	return result


## Effective foreground after reverse video is applied.
## Reverse with no explicit colors inverts the default white-on-black.
func _effective_fg() -> String:
	if not _current_reverse:
		return _current_fg
	return _current_bg if not _current_bg.is_empty() else "#000000"


## Effective background after reverse video is applied.
func _effective_bg() -> String:
	if not _current_reverse:
		return _current_bg
	return _current_fg if not _current_fg.is_empty() else "#ffffff"


## Close all open BBCode tags in LIFO order.
## Clears all state variables as a side effect.
func _close_all_tags() -> String:
	var r := _emit_closing_tags()
	_current_fg = ""
	_current_bg = ""
	_current_bold = false
	_current_italic = false
	_current_underline = false
	_current_strike = false
	_current_reverse = false
	return r


## Emit closing tags for all currently-open tags in LIFO order WITHOUT
## mutating the SGR state. Used to keep BBCode chunk-local and line-local.
func _emit_closing_tags() -> String:
	var r := ""
	if not _effective_bg().is_empty():
		r += "[/bgcolor]"
	if not _effective_fg().is_empty():
		r += "[/color]"
	if _current_strike:
		r += "[/s]"
	if _current_underline:
		r += "[/u]"
	if _current_italic:
		r += "[/i]"
	if _current_bold:
		r += "[/b]"
	return r


## Open the currently-active BBCode tags in FIFO order:
## bold, italic, underline, strikethrough, color, bgcolor.
func _open_active_tags() -> String:
	var r := ""
	if _current_bold:
		r += "[b]"
	if _current_italic:
		r += "[i]"
	if _current_underline:
		r += "[u]"
	if _current_strike:
		r += "[s]"
	if not _effective_fg().is_empty():
		r += "[color=%s]" % _effective_fg()
	if not _effective_bg().is_empty():
		r += "[bgcolor=%s]" % _effective_bg()
	return r


## Build a TerminalGrid cell dictionary from the current SGR rendering state.
func make_cell(ch: String) -> Dictionary:
	var fg := Color.WHITE
	if not _effective_fg().is_empty():
		fg = Color.html(_effective_fg())
	var bg := Color.BLACK
	if not _effective_bg().is_empty():
		bg = Color.html(_effective_bg())
	return {
		"char": ch,
		"fg": fg,
		"bg": bg,
		"bold": _current_bold,
		"italic": _current_italic,
		"underline": _current_underline,
		"url": "",
	}


## Map an ANSI color index (0-15) to a hex color string via palette_provider.
func _indexed_color(idx: int) -> String:
	if palette_provider.is_valid():
		var palette: Array[Color] = palette_provider.call()
		if idx >= 0 and idx < palette.size():
			return "#" + palette[idx].to_html(false)
	return "#aaaaaa"


## Convert an xterm-256 index to a hex color string.
func xterm256_hex(idx: int) -> String:
	if idx < 16:
		return _indexed_color(idx)
	if idx < 232:
		var i := idx - 16
		var r := _xterm_cube_channel((i / 36) % 6)
		var g := _xterm_cube_channel((i / 6) % 6)
		var b := _xterm_cube_channel(i % 6)
		return "#%02x%02x%02x" % [r, g, b]
	var v := 8 + (idx - 232) * 10
	return "#%02x%02x%02x" % [v, v, v]


## Map a 0-5 xterm color-cube step to its channel value.
## The xterm ramp is 0, 95, 135, 175, 215, 255 (55 + 40n for n > 0), not a
## linear multiple of 51.
func _xterm_cube_channel(n: int) -> int:
	return 0 if n == 0 else 55 + n * 40


## Escape text for safe embedding in RichTextLabel BBCode: XML entities plus
## literal square brackets (Godot treats bare [ and ] as tag delimiters).
##
## Iterates char-by-char so a replacement never re-escapes its own output
## (chained .replace() would turn a single `[` into `[lb[rb]` because the
## inserted `]` inside `[lb]` would be immediately re-escaped).
static func escape_bbcode_text(text: String) -> String:
	var escaped := text.xml_escape()
	var result := ""
	for ch: String in escaped:
		match ch:
			"[":
				result += "[lb]"
			"]":
				result += "[rb]"
			_:
				result += ch
	return result


## Strip ANSI / VT100 escape sequences from text, returning plain Unicode.
## The RegEx is compiled once and cached -- this runs per line in search loops.
static func strip_ansi(text: String) -> String:
	if _strip_re == null:
		var re := RegEx.new()
		# [[] and []] are bracket literals inside character classes -- written
		# this way to avoid backslash escapes.
		if re.compile(ESC + "([[][0-9;?]*[A-Za-z]|[]][^" + BEL + "]*" + BEL + "|.)") != OK:
			return text
		_strip_re = re
	return _strip_re.sub(text, "", true)
