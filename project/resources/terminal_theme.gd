## TerminalTheme -- color scheme Resource for terminal rendering.
##
## Defines five semantic color roles and a 16-entry ANSI color palette
## (indices 0-7 normal, 8-15 bright).
##
## Usage:
##   var theme := TerminalTheme.new()
##   ResourceSaver.save(theme, "res://resources/themes/my_theme.tres")
##   var loaded := ResourceLoader.load("res://resources/themes/my_theme.tres") as TerminalTheme
##
## The palette setter rejects arrays that are not exactly 16 entries:
## push_error is called and the assignment is silently ignored.
class_name TerminalTheme
extends Resource

## Terminal background fill color.
@export var color_background: Color = Color(0.05, 0.05, 0.1, 1.0)

## Default foreground (text) color.
@export var color_foreground: Color = Color(0.9, 0.9, 0.9, 1.0)

## Block cursor color.
@export var color_cursor: Color = Color(0.3, 0.9, 0.5, 1.0)

## Text-selection highlight color (background layer).
@export var color_selection_bg: Color = Color(0.3, 0.9, 0.5, 0.3)

## Text-selection highlight color (foreground/text layer).
@export var color_selection_fg: Color = Color(0.05, 0.05, 0.1, 1.0)

## 16-entry ANSI color palette.
## Assignment must contain exactly 16 Color entries; any other size is
## rejected (push_error) and the existing palette is preserved.
@export var palette: Array[Color]:
	set(value):
		if value.size() != 16:
			push_error("TerminalTheme: palette must have exactly 16 entries, got %d" % value.size())
			return
		_palette = value
	get:
		return _palette

var _palette: Array[Color] = []


func _init() -> void:
	palette = _default_palette()


## Returns a fresh copy of the built-in 16-color ANSI palette.
func _default_palette() -> Array[Color]:
	var p: Array[Color] = []
	p.resize(16)
	# Normal colors (0-7)
	p[0] = Color(0.0, 0.0, 0.0, 1.0)
	p[1] = Color(0.67, 0.02, 0.02, 1.0)
	p[2] = Color(0.02, 0.67, 0.02, 1.0)
	p[3] = Color(0.67, 0.67, 0.02, 1.0)
	p[4] = Color(0.02, 0.02, 0.67, 1.0)
	p[5] = Color(0.67, 0.02, 0.67, 1.0)
	p[6] = Color(0.02, 0.67, 0.67, 1.0)
	p[7] = Color(0.67, 0.67, 0.67, 1.0)
	# Bright colors (8-15)
	p[8] = Color(0.33, 0.33, 0.33, 1.0)
	p[9] = Color(1.0, 0.33, 0.33, 1.0)
	p[10] = Color(0.33, 1.0, 0.33, 1.0)
	p[11] = Color(1.0, 1.0, 0.33, 1.0)
	p[12] = Color(0.33, 0.33, 1.0, 1.0)
	p[13] = Color(1.0, 0.33, 1.0, 1.0)
	p[14] = Color(0.33, 1.0, 1.0, 1.0)
	p[15] = Color(1.0, 1.0, 1.0, 1.0)
	return p
