## Global terminal settings — accessed as TerminalSettings.<property>.
## This is a plain class (not an autoload); class_name makes it available
## everywhere without adding a new singleton.
class_name TerminalSettings

## Cursor blink interval in seconds. Governs the Timer in TerminalView.
## Default: 0.5 s (two half-second phases per full blink cycle).
static var cursor_blink_rate: float = 0.5
