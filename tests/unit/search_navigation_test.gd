## GdUnit4 tests: search match navigation (task 2.2.3).
##
## Spec: docs/todo-v2.md (task 2.2.3)
##
## Covers:
##   - navigate_next advances _search_match_index and wraps from last to first.
##   - navigate_prev goes backwards and wraps from first to last.
##   - Navigating with no matches is safe (no crash, index stays -1).
##   - Navigation updates the match-count label to show current/total.
##   - Escape (hide_search) resets _search_match_index to -1.
##   - get_highlighted_line with accent_col highlights that match in SEARCH_ACCENT_BG.
##
## All tests run in mock mode -- no GDExtension required.
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
# Test 1: navigate_next advances and wraps after last match
# ---------------------------------------------------------------------------


## navigate_next emits advance _search_match_index forward, wrapping to 0
## after the final match.
func test_navigate_next_wraps_to_first_after_last() -> void:
	SignalBus.output_ready.emit("error here\nsecond error\nthird error\n")
	_view.search_scrollback("error")
	assert_int(_view._search_matches.size()).is_equal(3)
	assert_int(_view._search_match_index).is_equal(-1)

	_view.search_bar.navigate_next.emit()
	assert_int(_view._search_match_index).is_equal(0)

	_view.search_bar.navigate_next.emit()
	assert_int(_view._search_match_index).is_equal(1)

	_view.search_bar.navigate_next.emit()
	assert_int(_view._search_match_index).is_equal(2)

	# One more -- wraps to 0.
	_view.search_bar.navigate_next.emit()
	assert_int(_view._search_match_index).is_equal(0)


# ---------------------------------------------------------------------------
# Test 2: navigate_prev goes backwards and wraps to last
# ---------------------------------------------------------------------------


## navigate_prev decrements _search_match_index, wrapping from 0 to the last
## match index.
func test_navigate_prev_wraps_to_last() -> void:
	SignalBus.output_ready.emit("error here\nsecond error\n")
	_view.search_scrollback("error")
	assert_int(_view._search_matches.size()).is_equal(2)

	# First navigate_next lands on index 0.
	_view.search_bar.navigate_next.emit()
	assert_int(_view._search_match_index).is_equal(0)

	# navigate_prev from 0 wraps to last (index 1).
	_view.search_bar.navigate_prev.emit()
	assert_int(_view._search_match_index).is_equal(1)


# ---------------------------------------------------------------------------
# Test 3: navigating with no matches is safe
# ---------------------------------------------------------------------------


## Emitting navigate_next or navigate_prev when there are no matches must not
## crash and must leave _search_match_index at -1.
func test_navigate_with_no_matches_is_safe() -> void:
	_view.search_scrollback("no_such_word_xyz_abc")
	assert_int(_view._search_matches.size()).is_equal(0)

	_view.search_bar.navigate_next.emit()
	assert_int(_view._search_match_index).is_equal(-1)

	_view.search_bar.navigate_prev.emit()
	assert_int(_view._search_match_index).is_equal(-1)


# ---------------------------------------------------------------------------
# Test 4: navigation updates the match-count label (1-indexed)
# ---------------------------------------------------------------------------


## After each navigate_next, match_label shows "<current> / <total>" where
## current is 1-indexed.
func test_navigation_updates_match_display() -> void:
	SignalBus.output_ready.emit("error one\nerror two\n")
	_view.search_scrollback("error")
	_view.search_bar.navigate_next.emit()
	assert_str(_view.search_bar.match_label.text).is_equal("1 / 2")
	_view.search_bar.navigate_next.emit()
	assert_str(_view.search_bar.match_label.text).is_equal("2 / 2")


# ---------------------------------------------------------------------------
# Test 5: Escape (hide_search) resets navigation state
# ---------------------------------------------------------------------------


## Calling hide_search() after navigation resets _search_match_index to -1.
func test_escape_resets_navigation_state() -> void:
	SignalBus.output_ready.emit("error one\nerror two\n")
	_view.search_scrollback("error")
	_view.search_bar.navigate_next.emit()
	assert_int(_view._search_match_index).is_equal(0)

	_view.search_bar.hide_search()
	assert_int(_view._search_match_index).is_equal(-1)


# ---------------------------------------------------------------------------
# Test 6: current match uses SEARCH_ACCENT_BG
# ---------------------------------------------------------------------------


## get_highlighted_line with accent_col pointing at the match uses
## SEARCH_ACCENT_BG, not SEARCH_HIGHLIGHT_BG.
func test_current_match_uses_accent_color() -> void:
	var line: String = "line with error inside"
	# "error" starts at col 10 in this string.
	var normal_hl: String = _view.get_highlighted_line(line, "error")
	assert_str(normal_hl).contains("[bgcolor=%s]" % TerminalView.SEARCH_HIGHLIGHT_BG)
	assert_bool(normal_hl.contains("[bgcolor=%s]" % TerminalView.SEARCH_ACCENT_BG)).is_false()

	# With accent_col = 10 the match gets SEARCH_ACCENT_BG.
	var accent_hl: String = _view.get_highlighted_line(line, "error", false, 10)
	assert_str(accent_hl).contains("[bgcolor=%s]" % TerminalView.SEARCH_ACCENT_BG)
	assert_bool(accent_hl.contains("[bgcolor=%s]" % TerminalView.SEARCH_HIGHLIGHT_BG)).is_false()


# ---------------------------------------------------------------------------
# Test 7: new search resets match index
# ---------------------------------------------------------------------------


## Running search_scrollback with a new query resets _search_match_index to -1.
func test_new_search_resets_match_index() -> void:
	SignalBus.output_ready.emit("error here\nsecond error\n")
	_view.search_scrollback("error")
	_view.search_bar.navigate_next.emit()
	assert_int(_view._search_match_index).is_equal(0)

	# Run a fresh search -- index must reset.
	_view.search_scrollback("second")
	assert_int(_view._search_match_index).is_equal(-1)
