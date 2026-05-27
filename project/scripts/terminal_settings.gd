## Global terminal settings — accessed as TerminalSettings.<property>.
## This is a plain class (not an autoload); class_name makes it available
## everywhere without adding a new singleton.
class_name TerminalSettings

## Cursor blink interval in seconds. Governs the Timer in TerminalView.
## Default: 0.5 s (two half-second phases per full blink cycle).
static var cursor_blink_rate: float = 0.5

## Point size of the terminal monospace font.
## Drives char_width (= font_size × 0.5) and line_height (= font_size)
## used to compute cols/rows from the viewport pixel dimensions.
## Default: 16 pt → char_width = 8.0 px, line_height = 16.0 px.
static var font_size: int = 16
