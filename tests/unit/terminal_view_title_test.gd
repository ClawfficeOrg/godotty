# GdUnit4 test: TerminalView OSC 0/2 tab-title sequences (task 3.0.4).
#
# Spec: docs/todo-v3.md (task 3.0.4)
#
# Covers:
#   - OSC 0 sequence sets tab title via tab_title_changed signal.
#   - OSC 2 sequence sets tab title via tab_title_changed signal.
#   - OSC sequence split across two feed chunks triggers one title update.
#   - Non-0/2 OSC sequences do not emit tab_title_changed.
#   - Empty title string is emitted as-is (valid OSC).
#
# All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _view: TerminalView
var _captured_titles: Array[String] = []


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_view)
	_captured_titles.clear()
	_view.tab_title_changed.connect(_on_tab_title_changed)


func _on_tab_title_changed(title: String) -> void:
	_captured_titles.append(title)


func after_test() -> void:
	if is_instance_valid(_view):
		if _view.tab_title_changed.is_connected(_on_tab_title_changed):
			_view.tab_title_changed.disconnect(_on_tab_title_changed)
		_view.queue_free()
	_view = null
	_captured_titles.clear()


# ---------------------------------------------------------------------------
# OSC 0 sets tab title
# ---------------------------------------------------------------------------


func test_osc_0_sets_tab_title() -> void:
	_view._on_output_ready("\u001b]0;My Tab\u0007")
	assert_int(_captured_titles.size()).is_equal(1)
	assert_str(_captured_titles[0]).is_equal("My Tab")


# ---------------------------------------------------------------------------
# OSC 2 sets tab title
# ---------------------------------------------------------------------------


func test_osc_2_sets_tab_title() -> void:
	_view._on_output_ready("\u001b]2;My Other\u0007")
	assert_int(_captured_titles.size()).is_equal(1)
	assert_str(_captured_titles[0]).is_equal("My Other")


# ---------------------------------------------------------------------------
# OSC sequence split across two chunks (buffering verification)
# ---------------------------------------------------------------------------


func test_osc_title_split_across_chunks() -> void:
	# First chunk ends partway through the OSC sequence -- no title yet.
	_view._on_output_ready("\u001b]")
	assert_int(_captured_titles.size()).is_equal(0)
	# Second chunk completes the sequence.
	_view._on_output_ready("0;X\u0007")
	assert_int(_captured_titles.size()).is_equal(1)
	assert_str(_captured_titles[0]).is_equal("X")


# ---------------------------------------------------------------------------
# Non-0/2 OSC codes do not emit title updates
# ---------------------------------------------------------------------------


func test_other_osc_ignored_for_title() -> void:
	_view._on_output_ready("\u001b]4;255;rgb:ff/ff/ff\u0007")
	assert_int(_captured_titles.size()).is_equal(0)


# ---------------------------------------------------------------------------
# Empty title is emitted (valid OSC; callers decide what to display)
# ---------------------------------------------------------------------------


func test_title_empty_string_is_emitted() -> void:
	_view._on_output_ready("\u001b]0;\u0007")
	assert_int(_captured_titles.size()).is_equal(1)
	assert_str(_captured_titles[0]).is_equal("")
