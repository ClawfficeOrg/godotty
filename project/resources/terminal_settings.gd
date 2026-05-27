## TerminalSettings — serializable per-session terminal configuration Resource.
##
## Stores font, sizing, color theme, and cursor preferences. Instances can be
## persisted to a .tres file via ResourceSaver/ResourceLoader.
##
## Note: this file intentionally omits `class_name` because the global static
## class `TerminalSettings` (project/scripts/terminal_settings.gd) already
## occupies that name. Access this Resource by preloading its path.
##
## Invalid property values are silently clamped to the declared ranges.
##
## Validation ranges:
##   font_size:         [FONT_SIZE_MIN,           FONT_SIZE_MAX]           = [8, 72]
##   line_height_scale: [LINE_HEIGHT_SCALE_MIN,   LINE_HEIGHT_SCALE_MAX]   = [0.5, 3.0]
##   cursor_blink_rate: [CURSOR_BLINK_RATE_MIN,   CURSOR_BLINK_RATE_MAX]   = [0.0, 5.0]
##   (cursor_blink_rate of 0.0 disables blinking)
extends Resource

## Minimum valid font size (points).
const FONT_SIZE_MIN: int = 8
## Maximum valid font size (points).
const FONT_SIZE_MAX: int = 72

## Minimum valid line-height scale factor.
const LINE_HEIGHT_SCALE_MIN: float = 0.5
## Maximum valid line-height scale factor.
const LINE_HEIGHT_SCALE_MAX: float = 3.0

## Minimum valid cursor blink interval (seconds); 0.0 = blinking disabled.
const CURSOR_BLINK_RATE_MIN: float = 0.0
## Maximum valid cursor blink interval (seconds).
const CURSOR_BLINK_RATE_MAX: float = 5.0

## Optional monospace font override. When null the engine default monospace font is used.
@export var font: FontFile = null

## Font size in points. Clamped to [FONT_SIZE_MIN, FONT_SIZE_MAX].
@export var font_size: int = 14:
	set(value):
		_font_size = clampi(value, FONT_SIZE_MIN, FONT_SIZE_MAX)
	get:
		return _font_size

## Line-height multiplier relative to font_size.
## Clamped to [LINE_HEIGHT_SCALE_MIN, LINE_HEIGHT_SCALE_MAX].
@export var line_height_scale: float = 1.2:
	set(value):
		_line_height_scale = clampf(value, LINE_HEIGHT_SCALE_MIN, LINE_HEIGHT_SCALE_MAX)
	get:
		return _line_height_scale

## Color scheme resource. When null consumers fall back to the default TerminalTheme.
@export var theme: TerminalTheme = null

## Cursor blink interval in seconds. 0.0 disables blinking.
## Clamped to [CURSOR_BLINK_RATE_MIN, CURSOR_BLINK_RATE_MAX].
@export var cursor_blink_rate: float = 0.5:
	set(value):
		_cursor_blink_rate = clampf(value, CURSOR_BLINK_RATE_MIN, CURSOR_BLINK_RATE_MAX)
	get:
		return _cursor_blink_rate

var _font_size: int = 14
var _line_height_scale: float = 1.2
var _cursor_blink_rate: float = 0.5


## Adds PROPERTY_HINT_RANGE Inspector metadata for the three validated numeric
## properties. Actual clamping happens in each property's setter.
func _validate_property(property: Dictionary) -> void:
	match property["name"]:
		"font_size":
			property["hint"] = PROPERTY_HINT_RANGE
			property["hint_string"] = "%d,%d,1" % [FONT_SIZE_MIN, FONT_SIZE_MAX]
		"line_height_scale":
			property["hint"] = PROPERTY_HINT_RANGE
			property["hint_string"] = (
				"%.2f,%.2f,0.01" % [LINE_HEIGHT_SCALE_MIN, LINE_HEIGHT_SCALE_MAX]
			)
		"cursor_blink_rate":
			property["hint"] = PROPERTY_HINT_RANGE
			property["hint_string"] = (
				"%.2f,%.2f,0.01" % [CURSOR_BLINK_RATE_MIN, CURSOR_BLINK_RATE_MAX]
			)
