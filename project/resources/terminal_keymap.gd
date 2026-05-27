## TerminalKeymap -- maps action names to InputEventKey bindings.
##
## A Resource that holds a `bindings` dictionary from action name (String)
## to InputEventKey. Call `TerminalKeymap.default()` to get a keymap
## pre-populated with the thirteen built-in terminal actions.
##
## Built-in actions:
##   copy, paste, clear, search,
##   scroll_page_up, scroll_page_down,
##   new_tab, close_tab, next_tab, split_right, split_down,
##   interrupt (Ctrl+C), eof (Ctrl+D)
##
## To rebind an action, assign a new InputEventKey to `bindings[action_name]`.
## Use `find_action(event)` to resolve which action a key event maps to.
class_name TerminalKeymap
extends Resource

## Action name: copy selection to clipboard.
const ACTION_COPY: String = "copy"
## Action name: paste from clipboard.
const ACTION_PASTE: String = "paste"
## Action name: clear the terminal screen.
const ACTION_CLEAR: String = "clear"
## Action name: open the search overlay.
const ACTION_SEARCH: String = "search"
## Action name: scroll one page up.
const ACTION_SCROLL_PAGE_UP: String = "scroll_page_up"
## Action name: scroll one page down.
const ACTION_SCROLL_PAGE_DOWN: String = "scroll_page_down"
## Action name: open a new tab.
const ACTION_NEW_TAB: String = "new_tab"
## Action name: close the current tab.
const ACTION_CLOSE_TAB: String = "close_tab"
## Action name: cycle to the next tab.
const ACTION_NEXT_TAB: String = "next_tab"
## Action name: split the current pane to the right.
const ACTION_SPLIT_RIGHT: String = "split_right"
## Action name: split the current pane downward.
const ACTION_SPLIT_DOWN: String = "split_down"
## Action name: send interrupt signal (Ctrl+C).
const ACTION_INTERRUPT: String = "interrupt"
## Action name: send EOF (Ctrl+D).
const ACTION_EOF: String = "eof"

## All built-in action names in canonical order.
const BUILTIN_ACTIONS: Array[String] = [
	ACTION_COPY,
	ACTION_PASTE,
	ACTION_CLEAR,
	ACTION_SEARCH,
	ACTION_SCROLL_PAGE_UP,
	ACTION_SCROLL_PAGE_DOWN,
	ACTION_NEW_TAB,
	ACTION_CLOSE_TAB,
	ACTION_NEXT_TAB,
	ACTION_SPLIT_RIGHT,
	ACTION_SPLIT_DOWN,
	ACTION_INTERRUPT,
	ACTION_EOF,
]

## Action-name -> InputEventKey mapping.  Assign directly to rebind.
@export var bindings: Dictionary = {}


## Returns a new TerminalKeymap populated with all default key bindings.
##
## Default bindings:
##   copy          -> Ctrl+Shift+C
##   paste         -> Ctrl+Shift+V
##   clear         -> Ctrl+L
##   search        -> Ctrl+Shift+F
##   scroll_page_up   -> Shift+PageUp
##   scroll_page_down -> Shift+PageDown
##   new_tab       -> Ctrl+T
##   close_tab     -> Ctrl+W
##   next_tab      -> Ctrl+Tab
##   split_right   -> Ctrl+Shift+Right
##   split_down    -> Ctrl+Shift+Down
##   interrupt     -> Ctrl+C
##   eof           -> Ctrl+D
static func default() -> TerminalKeymap:
	var km := TerminalKeymap.new()
	km.bindings = {
		ACTION_COPY: _make_key(KEY_C, true, true),
		ACTION_PASTE: _make_key(KEY_V, true, true),
		ACTION_CLEAR: _make_key(KEY_L, true),
		ACTION_SEARCH: _make_key(KEY_F, true, true),
		ACTION_SCROLL_PAGE_UP: _make_key(KEY_PAGEUP, false, true),
		ACTION_SCROLL_PAGE_DOWN: _make_key(KEY_PAGEDOWN, false, true),
		ACTION_NEW_TAB: _make_key(KEY_T, true),
		ACTION_CLOSE_TAB: _make_key(KEY_W, true),
		ACTION_NEXT_TAB: _make_key(KEY_TAB, true),
		ACTION_SPLIT_RIGHT: _make_key(KEY_RIGHT, true, true),
		ACTION_SPLIT_DOWN: _make_key(KEY_DOWN, true, true),
		ACTION_INTERRUPT: _make_key(KEY_C, true),
		ACTION_EOF: _make_key(KEY_D, true),
	}
	return km


## Returns the first action name whose binding matches `event`, or "" if none.
##
## Matching is based on keycode + Ctrl/Shift/Alt/Meta modifier flags.
func find_action(event: InputEventKey) -> String:
	for action: String in bindings:
		var bound: InputEventKey = bindings[action]
		if _keys_match(bound, event):
			return action
	return ""


static func _make_key(
	keycode: Key, ctrl: bool = false, shift: bool = false, alt: bool = false
) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.ctrl_pressed = ctrl
	ev.shift_pressed = shift
	ev.alt_pressed = alt
	return ev


func _keys_match(a: InputEventKey, b: InputEventKey) -> bool:
	return (
		a.keycode == b.keycode
		and a.ctrl_pressed == b.ctrl_pressed
		and a.shift_pressed == b.shift_pressed
		and a.alt_pressed == b.alt_pressed
		and a.meta_pressed == b.meta_pressed
	)
