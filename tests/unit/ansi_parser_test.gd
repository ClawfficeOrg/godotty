# GdUnit4 test: AnsiParser -- scene-free unit coverage of the extracted parser.
#
# Covers:
#   - SGR italic (3/23), reverse video (7/27), strikethrough (9/29) --
#     fable_review.md section 3.7 gaps.
#   - Reverse video swaps effective fg/bg (default inversion when unset).
#   - Tag invariant: tags are closed at newline and chunk boundaries.
#   - Partial escapes buffer across parse() calls.
#   - CSI/OSC/bell signal dispatch.
#   - make_cell carries italic/underline into grid cells.
#
# No scene required -- AnsiParser is a RefCounted.
extends GdUnitTestSuite

const ESC := char(27)
const BEL := char(7)

var _parser: AnsiParser


func before_test() -> void:
	_parser = AnsiParser.new()


# ---------------------------------------------------------------------------
# New SGR attributes
# ---------------------------------------------------------------------------


func test_sgr_3_italic_wraps_in_i_tags() -> void:
	var out := _parser.parse(ESC + "[3mslanted" + ESC + "[23mplain")
	assert_str(out).contains("[i]slanted[/i]")
	assert_bool(out.contains("[i]plain")).is_false()


func test_sgr_9_strikethrough_wraps_in_s_tags() -> void:
	var out := _parser.parse(ESC + "[9mgone" + ESC + "[29mkept")
	assert_str(out).contains("[s]gone[/s]")
	assert_bool(out.contains("[s]kept")).is_false()


func test_sgr_7_reverse_swaps_explicit_colors() -> void:
	# red fg + blue bg reversed -> blue fg + red bg
	var out := _parser.parse(ESC + "[38;2;255;0;0m" + ESC + "[48;2;0;0;255m" + ESC + "[7mX")
	assert_str(out).contains("[color=#0000ff]")
	assert_str(out).contains("[bgcolor=#ff0000]")


func test_sgr_7_reverse_without_colors_inverts_defaults() -> void:
	var out := _parser.parse(ESC + "[7mX" + ESC + "[27mY")
	assert_str(out).contains("[color=#000000]")
	assert_str(out).contains("[bgcolor=#ffffff]")


func test_sgr_0_resets_new_attributes() -> void:
	var out := _parser.parse(ESC + "[3;9;7mstyled" + ESC + "[0mplain")
	# After reset, "plain" must not be inside any tag.
	assert_str(out).ends_with("plain")


# ---------------------------------------------------------------------------
# Tag invariant (line-local / chunk-local)
# ---------------------------------------------------------------------------


func test_tags_closed_before_newline_and_reopened_after() -> void:
	var out := _parser.parse(ESC + "[31mred1\nred2")
	var nl := out.find("\n")
	assert_bool(out.substr(0, nl).ends_with("[/color]")).is_true()
	assert_bool(out.substr(nl + 1).begins_with("[color=")).is_true()


func test_tags_closed_at_chunk_end_and_reopened_next_chunk() -> void:
	var first := _parser.parse(ESC + "[31mred")
	assert_bool(first.ends_with("[/color]")).is_true()
	var second := _parser.parse("more")
	assert_bool(second.begins_with("[color=")).is_true()


# ---------------------------------------------------------------------------
# Partial escapes and control chars
# ---------------------------------------------------------------------------


func test_partial_escape_buffers_across_chunks() -> void:
	var first := _parser.parse("a" + ESC)
	var second := _parser.parse("[31mb")
	assert_str(first).is_equal("a")
	assert_str(second).contains("[color=")
	assert_str(second).contains("b")


func test_bare_cr_sets_pending_line_clear() -> void:
	_parser.parse("old")
	_parser.parse("\rnew")
	assert_bool(_parser.pending_line_clear).is_true()


func test_crlf_does_not_set_pending_line_clear() -> void:
	_parser.parse("line\r\n")
	assert_bool(_parser.pending_line_clear).is_false()


# ---------------------------------------------------------------------------
# Signal dispatch
# ---------------------------------------------------------------------------


func test_csi_signal_emitted_for_cursor_home() -> void:
	var received: Array = []
	_parser.csi_received.connect(func(cmd: String, params: String) -> void:
		received.append([cmd, params]))
	_parser.parse(ESC + "[3;7H")
	assert_int(received.size()).is_equal(1)
	assert_str(received[0][0]).is_equal("H")
	assert_str(received[0][1]).is_equal("3;7")


func test_osc_signal_emitted_with_body() -> void:
	var bodies: Array = []
	_parser.osc_received.connect(func(body: String) -> void: bodies.append(body))
	_parser.parse(ESC + "]0;my title" + BEL)
	assert_int(bodies.size()).is_equal(1)
	assert_str(bodies[0]).is_equal("0;my title")


func test_bell_signal_emitted() -> void:
	var count: Array = [0]
	_parser.bell_received.connect(func() -> void: count[0] += 1)
	_parser.parse("ding" + BEL)
	assert_int(count[0]).is_equal(1)


# ---------------------------------------------------------------------------
# Cell building
# ---------------------------------------------------------------------------


func test_make_cell_carries_italic_and_underline() -> void:
	_parser.parse(ESC + "[3;4m")
	var cell := _parser.make_cell("x")
	assert_bool(cell["italic"]).is_true()
	assert_bool(cell["underline"]).is_true()
	assert_str(cell["char"]).is_equal("x")


func test_escape_bbcode_text_escapes_brackets() -> void:
	assert_str(AnsiParser.escape_bbcode_text("[a]<b>")).is_equal("[lb]a[rb]&lt;b&gt;")


func test_strip_ansi_removes_sgr_and_osc() -> void:
	var noisy := ESC + "[31mred" + ESC + "[0m" + ESC + "]0;title" + BEL + "plain"
	assert_str(AnsiParser.strip_ansi(noisy)).is_equal("redplain")
