## TerminalTabButton — a single tab entry in the TerminalTabBar.
## Displays a title label, an output-indicator dot, and a close button.
## Created programmatically by TerminalTabBar; no separate scene required.
class_name TerminalTabButton
extends PanelContainer

## Emitted when the close button is pressed.
signal close_requested(shell_id: String)

## Emitted when the tab is clicked (focus requested).
signal focused(shell_id: String)

## Unicode × used as the close button label.
const CLOSE_SYMBOL: String = "\u00d7"

## Colour of the "new output" indicator dot.
const INDICATOR_COLOR: Color = Color(0.16, 0.69, 0.6, 1.0)

## Unique identifier linking this tab to its shell/terminal instance.
var shell_id: String = ""

var _label: Label = null
var _indicator: ColorRect = null
var _close_btn: Button = null


func _ready() -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	add_child(hbox)

	_indicator = ColorRect.new()
	_indicator.custom_minimum_size = Vector2(6.0, 6.0)
	_indicator.color = INDICATOR_COLOR
	_indicator.visible = false
	hbox.add_child(_indicator)

	_label = Label.new()
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_label)

	_close_btn = Button.new()
	_close_btn.text = CLOSE_SYMBOL
	_close_btn.flat = true
	hbox.add_child(_close_btn)

	_close_btn.pressed.connect(_on_close_pressed)
	gui_input.connect(_on_gui_input)


func _exit_tree() -> void:
	if is_instance_valid(_close_btn) and _close_btn.pressed.is_connected(_on_close_pressed):
		_close_btn.pressed.disconnect(_on_close_pressed)
	if gui_input.is_connected(_on_gui_input):
		gui_input.disconnect(_on_gui_input)


## Update the title label.
func set_title(title: String) -> void:
	if is_instance_valid(_label):
		_label.text = title


## Show or hide the "new output" indicator dot.
func set_indicator(show_dot: bool) -> void:
	if is_instance_valid(_indicator):
		_indicator.visible = show_dot


func _on_close_pressed() -> void:
	close_requested.emit(shell_id)


func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		focused.emit(shell_id)
