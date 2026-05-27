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

## All bundled font display names. The font picker populates its menu from
## this list. "Default" means no override (engine built-in monospace font).
const BUNDLED_FONT_NAMES: Array[String] = [
	"Default",
	"JetBrains Mono Nerd",
]

## Maps each bundled font display name to its resource path under
## resources/fonts/. "Default" is intentionally absent — it means null.
const BUNDLED_FONT_PATHS: Dictionary = {
	"JetBrains Mono Nerd": "res://resources/fonts/JetBrainsMonoNerdFont-Regular.ttf",
}

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

## Name of the last font the user picked. "Default" means no override.
## Persists across scene reloads because static vars survive within a process.
static var selected_font_name: String = "Default"

## Background transparency of the terminal panel (0.0 = fully transparent,
## 1.0 = fully opaque). Applied to TerminalView.self_modulate.a.
## Requires display/window/transparent = true in Project Settings for the OS
## window to actually become transparent; the panel alpha is always applied.
static var background_opacity: float = 1.0

## Terminal content padding in pixels applied as a MarginContainer inset.
## x = horizontal (left and right), y = vertical (top and bottom).
## Default: (4, 4) px.
static var padding: Vector2i = Vector2i(4, 4)

## Whether to emit an audio beep (via DisplayServer.beep()) on BEL (\u0007).
## Disabled by default; the visual flash is always shown.
static var audio_bell: bool = false

## Maximum number of lines to retain in the primary scrollback buffer.
## When the terminal exceeds this limit, oldest lines are discarded at write time.
## Range: 1 to 100_000. Default: 1000.
static var scrollback_lines: int = 1000
