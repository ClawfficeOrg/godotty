# GdUnit4 test: Carriage-return line-rewrite behaviour in TerminalView.
#
# A bare CR (\r not followed by \n) means "move cursor to column 0" — the
# shell is about to overwrite the current line.  The streaming text renderer
# must therefore *clear* the current line from the output buffer so that the
# replacement text replaces it rather than being appended after it.
#
# Bug context: ZSH/Starship redraws the prompt with sequences like
#   \r\033[K<new-prompt>        (CR + Erase-Line + new text)
#   \r\033[?2004h<new-prompt>   (CR + private-mode toggle + new text)
# Because \033 immediately follows \r, the old guard
#   `elif next_ch != "\u001b"`
# prevented line clearing.  The old line content remained in the output and
# the new prompt was appended after it.  Since both the old and new prompt
# begin with the same character (e.g. "~" from the cwd) this looks like a
# doubled first character.
#
# All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")
const ESC := "\u001b"

var _view: TerminalView


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# CR before plain text replaces the current line
# ---------------------------------------------------------------------------


func test_cr_before_text_replaces_line() -> void:
	# Classic overwrite: write "old", then CR + "new" — output must be "new".
	SignalBus.output_ready.emit("old\rnew")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).is_equal("new")


func test_cr_before_text_does_not_duplicate_first_char() -> void:
	# Minimal reproduction of the "doubled first character" report:
	# emit "~" then CR + "~/" — must not produce "~~/"
	SignalBus.output_ready.emit("~\r~/")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).is_equal("~/")


# ---------------------------------------------------------------------------
# CR before escape sequence — the original failing case
# ---------------------------------------------------------------------------


func test_cr_before_sgr_clears_current_line() -> void:
	# Shell sends old text, then rewrites with CR + SGR colour + new text.
	# Must NOT keep the old text.
	SignalBus.output_ready.emit("old text\r" + ESC + "[32mnew text" + ESC + "[0m")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	# "old text" must be gone
	assert_bool(bbcode.contains("old text")).is_false()
	# "new text" must be present
	assert_str(bbcode).contains("new text")


func test_cr_before_erase_line_then_text() -> void:
	# ZSH/readline pattern: \r\033[K<new prompt>
	# EL (ESC[K) is a no-op in primary mode, but the CR must still clear the line.
	# Use non-overlapping strings without xml-escaped chars so contains() is unambiguous.
	SignalBus.output_ready.emit("OLD_PS1 \r" + ESC + "[KNEW_PS1 ")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	# Old prompt must be gone
	assert_bool(bbcode.contains("OLD_PS1 ")).is_false()
	assert_str(bbcode).contains("NEW_PS1 ")


func test_cr_before_private_mode_escape_clears_line() -> void:
	# Starship / bracketed-paste toggle: \r\033[?2004h<prompt>
	SignalBus.output_ready.emit("old_prompt\r" + ESC + "[?2004hnew_prompt")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_bool(bbcode.contains("old_prompt")).is_false()
	assert_str(bbcode).contains("new_prompt")


func test_cr_before_csi_cursor_move_then_text() -> void:
	# ZSH sometimes sends: \r\033[1A\033[1000D\033[K<prompt>
	# (cursor up, cursor far left, erase line, then prompt text)
	SignalBus.output_ready.emit(
		"stale line\r" + ESC + "[1A" + ESC + "[1000D" + ESC + "[Kfresh line"
	)
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_bool(bbcode.contains("stale line")).is_false()
	assert_str(bbcode).contains("fresh line")


# ---------------------------------------------------------------------------
# CR at end of chunk (no look-ahead) must also clear the line
# ---------------------------------------------------------------------------


func test_cr_at_end_of_chunk_clears_line() -> void:
	# When CR arrives as the last byte of a PTY read chunk, there is no next
	# character to look ahead at.  The line must still be cleared so the next
	# chunk's content replaces it.
	SignalBus.output_ready.emit("first line\r")
	await get_tree().process_frame
	# Now send the replacement text in a separate chunk.
	SignalBus.output_ready.emit("replaced line")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_bool(bbcode.contains("first line")).is_false()
	assert_str(bbcode).contains("replaced line")


# ---------------------------------------------------------------------------
# \r\n sequences must NOT clear the line — they are ordinary line endings
# ---------------------------------------------------------------------------


func test_crlf_does_not_clear_previous_line() -> void:
	# \r\n is a standard line ending; the line before it must be preserved.
	SignalBus.output_ready.emit("line one\r\nline two\r\n")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).contains("line one")
	assert_str(bbcode).contains("line two")


func test_crlf_sequence_produces_two_lines() -> void:
	SignalBus.output_ready.emit("alpha\r\nbeta\r\n")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).is_equal("alpha\nbeta\n")


# ---------------------------------------------------------------------------
# Multi-line: CR only clears the CURRENT line, not previous lines
# ---------------------------------------------------------------------------


func test_cr_does_not_clobber_previous_lines() -> void:
	SignalBus.output_ready.emit("line one\nline two\rrewritten two")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	# "line one" is on a previous line and must survive
	assert_str(bbcode).contains("line one")
	# "line two" was the current line and must be replaced
	assert_bool(bbcode.contains("line two")).is_false()
	assert_str(bbcode).contains("rewritten two")


# ---------------------------------------------------------------------------
# Cross-chunk line rewrites
# A CR arriving in chunk N must also clear the partial line already committed
# to _output_accumulator / output_display by earlier chunk(s).
# ---------------------------------------------------------------------------


func test_cross_chunk_cr_plain_text() -> void:
	# Chunk 1: shell echoes the first keystroke ("l").
	# Chunk 2: shell redraws the whole line with CR ("\rls").
	# Expected: display shows "ls", NOT "lls".
	SignalBus.output_ready.emit("l")
	await get_tree().process_frame
	SignalBus.output_ready.emit("\rls")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).is_equal("ls")


func test_cross_chunk_cr_erase_then_text() -> void:
	# ZSH/readline pattern split across two PTY reads:
	# chunk 1: "first"
	# chunk 2: "\r\033[Kfresh"  (CR + EL + new text)
	# Expected: "fresh" only — "first" must be gone.
	SignalBus.output_ready.emit("first")
	await get_tree().process_frame
	SignalBus.output_ready.emit("\r" + ESC + "[Kfresh")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_bool(bbcode.contains("first")).is_false()
	assert_str(bbcode).contains("fresh")


func test_cross_chunk_cr_preserves_previous_lines() -> void:
	# A completed line (terminated with \n) must survive a cross-chunk
	# rewrite of the current (partial) line.
	SignalBus.output_ready.emit("complete line\n")
	await get_tree().process_frame
	SignalBus.output_ready.emit("part")
	await get_tree().process_frame
	SignalBus.output_ready.emit("\rreplace")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).contains("complete line")
	assert_bool(bbcode.contains("part")).is_false()
	assert_str(bbcode).contains("replace")


func test_cross_chunk_cr_with_color_in_second_chunk() -> void:
	# Chunk 1: plain echo.  Chunk 2: CR + SGR color + replacement + reset.
	# Expected: colored "newval" only — "old" must be gone.
	SignalBus.output_ready.emit("old")
	await get_tree().process_frame
	SignalBus.output_ready.emit("\r" + ESC + "[32mnewval" + ESC + "[0m")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_bool(bbcode.contains("old")).is_false()
	assert_str(bbcode).contains("newval")
