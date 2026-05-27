## TerminalGrid — 2-D cell backing store for terminal emulation.
##
## Stores a row-major array of cell dictionaries. Each cell:
##   { char: String, fg: Color, bg: Color, bold: bool, italic: bool,
##     underline: bool, url: String }
##
## Not an autoload — instantiate directly:
##   var grid := TerminalGrid.new()
##   grid.resize(80, 24)
##
## Primary and alternate screen buffers are separate TerminalGrid instances.
class_name TerminalGrid
extends RefCounted

## Default cell template. Duplicate before storing/returning.
const DEFAULT_CELL: Dictionary = {
	"char": " ",
	"fg": Color.WHITE,
	"bg": Color.BLACK,
	"bold": false,
	"italic": false,
	"underline": false,
	"url": "",
}

## Current cursor row (0-based). Updated by set_cursor, move_cursor, and resize.
var cursor_row: int = 0

## Current cursor column (0-based). Updated by set_cursor, move_cursor, and resize.
var cursor_col: int = 0

var _cols: int = 0
var _rows: int = 0

## Row-major 2-D array: _cells[row][col] → Dictionary
var _cells: Array = []


## Return a fresh default cell dictionary.
func _blank_cell() -> Dictionary:
	return DEFAULT_CELL.duplicate()


## Resize the grid to (cols × rows).
## Existing content is preserved where it fits; new cells are blank.
## Excess rows/columns are truncated.
func resize(cols: int, rows: int) -> void:
	var new_cells: Array = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			if r < _rows and c < _cols:
				row.append(_cells[r][c])
			else:
				row.append(_blank_cell())
		new_cells.append(row)
	_cols = cols
	_rows = rows
	_cells = new_cells
	# Clamp cursor to new bounds after resize.
	cursor_row = clampi(cursor_row, 0, max(0, _rows - 1))
	cursor_col = clampi(cursor_col, 0, max(0, _cols - 1))


## Write a cell at (row, col). Out-of-bounds writes are silently ignored.
func set_cell(row: int, col: int, cell: Dictionary) -> void:
	if row < 0 or row >= _rows or col < 0 or col >= _cols:
		return
	_cells[row][col] = cell.duplicate()


## Read a cell at (row, col).
## Returns a blank default cell for out-of-bounds reads.
func get_cell(row: int, col: int) -> Dictionary:
	if row < 0 or row >= _rows or col < 0 or col >= _cols:
		return _blank_cell()
	return _cells[row][col].duplicate()


## Clear (reset to default) a rectangular region.
## top_row, left_col: top-left corner; height, width: extent.
## Clamps silently to grid bounds.
func clear_region(top_row: int, left_col: int, height: int, width: int) -> void:
	var end_row: int = min(top_row + height, _rows)
	var end_col: int = min(left_col + width, _cols)
	for r in range(max(top_row, 0), end_row):
		for c in range(max(left_col, 0), end_col):
			_cells[r][c] = _blank_cell()


## Scroll the grid up by n lines.
## The top n rows are discarded; n blank rows are appended at the bottom.
func scroll_up(n: int) -> void:
	if n <= 0:
		return
	var drop: int = min(n, _rows)
	for _i in range(drop):
		_cells.remove_at(0)
	for _i in range(drop):
		var row: Array = []
		for _c in range(_cols):
			row.append(_blank_cell())
		_cells.append(row)


## Move cursor to an absolute 0-based (row, col).
## Coordinates are clamped to grid bounds.
func set_cursor(row: int, col: int) -> void:
	cursor_row = clampi(row, 0, max(0, _rows - 1))
	cursor_col = clampi(col, 0, max(0, _cols - 1))


## Move cursor relative to current position.
## Result is clamped to grid bounds.
func move_cursor(delta_row: int, delta_col: int) -> void:
	set_cursor(cursor_row + delta_row, cursor_col + delta_col)


## Erase display cells (CSI J).
## mode 0: cursor position to end of display.
## mode 1: beginning of display to cursor position (inclusive).
## mode 2: entire display.
## Cursor position is not changed.
func erase_display(mode: int) -> void:
	match mode:
		0:
			clear_region(cursor_row, cursor_col, 1, _cols - cursor_col)
			if cursor_row + 1 < _rows:
				clear_region(cursor_row + 1, 0, _rows - cursor_row - 1, _cols)
		1:
			if cursor_row > 0:
				clear_region(0, 0, cursor_row, _cols)
			clear_region(cursor_row, 0, 1, cursor_col + 1)
		2:
			clear_region(0, 0, _rows, _cols)


## Erase line cells (CSI K).
## mode 0: cursor position to end of current line.
## mode 1: beginning of current line to cursor position (inclusive).
## mode 2: entire current line.
## Cursor position is not changed.
func erase_line(mode: int) -> void:
	match mode:
		0:
			clear_region(cursor_row, cursor_col, 1, _cols - cursor_col)
		1:
			clear_region(cursor_row, 0, 1, cursor_col + 1)
		2:
			clear_region(cursor_row, 0, 1, _cols)


## Write a cell at the current cursor position and advance the column by one.
## Column does not advance past the last column.
func write_at_cursor(cell: Dictionary) -> void:
	set_cell(cursor_row, cursor_col, cell)
	if _cols > 0 and cursor_col < _cols - 1:
		cursor_col += 1


## Return a BBCode-formatted string for the given row (for RichTextLabel).
## Adjacent cells with identical style are merged into a single BBCode span.
## Returns "" for an out-of-bounds row.
func to_bbcode_line(row: int) -> String:
	if row < 0 or row >= _rows:
		return ""
	var result := ""
	var col := 0
	while col < _cols:
		var cell: Dictionary = _cells[row][col]
		var span_len := _span_length(row, col)
		var text := ""
		for k in range(span_len):
			text += _cells[row][col + k]["char"]
		result += _span_to_bbcode(cell, text)
		col += span_len
	return result


## Return the number of consecutive columns starting at (row, col) that
## share the same visual style as the cell at that position.
func _span_length(row: int, col: int) -> int:
	var ref_cell: Dictionary = _cells[row][col]
	var count := 1
	while col + count < _cols:
		var next: Dictionary = _cells[row][col + count]
		if (
			next["fg"] != ref_cell["fg"]
			or next["bg"] != ref_cell["bg"]
			or next["bold"] != ref_cell["bold"]
			or next["italic"] != ref_cell["italic"]
			or next["underline"] != ref_cell["underline"]
			or next["url"] != ref_cell["url"]
		):
			break
		count += 1
	return count


## Wrap text in the BBCode tags implied by a cell's style attributes.
func _span_to_bbcode(cell: Dictionary, text: String) -> String:
	var out := text
	var url: String = cell["url"]
	if url != "":
		out = "[url=" + url + "]" + out + "[/url]"
	var bg: Color = cell["bg"]
	if bg != Color.BLACK:
		out = "[bgcolor=" + bg.to_html(false) + "]" + out + "[/bgcolor]"
	var fg: Color = cell["fg"]
	if fg != Color.WHITE:
		out = "[color=" + fg.to_html(false) + "]" + out + "[/color]"
	if cell["underline"]:
		out = "[u]" + out + "[/u]"
	if cell["italic"]:
		out = "[i]" + out + "[/i]"
	if cell["bold"]:
		out = "[b]" + out + "[/b]"
	return out
