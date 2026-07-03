# GdUnit4 test: per-tab output isolation and xterm-256 color-cube ramp.
#
# Covers the fable_review.md findings:
#   §3.1 -- TerminalManagerNode must not broadcast on SignalBus; a view with an
#           injected manager renders that manager's output and nothing else,
#           and other views do not render the injected manager's output.
#   §3.6 -- AnsiParser.xterm256_hex uses the spec xterm ramp (0,95,135,175,215,255),
#           not multiples of 51.
#
# All tests run in mock mode -- no GDExtension required.
extends GdUnitTestSuite

const TERMINAL_SCENE := preload("res://scenes/terminal.tscn")

var _default_view: TerminalView
var _injected_view: TerminalView
var _manager: TerminalManagerNode


func before_test() -> void:
	TerminalManager.is_mock_mode = true
	TerminalManager.is_addon_available = false
	TerminalManager._mock_output_buffer.clear()
	TerminalManager._mock_history.clear()
	_manager = TerminalManagerNode.new()
	add_child(_manager)
	_manager.is_mock_mode = true
	_manager.is_addon_available = false
	_manager._mock_output_buffer.clear()
	_manager._mock_history.clear()
	_default_view = TERMINAL_SCENE.instantiate() as TerminalView
	add_child(_default_view)
	_injected_view = TERMINAL_SCENE.instantiate() as TerminalView
	_injected_view.manager = _manager
	add_child(_injected_view)


func after_test() -> void:
	for v: TerminalView in [_default_view, _injected_view]:
		if is_instance_valid(v):
			v.queue_free()
	_default_view = null
	_injected_view = null
	if is_instance_valid(_manager):
		_manager.queue_free()
	_manager = null


# ---------------------------------------------------------------------------
# TerminalManagerNode does not broadcast on SignalBus
# ---------------------------------------------------------------------------


func test_node_output_does_not_reach_default_view() -> void:
	_default_view._clear_output()
	_injected_view._clear_output()
	_manager.write_input("echo tab_only")
	await get_tree().process_frame
	assert_bool(_default_view._output_accumulator.contains("tab_only")).is_false()


func test_node_output_reaches_injected_view() -> void:
	_injected_view._clear_output()
	_manager.write_input("echo tab_only")
	await get_tree().process_frame
	assert_bool(_injected_view._output_accumulator.contains("tab_only")).is_true()


func test_bus_output_does_not_reach_injected_view() -> void:
	_default_view._clear_output()
	_injected_view._clear_output()
	SignalBus.output_ready.emit("bus_broadcast\n")
	await get_tree().process_frame
	assert_bool(_default_view._output_accumulator.contains("bus_broadcast")).is_true()
	assert_bool(_injected_view._output_accumulator.contains("bus_broadcast")).is_false()


func test_node_clear_does_not_clear_default_view() -> void:
	_default_view._clear_output()
	SignalBus.output_ready.emit("keep me\n")
	await get_tree().process_frame
	_manager.clear()
	await get_tree().process_frame
	assert_bool(_default_view._output_accumulator.contains("keep me")).is_true()


# ---------------------------------------------------------------------------
# xterm-256 color cube uses the spec ramp
# ---------------------------------------------------------------------------


func test_xterm256_cube_ramp_matches_spec() -> void:
	# Index 196 = cube (5,0,0) -> #ff0000
	assert_str(_default_view._parser.xterm256_hex(196)).is_equal("#ff0000")
	# Index 17 = cube (0,0,1) -> blue channel 95 (0x5f), not 51 (0x33)
	assert_str(_default_view._parser.xterm256_hex(17)).is_equal("#00005f")
	# Index 21 = cube (0,0,5) -> #0000ff
	assert_str(_default_view._parser.xterm256_hex(21)).is_equal("#0000ff")
	# Index 59 = cube (1,1,1) -> #5f5f5f
	assert_str(_default_view._parser.xterm256_hex(59)).is_equal("#5f5f5f")


func test_xterm256_grayscale_ramp_unchanged() -> void:
	# Index 232 -> #080808, index 255 -> #eeeeee
	assert_str(_default_view._parser.xterm256_hex(232)).is_equal("#080808")
	assert_str(_default_view._parser.xterm256_hex(255)).is_equal("#eeeeee")
