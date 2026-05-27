## GdUnit4 tests: scrollback search logic (task 2.2.2).
##
## Spec: docs/todo-v2.md (task 2.2.2)
##
## Covers:
##   - search_scrollback() returns 3 matches for "error" across 3 plain/mixed-case lines.
##   - Case-insensitive by default.
##   - Regex mode with a valid pattern finds matches.
##   - Malformed regex returns empty result without crashing.
##   - get_highlighted_line() injects [bgcolor=][/bgcolor] BBCode around matches.
##
## All tests run in mock mode — no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()


func after_test() -> void:
	if is_instance_valid(_view):
		_view.queue_free()
	_view = null


# ---------------------------------------------------------------------------
# Test 1: plain case-insensitive search returns 3 matches
# ---------------------------------------------------------------------------


## Populate scrollback with three lines containing "error" (different cases),
## call search_scrollback("error"), and verify 3 Vector2i matches at correct positions.
func test_search_plain_case_insensitive_matches() -> void:
	SignalBus.output_ready.emit("line one with error here\nAnother ERROR line\nfinal error entry\n")
	var matches: Array[Vector2i] = _view.search_scrollback("error")
	assert_int(matches.size()).is_equal(3)
	# Line 0: "line one with error here" → col 14
	assert_int(matches[0].x).is_equal(0)
	assert_int(matches[0].y).is_equal(14)
	# Line 1: "Another ERROR line" → col 8
	assert_int(matches[1].x).is_equal(1)
	assert_int(matches[1].y).is_equal(8)
	# Line 2: "final error entry" → col 6
	assert_int(matches[2].x).is_equal(2)
	assert_int(matches[2].y).is_equal(6)


# ---------------------------------------------------------------------------
# Test 2: regex toggle and invalid-pattern safety
# ---------------------------------------------------------------------------


## Regex mode with a valid alternation pattern matches 3 occurrences;
## a malformed regex returns an empty array without crashing.
func test_search_regex_toggle_and_invalid_pattern_handling() -> void:
	SignalBus.output_ready.emit("line with error here\nsecond error line\nfinal err0r entry\n")
	# Valid regex: "err(or|0r)" matches "error" twice and "err0r" once.
	var matches: Array[Vector2i] = _view.search_scrollback("err(or|0r)", true)
	assert_int(matches.size()).is_equal(3)
	# Malformed regex must not crash and must return empty.
	var bad_matches: Array[Vector2i] = _view.search_scrollback("err(or", true)
	assert_int(bad_matches.size()).is_equal(0)


# ---------------------------------------------------------------------------
# Test 3: BBCode highlight injection in rendered lines
# ---------------------------------------------------------------------------


## get_highlighted_line injects [bgcolor=...][/bgcolor] around matched text.
func test_rendering_injects_bbcode_for_matches() -> void:
	SignalBus.output_ready.emit("line with error inside\n")
	var matches: Array[Vector2i] = _view.search_scrollback("error")
	assert_int(matches.size()).is_equal(1)
	# Direct test of the pure highlight helper (no display required).
	var hl: String = _view.get_highlighted_line("line with error inside", "error")
	assert_str(hl).contains("[bgcolor=")
	assert_str(hl).contains("[/bgcolor]")
	# The [bgcolor= open tag must appear before [/bgcolor] close tag.
	var open_idx: int = hl.find("[bgcolor=")
	var close_idx: int = hl.find("[/bgcolor]")
	assert_bool(open_idx < close_idx).is_true()
	# Non-matching line must not contain bgcolor tags.
	var no_hl: String = _view.get_highlighted_line("nothing matches here", "error")
	assert_bool(no_hl.contains("[bgcolor=")).is_false()
