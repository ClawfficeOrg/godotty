# GdUnit4 test: TerminalView renders ANSI background colors correctly.
#
# Covers: SGR codes 40-47 (standard bg), 100-107 (bright bg), 49 (default bg),
#         48;5;N (256-color bg), 48;2;R;G;B (RGB bg), and BBCode [bgcolor] tags.
#
# All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

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
# SGR 40-47: Standard background colors (black through white)
# ---------------------------------------------------------------------------


func test_sgr_40_black_background() -> void:
	var esc := char(27)
	SignalBus.output_ready.emit(esc + "[40mBLACK_BG" + esc + "[0m")
	await get_tree().process_frame
	var text := _view.output_display.get_parsed_text()
	assert_str(text).contains("BLACK_BG")
	# BBCode should contain [bgcolor=...] tag
	var bbcode := _view._output_accumulator
	assert_str(bbcode).contains("[bgcolor=")


func test_sgr_41_red_background() -> void:
	var esc := char(27)
	SignalBus.output_ready.emit(esc + "[41mRED_BG" + esc + "[0m")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).contains("[bgcolor=")
	assert_str(bbcode).contains("RED_BG")


func test_sgr_47_white_background() -> void:
	var esc := char(27)
	SignalBus.output_ready.emit(esc + "[47mWHITE_BG" + esc + "[0m")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).contains("[bgcolor=")
	assert_str(bbcode).contains("WHITE_BG")


# ---------------------------------------------------------------------------
# SGR 49: Reset background to default
# ---------------------------------------------------------------------------


func test_sgr_49_resets_background() -> void:
	var esc := char(27)
	SignalBus.output_ready.emit(esc + "[41mRED" + esc + "[49mNO_BG" + esc + "[0m")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	# Should have [/bgcolor] after the reset
	assert_str(bbcode).contains("[/bgcolor]")


# ---------------------------------------------------------------------------
# SGR 100-107: Bright background colors
# ---------------------------------------------------------------------------


func test_sgr_100_bright_black_background() -> void:
	var esc := char(27)
	SignalBus.output_ready.emit(esc + "[100mBRIGHT_BLACK_BG" + esc + "[0m")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).contains("[bgcolor=")
	assert_str(bbcode).contains("BRIGHT_BLACK_BG")


func test_sgr_107_bright_white_background() -> void:
	var esc := char(27)
	SignalBus.output_ready.emit(esc + "[107mBRIGHT_WHITE_BG" + esc + "[0m")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).contains("[bgcolor=")
	assert_str(bbcode).contains("BRIGHT_WHITE_BG")


# ---------------------------------------------------------------------------
# SGR 48;5;N: 256-color background
# ---------------------------------------------------------------------------


func test_sgr_48_5_xterm256_background() -> void:
	var esc := char(27)
	# Color 196 is bright red in xterm256
	SignalBus.output_ready.emit(esc + "[48;5;196mXTERM_BG" + esc + "[0m")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).contains("[bgcolor=")
	assert_str(bbcode).contains("XTERM_BG")


# ---------------------------------------------------------------------------
# SGR 48;2;R;G;B: RGB background
# ---------------------------------------------------------------------------


func test_sgr_48_2_rgb_background() -> void:
	var esc := char(27)
	# RGB(255, 128, 0) = orange
	SignalBus.output_ready.emit(esc + "[48;2;255;128;0mRGB_BG" + esc + "[0m")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).contains("[bgcolor=#ff8000]")
	assert_str(bbcode).contains("RGB_BG")


# ---------------------------------------------------------------------------
# SGR 0: Reset clears background
# ---------------------------------------------------------------------------


func test_sgr_0_clears_background() -> void:
	var esc := char(27)
	SignalBus.output_ready.emit(esc + "[42mGREEN_BG" + esc + "[0mNORMAL")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).contains("[bgcolor=")
	assert_str(bbcode).contains("[/bgcolor]")
	assert_str(bbcode).contains("NORMAL")


# ---------------------------------------------------------------------------
# Combined foreground + background
# ---------------------------------------------------------------------------


func test_combined_fg_and_bg() -> void:
	var esc := char(27)
	# Yellow text on blue background
	SignalBus.output_ready.emit(esc + "[33;44mYELLOW_ON_BLUE" + esc + "[0m")
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	assert_str(bbcode).contains("[color=")
	assert_str(bbcode).contains("[bgcolor=")
	assert_str(bbcode).contains("YELLOW_ON_BLUE")


# ---------------------------------------------------------------------------
# Multiple bg color changes in sequence
# ---------------------------------------------------------------------------


func test_multiple_bg_changes() -> void:
	var esc := char(27)
	SignalBus.output_ready.emit(
		esc + "[41mRED" + esc + "[42mGREEN" + esc + "[43mYELLOW" + esc + "[0m"
	)
	await get_tree().process_frame
	var bbcode := _view._output_accumulator
	# Should have multiple [bgcolor=...] tags as colors change
	var bg_count := bbcode.count("[bgcolor=")
	assert_int(bg_count).is_greater_equal(3)
