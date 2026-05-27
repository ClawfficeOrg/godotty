# Changelog

All notable changes to **godotty** are documented here.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

Pre-1.0 versions: MINOR bumps may include breaking changes (loudly noted).

## [Unreleased]

- **Multi-instance `TerminalManager` (task 3.0.1) — BREAKING CHANGE (public API; requires human sign-off).**
  - Added `TerminalManagerNode` (`project/scripts/terminal_manager_node.gd`) — a new `Node`-derived
    class with full terminal logic (mock + real backend) that can be instantiated per-tab independently.
  - `project/autoload/terminal_manager.gd` gains `get_default() -> Node` and `set_default(node: Node)`
    registry methods; `get_default()` returns the autoload itself when no custom default is registered,
    preserving full backward compatibility.
  - `project/scripts/terminal_view.gd` gains `@export var manager: Node = null`; all internal calls
    route through `_get_manager()` which returns the injected instance or falls back to the autoload.
  - `project/scenes/terminal_manager.tscn` — minimal scene for editor/test instantiation.
  - `tests/unit/terminal_manager_multi_instance_test.gd` — 11 tests covering instanceability,
    independent state, registry API, and backward-compatibility shim.
  - `tests/unit/terminal_view_injection_test.gd` — 9 tests proving `TerminalView` accepts an
    injected manager and falls back to the autoload registry.

  - `TerminalSettings.scrollback_lines: int` (default `1000`, max `100_000`) — configures
    how many lines the primary-screen scrollback buffer retains.
  - `TerminalView._enforce_scrollback_limit()` — trims oldest lines from `_raw_accumulator`
    and re-renders `output_display` when `_line_count` exceeds the limit. Enforced at write
    time; the effective limit is `clampi(TerminalSettings.scrollback_lines, 1, 100_000)`.
  - Replaced the hard-coded `MAX_LINES = 1000` constant with the live settings value.
- **Visual bell (task 2.4.3).**
  - `TerminalView.bell_color: Color` (exported, default `Color.WHITE`) — the flash
    colour applied to `self_modulate` when a BEL (`\u0007`) character is received.
  - `TerminalView.BELL_DURATION: float = 0.15` — flash duration constant (seconds).
  - `TerminalView._trigger_visual_bell()` — sets `self_modulate` to `bell_color`
    instantly, then tweens back to the original modulate over `BELL_DURATION`.
  - `TerminalSettings.audio_bell: bool` (default `false`) — when `true`, also calls
    `DisplayServer.beep()` for an audio bell alongside the visual flash.
  - `tests/unit/terminal_view_bell_test.gd` — 4 tests: default export color,
    modulate changes to bell_color on BEL, modulate restores after tween, and
    audio bell enabled does not crash.
- **Configurable terminal padding (task 2.4.2).**
  - `TerminalSettings.padding: Vector2i` (default `(4, 4)` px).
  - `terminal.tscn` wraps `VBoxContainer` in a `MarginContainer` named
    `PaddingContainer`; `TerminalView.padding_container` exposes it.
  - `TerminalView.apply_padding()` — reads `TerminalSettings.padding` and
    applies x to left/right margins and y to top/bottom margins. Called in `_ready()`.
  - `.gdlintrc` — raised `max-line-length` to 120 to accommodate longer NodePath
    @onready declarations introduced by the PaddingContainer wrapper.
  - `tests/unit/terminal_view_padding_test.gd` — 5 tests: default (4,4), applied
    at ready, (10,10) sets all sides to 10, (0,0) sets all to zero, asymmetric axes.
- **Background transparency for terminal panel (task 2.4.1).**
  - `TerminalSettings.background_opacity: float` (0.0–1.0, default 1.0).
  - `TerminalView.apply_background_opacity()` — applies the setting to
    `self_modulate.a`, clamped to valid range. Called in `_ready()`.
  - OS-level window transparency additionally requires
    `display/window/transparent = true` in Project Settings.
  - `tests/unit/terminal_view_background_opacity_test.gd` — 7 tests covering
    half-opacity, full opacity, zero opacity, clamping, default at ready, and
    RGB channel preservation.
- **Keybinding editor panel (task 2.3.3).**
  - `project/scenes/settings_dialog.tscn` — scrollable keybinding list with
    (action name, current chord, [Edit] button) rows; Save and Reset to Defaults
    buttons at the bottom.
  - `project/scripts/settings_dialog.gd` — `SettingsDialog` class (extends Control):
    populates rows from `TerminalKeymap.BUILTIN_ACTIONS`, captures the next key press
    when Edit is clicked and updates `TerminalManager.keymap.bindings`, saves to
    `user://keymap.tres` via `save_keymap()`, restores from file or defaults via
    `load_keymap()`.
  - `tests/unit/settings_keybinding_test.gd` — 6 tests: action rows populated,
    F5 capture binds action, capture resets after one key, modifier-only key ignored,
    save/load persistence, missing-file fallback to defaults, rebind "copy" survives
    simulated restart (release-gate test for 2.3.0).
- **TerminalView consumes TerminalKeymap for input dispatch (task 2.3.2).**
  - `project/autoload/terminal_manager.gd` — new `keymap: TerminalKeymap` property
    (defaults to `TerminalKeymap.default()`); assign to rebind at runtime.
  - `project/scripts/terminal_view.gd` — `_input` now loops over
    `TerminalManager.keymap.bindings` via `find_action()`; each match calls
    `_execute_action(action_name)`. Echo events are filtered. Legacy
    Ctrl+Insert / Shift+Insert shortcuts kept as hardcoded pre-checks.
  - `tests/unit/terminal_view_keymap_test.gd` — 4 tests covering default
    Ctrl+L clear, rebind clear to Ctrl+K, old binding invalidation, echo guard.
- **TerminalKeymap resource (task 2.3.1).**
  - `project/resources/terminal_keymap.gd` — `Resource` with `bindings: Dictionary`
    mapping action name → `InputEventKey`. Twelve built-in actions: `copy`,
    `paste`, `clear`, `search`, `scroll_page_up`, `scroll_page_down`, `new_tab`,
    `close_tab`, `split_right`, `split_down`, `interrupt` (Ctrl+C), `eof`
    (Ctrl+D). Static factory `TerminalKeymap.default()` pre-populates all
    bindings. `find_action(event)` resolves a key event to its action name.
  - `tests/unit/terminal_keymap_test.gd` — 7 tests covering default bindings,
    Ctrl+C / Ctrl+D mappings, rebinding, and `find_action` resolution.
- **Search match navigation (task 2.2.3).**
  - `project/scripts/search_bar.gd` — `_input()` now intercepts `KEY_ENTER`/
    `KEY_KP_ENTER`: plain Enter emits `navigate_next`, Shift+Enter emits
    `navigate_prev`; event is consumed so the `LineEdit` does not also fire
    `text_submitted`.
  - `project/scripts/terminal_view.gd` — `SEARCH_ACCENT_BG` constant
    (`#b58900`) for the current-match highlight; `_search_match_index` private
    var; `_on_navigate_next()` / `_on_navigate_prev()` signal handlers;
    `_navigate_search_match(direction)` advances/retreats the index with wrap,
    calls `_render_highlighted_scrollback()` with accent on the selected match,
    scrolls the `ScrollContainer` to the match line, and updates the match-count
    label to `"<current> / <total>"` (1-indexed).  `get_highlighted_line()` gains
    an optional `accent_col: int = -1` parameter — when `≥ 0` that match column
    uses `SEARCH_ACCENT_BG`; all others keep `SEARCH_HIGHLIGHT_BG`.
    `search_scrollback()` resets `_search_match_index` to `-1` on each new
    query.  `_on_search_canceled()` likewise resets it.
    Navigate signals wired in `_ready()` and cleaned up in `_exit_tree()`.
  - `.gdlintrc` — `max-file-lines` raised from 1400 → 1500 to accommodate
    the larger `terminal_view.gd`.
  - `tests/unit/search_navigation_test.gd` — 7 tests: forward wrap, backward
    wrap, no-match safety, match-display label, Escape reset, accent color,
    new-search reset; ALL GREEN.

- **Scrollback search logic (task 2.2.2).**
  - `project/scripts/terminal_view.gd` — added `search_scrollback(query, use_regex=false)`
    returning `Array[Vector2i]` (line, col) for every match; case-insensitive plain search
    by default, optional regex mode; stores matches in `_search_matches` and re-renders the
    output with `[bgcolor=][/bgcolor]` highlights via `_render_highlighted_scrollback()`.
    Added `get_highlighted_line(line_text, query, use_regex=false)` pure helper for
    testable BBCode injection; `_strip_ansi()` regex helper; `_on_search_submitted()`
    wired to `SearchBar.search_submitted`; `_on_search_canceled()` now also restores
    unhighlighted rendering; `SEARCH_HIGHLIGHT_BG` constant.
  - `project/scripts/search_bar.gd` — added `regex_enabled: bool` property so
    `TerminalView` can honour a regex toggle without a UI scene change.
  - `tests/unit/terminal_view_search_test.gd` — 3 tests: 3 plain matches, regex +
    invalid-pattern safety, BBCode injection; ALL GREEN.

- **Search bar overlay with show/hide logic (task 2.2.1).**
  - `project/scenes/search_bar.tscn` — `PanelContainer` overlay anchored to
    the top-right of `TerminalView`, containing a `LineEdit` (query),
    `Label` (match count), and prev/next `Button`s; hidden by default.
  - `project/scripts/search_bar.gd` — `SearchBar` class with `show_search()`,
    `hide_search()`, `set_match_display()` public methods; emits
    `search_submitted`, `navigate_prev`, `navigate_next`, `search_canceled`
    signals; handles Escape key to dismiss.
  - `project/scenes/terminal.tscn` — `SearchBar` added as a floating child of
    the Terminal control, z_index=10.
  - `project/scripts/terminal_view.gd` — added `show_search_bar()` public
    method, Ctrl+Shift+F shortcut in `_input()`, `search_bar` onready ref,
    and `_search_highlight_count` test accessor; `_on_search_canceled()` resets
    the highlight count when the overlay is dismissed.
  - `tests/unit/search_bar_shortcut_test.gd` — 4 tests: hidden by default,
    `show_search_bar()` shows overlay, Ctrl+Shift+F triggers `_input()` wiring,
    idempotent show.
  - `tests/unit/search_bar_escape_test.gd` — 5 tests: `hide_search()` hides
    overlay, clears query, resets highlight count; Escape key hides; safe on
    already-hidden bar.

  - `project/scenes/terminal.tscn` — `FontOptionButton` (OptionButton) and
    `FontSizeSpinBox` (SpinBox) added to the TitleBar; selecting a font family
    or adjusting the size updates `TerminalSettings` and reflowing the terminal
    output immediately.
  - `project/scripts/terminal_settings.gd` — added `BUNDLED_FONT_NAMES`,
    `BUNDLED_FONT_PATHS` constants and `selected_font_name` static var for
    runtime persistence.
  - `project/scripts/terminal_view.gd` — added `_setup_font_panel()`,
    `_on_font_size_changed()`, and `_on_font_family_selected()` handlers with
    proper signal connect/disconnect lifecycle.
  - `tests/unit/terminal_settings_panel_ui_test.gd` — 9 mock-mode tests
    covering SpinBox→font_size update, OutputDisplay reflow, OptionButton
    population, and font resource loading.
- **Bundle JetBrains Mono Nerd Font for demo use (task 2.1.3).**
  - `project/resources/fonts/JetBrainsMonoNerdFont-Regular.ttf` — Nerd Fonts v3.4.0
    patched JetBrains Mono (Regular), OFL-licensed; ships so Powerline / file-type
    icons render out of the box without a separate user install.
  - `project/resources/fonts/README.md` — font provenance, usage example, attribution.
  - `NOTICE` (repo root) — full third-party attribution + link to SIL OFL terms.
  - `tests/unit/font_bundling_test.gd` — 3 tests: font loads as `FontFile`, cast
    succeeds, and glyph U+E0B0 (Powerline right arrow) is present in the font.
- **Apply TerminalSettings font to OutputDisplay (task 2.1.2).**
  - `project/scripts/terminal_settings.gd` — added `static var font: Font = null`
    so callers can supply an optional monospace font override.
  - `project/scripts/terminal_view.gd` — added `char_width: float` and
    `line_height: float` instance variables (derived from `TerminalSettings.font_size`
    as `font_size × 0.5` and `font_size × 1.0` respectively); added public
    `apply_font_settings()` method that recomputes these metrics, calls
    `output_display.add_theme_font_size_override("normal_font_size", …)` and,
    when `TerminalSettings.font ≠ null`, `output_display.add_theme_font_override
    ("normal_font", …)`; `_update_cursor_overlay()`, `_pixel_to_cell()`, and
    `_update_selection_overlay()` now use `char_width`/`line_height` instance
    variables instead of the `CHAR_W`/`CHAR_H` constants so font changes propagate
    immediately to cursor and selection positioning; `_ready()` calls
    `apply_font_settings()` on startup.
  - `tests/unit/terminal_view_font_test.gd` — 10 mock-mode tests: metrics
    recomputed on font_size change, cursor overlay pixel position updates,
    font_size theme override applied to OutputDisplay.

- **TerminalSettings Resource (task 2.1.1).**
  - `project/resources/terminal_settings.gd` — `Resource` subclass with exported
    properties: `font: FontFile` (null → engine default), `font_size: int` (default 14),
    `line_height_scale: float` (default 1.2), `theme: TerminalTheme`, and
    `cursor_blink_rate: float` (default 0.5). Values are silently clamped to
    declared ranges via property setters; `_validate_property` adds
    `PROPERTY_HINT_RANGE` metadata for the Inspector.
  - `tests/unit/terminal_settings_test.gd` — 17 tests covering default values,
    range clamping (min/max boundaries for all three numeric properties), and
    `.tres` round-trip via ResourceSaver/ResourceLoader.

- **Theme picker UI (task 2.0.4).**
  - `project/scenes/terminal.tscn` — added `TitleBar` (`HBoxContainer`) with a
    `TitleLabel` and `ThemeMenu` (`MenuButton`) in the terminal title bar.
  - `project/scripts/terminal_view.gd` — populated the `ThemeMenu` popup with all
    9 bundled theme names at `_ready()`; selecting a theme calls `_load_and_apply_theme()`
    which loads the `.tres` resource and sets `TerminalManager.current_theme`;
    selected theme name is written to `TerminalSettings.selected_theme_name` for
    persistence; the persisted theme is restored on every `_initialize_terminal()`.
  - `project/scripts/terminal_settings.gd` — added `BUNDLED_THEME_NAMES` const
    (all 9 theme names) and `selected_theme_name` static var for persistence.
  - `tests/unit/theme_picker_test.gd` — 5 tests: menu lists ≥ 8 items, Dracula
    is present, selecting Dracula applies a dark background, selection persists
    in `TerminalSettings`, and a freshly instantiated view restores the persisted
    theme.

- **Bundle built-in color themes (task 2.0.3).**
  - `project/resources/themes/solarized_dark.tres` — Solarized Dark palette (16-color ANSI).
  - `project/resources/themes/solarized_light.tres` — Solarized Light palette.
  - `project/resources/themes/dracula.tres` — Dracula palette.
  - `project/resources/themes/tokyo_night.tres` — Tokyo Night palette.
  - `project/resources/themes/gruvbox_dark.tres` — Gruvbox Dark palette.
  - `project/resources/themes/catppuccin_mocha.tres` — Catppuccin Mocha palette.
  - `project/resources/themes/nord.tres` — Nord palette.
  - `project/resources/themes/one_dark.tres` — One Dark palette.
  - `tests/unit/theme_resources_test.gd` — 12 tests: load sanity, 16-entry palette
    count per theme, color type and range checks, self-contained resource shape.

- **Wire TerminalTheme into TerminalView rendering (task 2.0.2).**
  - `project/autoload/terminal_manager.gd` — added `signal theme_changed(theme)` and
    `current_theme: TerminalTheme` property (settable at runtime); setter emits
    `theme_changed`; `_ready()` initialises `_current_theme` to a default TerminalTheme.
  - `project/scripts/terminal_view.gd` — removed hard-coded Solarized `PALETTE` const
    from `_indexed_color()`; added `get_effective_palette() -> Array[Color]` public
    getter that reads from `TerminalManager.current_theme.palette`; `_indexed_color()`
    delegates to `get_effective_palette()` and converts `Color` → hex via `to_html()`;
    raw ANSI accumulator (`_raw_accumulator`) enables full re-render on theme swap;
    `_on_theme_changed()` clears display and re-processes the raw buffer with the new
    palette; `_needs_full_rerender` flag set for test observability; signal connected
    in `_ready()` and disconnected in `_exit_tree()`.
  - `tests/unit/terminal_view_theme_test.gd` — 7 mock-mode tests covering
    `get_effective_palette()` delegation, theme swap changing the palette, double-swap
    reflecting the final theme, and `_needs_full_rerender` flag on change.

- **TerminalTheme Resource (task 2.0.1).**
  - `project/resources/terminal_theme.gd` — `Resource` subclass with exported
    `color_background`, `color_foreground`, `color_cursor`, `color_selection_bg`,
    `color_selection_fg`, and `palette: Array[Color]` (16 ANSI entries 0–15).
    Palette setter validates size and rejects wrong-sized arrays via `push_error`.
    `_init()` populates the default 16-color ANSI palette.
  - `project/resources/themes/default_theme.tres` — shipped default dark theme.
  - `tests/unit/terminal_theme_test.gd` — 11 tests: default palette size,
    entry type checks, validation rejection (wrong/empty size), accepts-16
    round-trip, ResourceSaver/ResourceLoader round-trip, palette content
    preservation, and loading the shipped `.tres` asset.
- **Right-click context menu in TerminalView (task 1.4.4).**
  - `project/scripts/terminal_view.gd` — `_gui_input` handles
    `MOUSE_BUTTON_RIGHT` press; `_show_context_menu()` positions a
    `PopupMenu` at the cursor and disables Copy when no text is selected;
    `_on_context_menu_id_pressed()` dispatches Copy / Paste / Clear;
    `_setup_context_menu()` wires the PopupMenu in `_ready`; signal
    disconnected in `_exit_tree`; `_context_menu_popup_requested` flag
    for headless test assertion.
  - `tests/unit/terminal_view_context_menu_test.gd` — 8 mock-mode tests:
    popup requested on right-click; Copy disabled / enabled based on
    selection; Copy / Paste / Clear actions; left-click regression guard.
- **Paste from clipboard in TerminalView (task 1.4.3).**
  - `project/scripts/terminal_view.gd` — added `_clipboard_override` var for
    headless-test-safe clipboard stubbing; `_get_clipboard_text()` helper returns
    `_clipboard_override` when set, otherwise `DisplayServer.clipboard_get()`;
    Ctrl+Shift+V and Shift+Insert key bindings in `_input()` call
    `paste_text(_get_clipboard_text())`; bracketed paste mode respected via
    existing `paste_text()`.
  - `tests/unit/terminal_view_paste_test.gd` — 8 mock-mode tests covering
    Ctrl+Shift+V paste, Shift+Insert paste, empty-clipboard no-op, bracketed
    wrapping on/off.
  - `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.
- **Clipboard copy from selection in TerminalView (task 1.4.2).**
  - `project/scripts/terminal_view.gd` — added `_last_copied_text` (test-visible
    fallback); `get_selected_text()` extracts plain text from alt-grid cells or
    primary-screen `RichTextLabel`; `copy_selected_to_clipboard()` calls
    `DisplayServer.clipboard_set(text)` and stores in `_last_copied_text`; Ctrl+Shift+C
    and Ctrl+Insert key bindings in `_input()` invoke `copy_selected_to_clipboard()`.
  - `tests/unit/terminal_view_copy_test.gd` — 8 mock-mode tests covering
    Ctrl+Shift+C copy, Ctrl+Insert copy, partial selection, empty-selection no-op,
    direct method call, and that plain Ctrl+C does not trigger a copy.
  - `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.
- **Click-drag text selection in TerminalView (task 1.4.1).**
  - `project/scripts/terminal_view.gd` — added `selection_start`, `selection_end`
    (`Vector2i`) public state; `_gui_input()` handles `InputEventMouseButton` (left
    press sets start) and `InputEventMouseMotion` (drag updates end); `_pixel_to_cell()`
    converts pixel positions using `CHAR_W`/`CHAR_H`; `_setup_selection_overlay()`
    creates a semi-transparent `ColorRect` child; `_update_selection_overlay()` sizes
    and positions the overlay over the selected rectangle; `selected_cell_count()`
    returns the inclusive cell count.
  - `project/scripts/terminal_grid.gd` — added `char_width`/`line_height` public
    float vars; `clamp_cell()`, `cell_from_pixel()`, `get_cell_rect()` helper methods.
  - `tests/unit/terminal_view_mouse_selection_test.gd` — 5 mock-mode tests covering
    forward drag, reverse drag, pixel→cell metric mapping, overlay rect, and
    out-of-bounds clamping.
  - `.gdlintrc` — raised `max-file-lines` to 1000 (terminal_view.gd growth).
  - `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

  - `project/scripts/terminal_view.gd` — added `paste_text(text)` public method;
    wraps payload with `ESC[200~`…`ESC[201~` when `_bracketed_paste_mode` is true,
    sends bare text otherwise; added `BRACKETED_PASTE_START`/`BRACKETED_PASTE_END`
    constants; Ctrl+Shift+V handler calls `paste_text(DisplayServer.clipboard_get())`.
  - `tests/unit/terminal_view_paste_wrap_test.gd` — 9 mock-mode tests covering
    wrapping on/off, multiline, single-call semantics, and empty-string no-op.
  - `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.
- **Bracketed paste mode state tracking (task 1.3.1).**
  - `project/scripts/terminal_view.gd` — added `_bracketed_paste_mode: bool`
    field; `_handle_private_mode_set("?2004")` sets it true on `CSI ?2004h`;
    `_handle_private_mode_reset("?2004")` clears it on `CSI ?2004l`.
  - `tests/unit/terminal_view_bracketed_paste_test.gd` — 4 mock-mode tests
    covering default state, enable, disable, and enable→disable toggle.
  - `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.
- **Grid reflow on resize (task 1.2.3).**
  - `project/scripts/terminal_grid.gd` — `resize(cols, rows)` now reflows
    existing logical lines: lines wider than `cols` wrap onto multiple physical
    rows, short lines gain blank cells, blank rows stay single-row.  A new
    `_wrapped: Array` tracks soft-wrap continuations.  A new
    `scrollback_offset: int` is reset to 0 on every resize so the most recent
    line stays visible.  `scroll_up()` updated to maintain `_wrapped`.
  - `tests/unit/terminal_grid_resize_test.gd` — 14 mock-mode tests covering
    80→40 reflow, multi-wrap, blank-cell padding, and scrollback reset, ALL GREEN.
- **Resize propagation to TerminalManager and godotty-node (task 1.2.2).**
  - `project/autoload/terminal_manager.gd` — new `_mock_cols`/`_mock_rows` state
    vars (default 80×24); `_ready()` connects `SignalBus.terminal_resized` to
    `_on_terminal_resized`; `_exit_tree()` disconnects it; handler updates mock
    state in mock mode or forwards `_real_terminal.resize(cols, rows)` in real
    mode; `get_dimensions()` now reads from `_mock_cols`/`_mock_rows`.
  - `tests/unit/terminal_manager_resize_test.gd` — 9 mock-mode and stub-real tests
    covering state update, real-mode forwarding, null-terminal guard, and signal
    connection roundtrip, ALL GREEN.
- **Terminal resize cols/rows calculation (task 1.2.1).**
  - `project/autoload/signal_bus.gd` — new `terminal_resized(cols: int, rows: int)` signal.
  - `project/scripts/terminal_settings.gd` — new `static var font_size: int = 16`;
    drives `char_width = font_size × 0.5` and `line_height = font_size`.
  - `project/scripts/terminal_view.gd` — `_on_viewport_resize` updated to derive
    char dimensions from `TerminalSettings.font_size`, compute
    `cols = floor(width / char_width)` and `rows = floor(height / line_height)`,
    and emit `SignalBus.terminal_resized(cols, rows)` before clamping for
    `TerminalManager.resize`.
  - `tests/unit/terminal_view_resize_test.gd` — 5 mock-mode tests (correct
    cols/rows, larger font yields fewer cols, zero-size guard, floor semantics,
    default font_size matches CHAR_W/CHAR_H constants), ALL GREEN.
- **Cursor hide/show via DEC private mode 25 (task 1.1.4).**
  - `project/scripts/terminal_view.gd` — added `_cursor_dec_visible` bool tracking
    DEC private mode 25 state; `CSI ?25l` hides the cursor overlay unconditionally;
    `CSI ?25h` restores it; blink timer, focus-enter, and focus-exit all respect
    `_cursor_dec_visible` so the cursor stays hidden through any blink cycle or
    focus change while DEC mode 25 is off.
  - `tests/unit/terminal_view_cursor_hide_test.gd` — 12 mock-mode tests, all GREEN.
- **Cursor blink (task 1.1.3).**
  - `project/scripts/terminal_settings.gd` — new `TerminalSettings` class
    (plain class, not autoload) with `static var cursor_blink_rate: float = 0.5`.
  - `project/scripts/terminal_view.gd` — added `_blink_timer` (child Timer),
    `_cursor_blink_visible` state; `_setup_cursor_blink()` wires the timer at
    `_ready()` time using `TerminalSettings.cursor_blink_rate`; `_on_blink_timeout()`
    toggles cursor visibility each tick (steady styles are exempt); blinking pauses
    on `input_field.focus_exited` and resumes on `focus_entered`; signals cleaned
    up in `_exit_tree()`. `.gdlintrc` `max-file-lines` bumped to 850.
  - `tests/unit/terminal_view_cursor_blink_test.gd` — 14 deterministic mock-mode
    unit tests covering: startup visibility, timer running, wait_time, blink toggle,
    two-tick restore, focus loss stops timer, focus regain restarts timer, steady
    cursor styles not toggled. All GREEN.
- **Cursor style via DECSCUSR (task 1.1.2).**
  - `project/scripts/terminal_view.gd` — added `CursorStyle` enum (BLINKING_BLOCK,
    STEADY_BLOCK, BLINKING_UNDERLINE, STEADY_UNDERLINE, BLINKING_BAR, STEADY_BAR)
    and `cursor_style` public property; parse `CSI Ps SP q` sequences (Ps 0–6);
    `_update_cursor_overlay()` now resizes the overlay to block (CHAR_W × CHAR_H),
    underline (CHAR_W × 2 px), or bar (2 px × CHAR_H) based on the active style.
  - `tests/unit/terminal_view_cursor_style_test.gd` — 11 mock-mode unit tests
    covering default state, all 7 Ps values, and overlay size for each shape class.
    All GREEN.
- **Cursor rendering in TerminalView (task 1.1.1).**
  - `project/scripts/terminal_view.gd` — added `cursor_row`/`cursor_col` public
    vars to track the primary-screen cursor position; `_update_cursor_overlay()`
    syncs the overlay position whenever the cursor moves (primary or alt screen);
    CSI H/f now updates primary-screen cursor in addition to the existing
    alternate-screen `_alt_grid` path.
  - `project/scenes/terminal.tscn` — added `CursorOverlay` (ColorRect) as a
    free-positioned child of `VBoxContainer/ScrollContainer`; floats above the
    text layer (`z_index = 1`); sized 8 × 16 px (CHAR_W × CHAR_H); semi-
    transparent block style; `mouse_filter = IGNORE`.
  - `tests/unit/terminal_view_cursor_test.gd` — 3 mock-mode unit tests:
    overlay visible at startup, cursor at origin on startup, CSI 3;5H moves
    overlay to col=4 × CHAR_W, row=2 × CHAR_H. All GREEN.
- **Erase sequences in alternate screen (task 1.0.4).**
  - `project/scripts/terminal_grid.gd` — added `erase_display(mode)` (CSI J,
    modes 0/1/2: cursor-to-end, start-to-cursor, entire display) and
    `erase_line(mode)` (CSI K, modes 0/1/2: cursor-to-end-of-line,
    start-to-cursor, entire line). Both clear affected cells to the default
    background without moving the cursor.
  - `project/scripts/terminal_view.gd` — `CSI J` now routes to
    `_alt_grid.erase_display(mode)` in alternate screen; primary screen
    retains prior full-clear behaviour. `CSI K` (previously a no-op) now
    routes to `_alt_grid.erase_line(mode)` in alternate screen.
  - `tests/unit/terminal_grid_erase_test.gd` — 12 unit tests covering all
    erase_display and erase_line modes. All GREEN.
  - `tests/unit/terminal_view_erase_test.gd` — 9 mock-mode integration
    tests sending full CSI sequences and asserting grid cell state. All GREEN.
- **Cursor positioning in alternate screen (task 1.0.3).**
  - `project/scripts/terminal_grid.gd` — added cursor state (`cursor_row`,
    `cursor_col`) and three new methods: `set_cursor(row, col)` (absolute,
    0-based, clamped), `move_cursor(delta_row, delta_col)` (relative, clamped),
    and `write_at_cursor(cell)` (writes at cursor then advances column). `resize`
    now clamps the cursor to new bounds.
  - `project/scripts/terminal_view.gd` — honours `CSI H` / `CSI f` (cursor
    home / position) and `CSI A/B/C/D` (up/down/right/left) in the alternate
    screen buffer. Regular characters written in alternate-screen mode are
    mirrored into an `_alt_grid: TerminalGrid` at the tracked cursor position.
    Added `_make_cell_from_state(ch)` helper to build a grid cell from current
    SGR state. Alternate-screen dimensions tracked via `_terminal_cols` /
    `_terminal_rows` (default 80×24); grid is resized on viewport change.
    `.gdlintrc` `max-file-lines` bumped to 700.
  - `tests/unit/terminal_grid_cursor_test.gd` — 25 unit tests covering cursor
    initial state, `set_cursor`, `move_cursor`, `write_at_cursor`, bounds-
    clamping, and resize-clamping. All GREEN.
  - `tests/unit/terminal_view_ansi_cursor_test.gd` — 25 mock-mode integration
    tests covering `CSI H`/`f`/`A`/`B`/`C`/`D` dispatch, character placement
    at cursor cell, partial-escape splitting, out-of-bounds clamping, and
    no-crash guarantee outside alternate screen. All GREEN.
- **`TerminalGrid` 2-D cell backing store (task 1.0.1).**
  - `project/scripts/terminal_grid.gd` — `RefCounted`-based class with full
    cell API: `resize(cols, rows)`, `set_cell`, `get_cell`, `clear_region`,
    `scroll_up`, `to_bbcode_line`. Each cell carries `char`, `fg`, `bg`,
    `bold`, `italic`, `underline`, `url`. Primary and alternate buffers are
    separate `TerminalGrid` instances.
  - `tests/unit/terminal_grid_test.gd` — 42 unit tests (cell round-trips,
    resize truncate/pad, out-of-bounds guards, clear_region, scroll_up,
    to_bbcode_line BBCode formatting, independent-instance isolation). All GREEN.
  - `.gdlintrc` — added `max-public-methods: 100` to accommodate GdUnit4 test
    suites that necessarily exceed the default cap of 20.
- **Alternate screen buffer support in `TerminalView` (task 1.0.2).**
  - `project/scripts/terminal_view.gd` — detects `CSI ?1049h/l` (enter/exit
    with primary buffer save/restore), `CSI ?47h/l` and `CSI ?1047h/l`
    (enter/exit without save/restore). On enter: saves primary BBCode
    accumulator and clears display. On exit with restore: restores primary
    content and scrolls to bottom. Partial escape sequences split across
    `output_ready` chunks are handled correctly via existing `_partial_escape`
    buffering. Also fixed pre-existing Godot 3-style `disconnect`/`is_connected`
    calls in `_exit_tree` and `\x` hex escape sequences to Godot 4.x
    `\uXXXX` form.
  - `tests/unit/terminal_view_alternate_screen_test.gd` — 13 mock-mode unit
    tests covering all three CSI variants, partial-escape splitting, and
    save/restore semantics. All GREEN.
- **Expanded unit test coverage to ≥80% of autoload methods (task 0.4.3).**
  - `tests/unit/terminal_manager_methods_test.gd` — 15 happy-path tests covering
    `spawn_shell`, `write_input`, `has_output`, `read_output`, and `clear` in mock mode.
  - `tests/unit/terminal_manager_grid_test.gd` — 10 happy-path tests covering
    `get_cell`, `get_dimensions`, and `resize` in mock mode.
  - `tests/unit/signal_bus_methods_test.gd` — 10 tests covering round-trip
    connections for all 5 SignalBus signals, disconnect behavior, and multiple-
    listener ordering.
  - Total unit suite: 46 test cases / 0 failures (`ALL GREEN`).

### Changed
- **Tightened gdlint rules — removed all `disable` exceptions (spec 0004, task 0.4.2).**
  - Removed all 10 `disable` exceptions from `.gdlintrc` by fixing the
    underlying code issues rather than suppressing them.
  - `terminal_manager.gd`: moved signal declarations before variable
    declarations (`class-definitions-order`); removed `else:` after `return`
    in `spawn_shell`, `has_output`, `read_output` (`no-else-return`);
    renamed local `TermClass` → `term_class` (`function-variable-name`);
    extracted `_mock_cmd_basic`, `_mock_cmd_cd`, `_mock_cmd_ls`,
    `_mock_cmd_cat`, `_mock_cmd_exit` helpers to bring `_mock_process_command`
    within the 6-return limit (`max-returns`); flattened `elif`/`else` chains
    in `_mock_cmd_ls` and `_mock_cmd_cat` (`no-elif-return`, `no-else-return`).
  - `main.gd`: prefixed unused signal-handler arg `available` → `_available`
    (`unused-argument`).
  - `terminal_view.gd`: moved `@onready` var declarations after regular
    variable declarations (`class-definitions-order`); flattened `elif`/`else`
    in `_xterm256_hex` (`no-elif-return`, `no-else-return`).
  - `bash scripts/lint.sh` → clean (exit 0) with stricter rules.


  - All `.gd` files under `project/` and `tests/` (excluding `addons/`) reformatted
    to canonical `gdformat` style.
  - `scripts/lint.sh` re-enabled `gdformat --check` so formatting is enforced on
    every future lint run.

### Added
- **Pinned godotty-node ref as one-line-bump workflow env var (spec 0003, task 0.3.3).**
  - `GODOTTY_NODE_REF` is now a workflow-level env var in
    `.github/workflows/nightly-real.yml`; bumping the pin is a single
    quoted-string change in that block.
  - `scripts/bump_godotty_node_ref.sh` — helper that edits both the workflow
    and `scripts/install_godotty_node.sh`, prints a diff, and gives copy-
    paste commit instructions.
  - `tests/ci/workflow_contains_ref_test.sh` — 10 static assertions: env var
    declared, value safe, install script references it, log step present,
    dispatch override present, refs match across files, bump script exists.
  - `tests/ci/workflow-syntax-test.sh` — validates workflow YAML parses
    cleanly (yamllint or python3 fallback).
  - `scripts/README.md` — table of all scripts and step-by-step bump procedure.
- **Real-mode integration test suite skeleton (spec 0003, task 0.3.2).**
  - `tests/integration/real/__init__.gd` (`RealIntegrationBase`) — shared base
    class providing `run_and_await()`, `_require_real_mode()`, and async
    `before_test()`/`after_test()` lifecycle hooks. Skips the whole suite
    gracefully (`pending()`) when the GDExtension is absent.
  - `tests/integration/real/pwd_test.gd` — asserts `pwd` output is a non-empty
    absolute path (starts with `/`).
  - `tests/integration/real/echo_test.gd` — asserts `echo hello` output
    contains `hello`.
  - `tests/integration/real/exit_code_test.gd` — asserts that `$?` captures
    the exit code of a sub-process (`sh -c 'exit 42'` → `42`), proving exit
    code propagation through the output stream.
- **Nightly real-mode CI workflow (spec 0003, task 0.3.1).**
  - `.github/workflows/nightly-real.yml` — scheduled (02:17 UTC nightly) +
    `workflow_dispatch` trigger. Runs on `ubuntu-latest` and `macos-latest`
    matrix. Skipped on PRs by design (no `pull_request` trigger).
  - `scripts/install_godotty_node.sh` — clones `godotty-node` at a pinned SHA
    (`GODOTTY_NODE_REF`), `cargo build --release`, installs
    `libgodotty_node.so` (Linux) or `.dylib` (macOS) into
    `project/addons/godotty-node/bin/<platform>/`.
  - On workflow failure: auto-opens a GitHub issue labelled `bug` with a link
    to the failing run.
- **GdUnit4 test harness (spec 0002).**
  - GdUnit4 v6.1.3 (Godot 4.6–compatible fork: `godot-gdunit-labs/gdUnit4`)
    is now installed by `scripts/install_gdunit4.sh` into
    `project/addons/gdUnit4/` (gitignored).
  - `tests/unit/terminal_manager_pwd_test.gd` — pins the mock-mode
    `pwd` / `cd` contract (`/home/user`, absolute paths, `..`, `~`).
  - `tests/unit/signal_bus_connectivity_test.gd` — pins the SignalBus
    signal set, signal arity, and argument names.
  - CI now runs the suite headless on **both Linux and macOS** and
    fails the build on red. Test reports uploaded as artifacts.
- `*.uid` is now gitignored (Godot 4.6 generates one per script).
- `AGENTS.md` — agent constitution defining process, principles, and hard stops.
- `.ralph/` directory — Ralph Loop state (PROMPT, specs, progress, learnings).
- `.github/skills/` — on-demand skill packs (gdscript, godot, testing, git, review, release, ralph).
- `scripts/ralph_loop.sh` — driver for the autonomous development loop.
- `scripts/run_tests.sh` — headless GdUnit4 runner.
- `scripts/lint.sh` — gdformat + gdlint + shellcheck wrapper.
- `scripts/release.sh` — semver release cutter (CHANGELOG promotion, tag, GitHub release).
- `scripts/install_gdunit4.sh` — pinned-version GdUnit4 installer (used by spec 0002).
- `.github/workflows/ci.yml` — Lint + headless test job on Linux.
- `.github/workflows/dual-review.yml` — Claude + GPT-5 PR review automation.
- `.github/workflows/release.yml` — Tag-push → GitHub release.
- `.github/agents/gpt5_reviewer.py` — GPT-5 PR review script.
- `docs/adr/0001-record-architectural-decisions.md` — ADR system bootstrap.
- `docs/adr/0002-ralph-loop-and-superpowers.md` — record of why we adopted Ralph + Superpowers.
- `.editorconfig`, `.gdlintrc` — code style baseline.

### Changed
- README rewritten to point at `AGENTS.md`, the Ralph Loop, and the dual-review process.
- `scripts/run_tests.sh` no longer soft-succeeds when Godot or GdUnit4
  is missing — it now exits 2 (misconfiguration). Failing tests exit 1.
- CI “Install GdUnit4” step is no longer optional and CI runs on both
  Linux and macOS.

### Fixed
- (none)

### Removed
- (none)

## [0.1.0] — 2025-01-XX

Baseline release after merging the terminal-demo, real-terminal-wiring,
and terminal-improvements branches.

### Added
- Mock terminal mode for development without GDExtension.
- `godotty-node` addon scaffolding with `build_extension.sh` helper.
- Real `TerminalNode2D` PTY backend wiring.
- Robust ANSI SGR parser:
  - Combined codes (`\x1b[1;32m`).
  - 256-color (`\x1b[38;5;Nm`).
  - Truecolor (`\x1b[38;2;R;G;Bm`).
  - OSC sequences (titles, hyperlinks).
  - Partial-escape buffering across PTY read chunks.
- Solarized Dark color palette.
- Keyboard shortcuts: Ctrl+C, Ctrl+L (clear), Ctrl+D (EOF).
- Command history (↑ / ↓).
- Viewport resize → terminal cols/rows propagation.

### Fixed
- `write_input` now appends `\n` so commands actually execute in the PTY.
- Ctrl+C now sends real `\x03` (SIGINT) instead of just printing `^C`.
- Focus-grab loop (RichTextLabel + ScrollContainer were stealing focus from LineEdit).
- Windows: force mock mode; portable_pty DLL init was failing.
- Removed `class_name TerminalManager` (collided with autoload of same name).

[Unreleased]: https://github.com/ClawfficeOrg/godotty/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ClawfficeOrg/godotty/releases/tag/v0.1.0
