## SearchBar — overlay search UI for TerminalView.
## Handles show/hide logic, query input, match-count display, and prev/next navigation.
## Escape hides the bar and emits search_canceled.
class_name SearchBar
extends PanelContainer

## Emitted when the user presses Enter or changes the query text.
signal search_submitted(query: String)

## Emitted when the user presses the prev-match button.
signal navigate_prev

## Emitted when the user presses the next-match button.
signal navigate_next

## Emitted when the search bar is dismissed (Escape or hide_search()).
signal search_canceled

const MATCH_LABEL_NONE: String = "No results"
const MATCH_LABEL_FORMAT: String = "%d / %d"

@onready var query_edit: LineEdit = $HBoxContainer/QueryEdit
@onready var match_label: Label = $HBoxContainer/MatchLabel
@onready var prev_button: Button = $HBoxContainer/PrevButton
@onready var next_button: Button = $HBoxContainer/NextButton


func _ready() -> void:
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	query_edit.text_submitted.connect(_on_query_submitted)
	query_edit.text_changed.connect(_on_query_changed)


func _exit_tree() -> void:
	if is_instance_valid(prev_button) and prev_button.pressed.is_connected(_on_prev_pressed):
		prev_button.pressed.disconnect(_on_prev_pressed)
	if is_instance_valid(next_button) and next_button.pressed.is_connected(_on_next_pressed):
		next_button.pressed.disconnect(_on_next_pressed)
	if is_instance_valid(query_edit):
		if query_edit.text_submitted.is_connected(_on_query_submitted):
			query_edit.text_submitted.disconnect(_on_query_submitted)
		if query_edit.text_changed.is_connected(_on_query_changed):
			query_edit.text_changed.disconnect(_on_query_changed)


## Handle Escape key to dismiss the search bar while it is visible.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		hide_search()
		get_viewport().set_input_as_handled()


## Show the search bar and give keyboard focus to the query field.
func show_search() -> void:
	show()
	query_edit.call_deferred("grab_focus")


## Hide the search bar, clear the query, and emit search_canceled.
func hide_search() -> void:
	hide()
	query_edit.text = ""
	set_match_display(0, 0)
	search_canceled.emit()


## Update the match-count label.
## When total is 0, shows MATCH_LABEL_NONE.
func set_match_display(current: int, total: int) -> void:
	if not is_instance_valid(match_label):
		return
	if total == 0:
		match_label.text = MATCH_LABEL_NONE
	else:
		match_label.text = MATCH_LABEL_FORMAT % [current, total]


func _on_prev_pressed() -> void:
	navigate_prev.emit()


func _on_next_pressed() -> void:
	navigate_next.emit()


func _on_query_submitted(query: String) -> void:
	search_submitted.emit(query)


func _on_query_changed(query: String) -> void:
	search_submitted.emit(query)
