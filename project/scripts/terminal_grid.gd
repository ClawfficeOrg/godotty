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

## Rows scrolled up from the bottom (0 = viewing most recent content).
## Reset to 0 on every resize so the newest line remains visible.
var scrollback_offset: int = 0

## Pixel width of one character cell — used by cell_from_pixel / get_cell_rect.
var char_width: float = 8.0

## Pixel height of one character line — used by cell_from_pixel / get_cell_rect.
var line_height: float = 16.0

var _cols: int = 0
var _rows: int = 0

## Row-major 2-D array: _cells[row][col] → Dictionary
var _cells: Array = []

## Parallel bool array: _wrapped[r] is true when row r is a soft-wrapped
## continuation of row r-1 (i.e., the logical line overflowed into row r).
var _wrapped: Array = []


## Return a fresh default cell dictionary.
func _blank_cell() -> Dictionary:
	return DEFAULT_CELL.duplicate()


## Return true when cell matches the default blank template exactly.
func _is_blank_cell(cell: Dictionary) -> bool:
	return (
		cell["char"] == " "
		and cell["fg"] == Color.WHITE
		and cell["bg"] == Color.BLACK
		and not cell["bold"]
		and not cell["italic"]
		and not cell["underline"]
		and cell["url"] == ""
	)


## Resize the grid to (cols × rows) with line reflow.
##
## Existing logical lines (sequences of consecutive rows where each
## continuation row has _wrapped=true) are re-wrapped at the new col width.
## Rows shorter than cols gain blank cells; long logical lines are split
## across multiple physical rows.  If the total physical rows exceed `rows`,
## the oldest rows are discarded.  scrollback_offset is reset to 0 so the
## most recent content remains visible.
func resize(cols: int, rows: int) -> void:
	if cols <= 0 or rows <= 0:
		_cols = cols
		_rows = rows
		_cells = []
		_wrapped = []
		return

	# Step 1: Extract logical lines from current content.
	var logical_lines: Array = []
	if _rows > 0:
		var current_line: Array = []
		for r in range(_rows):
			if r > 0 and _wrapped.size() > r and _wrapped[r]:
				current_line.append_array(_cells[r])
			else:
				if not current_line.is_empty():
					logical_lines.append(current_line)
				current_line = _cells[r].duplicate()
		if not current_line.is_empty():
			logical_lines.append(current_line)

	# Step 2: Re-wrap each logical line at the new col width.
	var new_cells: Array = []
	var new_wrapped: Array = []
	for logical_line in logical_lines:
		# Strip trailing blank cells so pure-blank rows stay single-row.
		var trimmed: Array = logical_line.duplicate()
		while not trimmed.is_empty() and _is_blank_cell(trimmed.back()):
			trimmed.remove_at(trimmed.size() - 1)

		if trimmed.is_empty():
			var blank_row: Array = []
			for _c in range(cols):
				blank_row.append(_blank_cell())
			new_cells.append(blank_row)
			new_wrapped.append(false)
		else:
			var first := true
			var idx := 0
			while idx < trimmed.size():
				var row: Array = []
				for c in range(cols):
					if idx + c < trimmed.size():
						row.append(trimmed[idx + c].duplicate())
					else:
						row.append(_blank_cell())
				new_cells.append(row)
				new_wrapped.append(not first)
				first = false
				idx += cols

	# Step 3: Trim oldest rows if overflow; pad bottom with blank rows.
	while new_cells.size() > rows:
		new_cells.remove_at(0)
		new_wrapped.remove_at(0)
	while new_cells.size() < rows:
		var blank_row: Array = []
		for _c in range(cols):
			blank_row.append(_blank_cell())
		new_cells.append(blank_row)
		new_wrapped.append(false)

	_cols = cols
	_rows = rows
	_cells = new_cells
	_wrapped = new_wrapped
	cursor_row = clampi(cursor_row, 0, max(0, _rows - 1))
	cursor_col = clampi(cursor_col, 0, max(0, _cols - 1))
	scrollback_offset = 0


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
		_wrapped.remove_at(0)
	for _i in range(drop):
		var row: Array = []
		for _c in range(_cols):
			row.append(_blank_cell())
		_cells.append(row)
		_wrapped.append(false)


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


## Clamp a cell coordinate to valid grid bounds.
## Returns Vector2i(0, 0) if the grid has no cells.
func clamp_cell(cell: Vector2i) -> Vector2i:
	if _cols <= 0 or _rows <= 0:
		return Vector2i(0, 0)
	return Vector2i(clampi(cell.x, 0, _cols - 1), clampi(cell.y, 0, _rows - 1))


## Convert a local pixel position to the grid cell it falls in.
## Result is clamped to grid bounds.
func cell_from_pixel(local_pos: Vector2) -> Vector2i:
	var col := int(floor(local_pos.x / char_width))
	var row := int(floor(local_pos.y / line_height))
	return clamp_cell(Vector2i(col, row))


## Return the pixel Rect2 for a grid cell in local coordinates.
## Cell coordinates are clamped to bounds before computing.
func get_cell_rect(cell: Vector2i) -> Rect2:
	var clamped := clamp_cell(cell)
	return Rect2(
		Vector2(float(clamped.x) * char_width, float(clamped.y) * line_height),
		Vector2(char_width, line_height)
	)


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
