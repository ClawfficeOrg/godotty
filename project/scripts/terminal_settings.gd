## Global terminal settings — accessed as TerminalSettings.<property>.
## This is a plain class (not an autoload); class_name makes it available
## everywhere without adding a new singleton.
class_name TerminalSettings

## All bundled theme display names. The theme picker populates its menu from
## this list. Each name maps to a .tres file under resources/themes/ via
## name.to_lower().replace(" ", "_") — except "Default" → "default_theme".
const BUNDLED_THEME_NAMES: Array[String] = [
	"Default",
	"Dracula",
	"Tokyo Night",
	"Gruvbox Dark",
	"Nord",
	"One Dark",
	"Solarized Dark",
	"Solarized Light",
	"Catppuccin Mocha",
]

## Cursor blink interval in seconds. Governs the Timer in TerminalView.
## Default: 0.5 s (two half-second phases per full blink cycle).
static var cursor_blink_rate: float = 0.5

## Optional monospace font override applied to OutputDisplay.
## When null, the engine default monospace font is used.
static var font: Font = null

## Point size of the terminal monospace font.
## Drives char_width (= font_size × 0.5) and line_height (= font_size)
## used to compute cols/rows from the viewport pixel dimensions.
## Default: 16 pt → char_width = 8.0 px, line_height = 16.0 px.
static var font_size: int = 16

## Name of the last theme the user picked. Empty string means "use default".
## Persists across scene reloads because static vars survive within a process.
static var selected_theme_name: String = ""
