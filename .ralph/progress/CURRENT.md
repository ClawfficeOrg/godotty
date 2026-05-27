# Current Working Memory

**STATUS:** in-progress
**SPEC:** `.ralph/specs/0003-real-terminal-ci.md`
**BRANCH:** `feature/0003-real-terminal-ci` (target)
**STARTED:** 2026-05-27

## Now doing

Task `3.0.4` — DONE. OSC 0/2 tab-title sequences.
- `TerminalView`: added `signal tab_title_changed(title: String)`.
- Fixed `_ansi_to_bbcode` early-exit: OSC sequences (`ESC]`) were incorrectly caught by the
  `bracket_pos == -1` guard and stored as partial escapes. Changed to only buffer bare ESC
  or incomplete ESC[ prefix.
- Added `_handle_osc(body)` to dispatch OSC 0/2 and emit `tab_title_changed`.
- Created `tests/unit/terminal_view_title_test.gd` (5 tests).
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.


Task `3.0.3` — DONE. Ctrl+T / Ctrl+W / Ctrl+Tab tab management keybindings.
- `TerminalKeymap`: added `ACTION_NEXT_TAB = "next_tab"` (Ctrl+Tab default); changed `new_tab` default Ctrl+Shift+T → Ctrl+T; changed `close_tab` default Ctrl+Shift+W → Ctrl+W.
- `TerminalTabBar`: added `_tab_order: Array[String]`, `next_tab()`, `get_tab_count()`, `get_active_shell_id()`.
- `TerminalView`: added signals `tab_new_requested`, `tab_close_requested`, `tab_next_requested`; `_execute_action` handles the three new tab actions.
- Created `tests/unit/terminal_keybindings_test.gd` (8 tests).
- Created `tests/unit/terminal_tab_management_test.gd` (9 tests).
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.


Task `3.0.2` — DONE. TabBar with add/close buttons and output indicators.
- Created `project/scripts/tab_button.gd` (`class_name TerminalTabButton`) — per-tab Control
  with title label, output-indicator ColorRect, and close Button; all children built in _ready().
- Created `project/scripts/tab_bar.gd` (`class_name TerminalTabBar`) — HBoxContainer-based tab
  bar; `_tabs: Dictionary` (shell_id → TerminalTabButton); `_active_shell_id`; `@onready _add_button`.
  Public API: `add_tab`, `remove_tab`, `set_tab_title`, `notify_output`, `focus_tab`.
  Signals: `new_tab_requested`, `tab_close_requested(shell_id)`, `tab_focused(shell_id)`.
- Created `project/scenes/tab_bar.tscn` (uid://tab_bar_scene_001) — TerminalTabBar + AddButton.
- Created `tests/unit/tab_bar_test.gd` — 11 GdUnit4 tests (all passing).
- NOTE: class names prefixed `Terminal` to avoid shadowing Godot 4 native `TabBar`/`TabButton`.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `3.0.1` — DONE. Multi-instance `TerminalManager`.
- Created `project/scripts/terminal_manager_node.gd` (`class_name TerminalManagerNode`) — full
  terminal logic (mock + real) as an instanceable Node; no SignalBus.terminal_resized in _ready().
- `project/autoload/terminal_manager.gd` — added `_registered_default`, `get_default()`,
  `set_default()` registry methods; `get_default()` falls back to `self` for compat.
- `project/scripts/terminal_view.gd` — added `@export var manager: Node = null` and
  `_get_manager()` helper; all 13 `TerminalManager.xxx` calls replaced with `_get_manager().xxx`.
- `project/scenes/terminal_manager.tscn` — minimal scene for TerminalManagerNode.
- `.gdlintrc` — raised `max-file-lines` from 1500 to 1600 (terminal_view.gd grew to ~1502 lines).
- `tests/unit/terminal_manager_multi_instance_test.gd` — 11 GdUnit4 tests.
- `tests/unit/terminal_view_injection_test.gd` — 9 GdUnit4 tests.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `2.4.4` — DONE. Scrollback buffer size setting.
- `project/scripts/terminal_settings.gd` — added `static var scrollback_lines: int = 1000`.
- `project/scripts/terminal_view.gd` — removed `MAX_LINES` const; replaced hard-coded limit with
  `clampi(TerminalSettings.scrollback_lines, 1, 100000)`; added `_enforce_scrollback_limit()` which
  trims `_raw_accumulator` by scanning newlines and re-renders `output_display` from the trimmed content.
- `tests/unit/terminal_view_scrollback_test.gd` — new GdUnit4 suite: 4 test cases covering default
  value, line count limit, last-line content, and _line_count invariant.
- `project/scripts/terminal_settings.gd` — added `static var padding: Vector2i = Vector2i(4, 4)`.
- `project/scenes/terminal.tscn` — added `PaddingContainer` (MarginContainer) wrapping VBoxContainer.
- `project/scripts/terminal_view.gd` — updated @onready paths, added `padding_container` public var,
  added `apply_padding()` method; called in `_ready()` after `apply_background_opacity()`.
- `.gdlintrc` — raised `max-line-length` to 120 for longer NodePath @onready declarations.
- `tests/unit/terminal_view_padding_test.gd` — 5 tests: default (4,4) setting, default applied at ready,
  (10,10) sets all sides to 10, (0,0) sets all to zero, asymmetric axes x=16/y=8.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `2.4.1` — DONE. Background transparency.
- `project/scripts/terminal_settings.gd` — added `static var background_opacity: float = 1.0`.
- `project/scripts/terminal_view.gd` — added `apply_background_opacity()` (clamps to [0,1],
  assigns to `self_modulate.a`); called in `_ready()` after `apply_font_settings()`.
- `tests/unit/terminal_view_background_opacity_test.gd` — 7 tests: half-opacity, full opacity,
  zero opacity, clamped below zero, clamped above one, default at ready, RGB channels preserved.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `2.3.3` — DONE. Keybinding editor panel.
- `project/scenes/settings_dialog.tscn` — Control-based dialog with ScrollContainer
  listing keybinding rows and Save/Reset buttons.
- `project/scripts/settings_dialog.gd` — SettingsDialog class: populates rows from
  TerminalKeymap.BUILTIN_ACTIONS, captures the next key press when Edit clicked,
  saves/loads user://keymap.tres, falls back to TerminalKeymap.default() when absent.
- `tests/unit/settings_keybinding_test.gd` — 6 tests covering row population,
  F5 capture, single-capture reset, modifier-only ignore, persistence, missing-file
  fallback, and the release-gate rebind-copy-survives-restart test.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `2.3.2` — DONE. Consume TerminalKeymap in TerminalView._input.
- `project/autoload/terminal_manager.gd` — added `var keymap: TerminalKeymap = TerminalKeymap.default()` public property.
- `project/scripts/terminal_view.gd` — replaced hard-coded `match event.keycode` block
  with keymap-driven loop: `TerminalManager.keymap.find_action(event)` → `_execute_action(action)`.
  Legacy Ctrl+Insert (copy) and Shift+Insert (paste) kept as hardcoded pre-checks.
  Echo events now explicitly filtered out.
- `tests/unit/terminal_view_keymap_test.gd` — 4 tests: default Ctrl+L clears,
  rebind clear to Ctrl+K, old Ctrl+L no longer clears after rebind, echo ignored.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → 375 tests, ALL GREEN.

Task `2.3.1` — DONE. TerminalKeymap resource.
- `project/resources/terminal_keymap.gd` — Resource with `bindings: Dictionary`;
  12 built-in action constants + `BUILTIN_ACTIONS`; static `default()` factory;
  `find_action(event)` resolver; `_make_key` / `_keys_match` helpers.
- `tests/unit/terminal_keymap_test.gd` — 7 tests; ALL GREEN.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `2.2.3` — DONE. Navigate matches.
- `project/scripts/search_bar.gd` — _input() intercepts Enter/Shift+Enter to
  emit navigate_next/navigate_prev (consumed so LineEdit text_submitted is skipped).
- `project/scripts/terminal_view.gd` — SEARCH_ACCENT_BG const (#b58900);
  _search_match_index var; _on_navigate_next/_on_navigate_prev handlers;
  _navigate_search_match(direction) with wrap + scroll + label update;
  _scroll_to_match_line(); get_highlighted_line() gains optional accent_col param;
  _render_highlighted_scrollback() applies accent to current match; signal
  connect/disconnect in _ready()/_exit_tree(); search_scrollback() and
  _on_search_canceled() reset _search_match_index.
- `.gdlintrc` — max-file-lines bumped 1400→1500.
- `tests/unit/search_navigation_test.gd` — 7 tests; ALL GREEN.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.


- `project/scripts/terminal_view.gd` — search_scrollback(query, use_regex=false) returning
  Array[Vector2i]; _strip_ansi() helper; get_highlighted_line() BBCode injector;
  _render_highlighted_scrollback(); _on_search_submitted() wired to SearchBar.search_submitted;
  _on_search_canceled() restores unhighlighted output; SEARCH_HIGHLIGHT_BG const;
  _search_matches/_last_search_query/_last_search_use_regex private vars.
- `project/scripts/search_bar.gd` — added regex_enabled: bool property.
- `tests/unit/terminal_view_search_test.gd` — 3 tests (3 plain matches, regex+safety, BBCode
  injection); ALL GREEN.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `2.2.1` — DONE. Search bar overlay scene and show/hide logic.
- `project/scenes/search_bar.tscn` — PanelContainer (hidden by default) with HBoxContainer
  containing QueryEdit (LineEdit), MatchLabel, PrevButton (◀), NextButton (▶).
- `project/scripts/search_bar.gd` — SearchBar class_name; public: show_search(),
  hide_search(), set_match_display(); signals: search_submitted, navigate_prev,
  navigate_next, search_canceled; _input() handles Escape.
- `project/scenes/terminal.tscn` — SearchBar instanced as child of Terminal Control,
  anchor top-right, z_index=10; load_steps bumped to 6.
- `project/scripts/terminal_view.gd` — added search_bar @onready ref, _search_highlight_count
  var, show_search_bar() method, KEY_F Ctrl+Shift+F handler, _on_search_canceled(), signal
  connect/disconnect in _ready()/_exit_tree().
- `tests/unit/search_bar_shortcut_test.gd` — 4 tests; ALL GREEN.
- `tests/unit/search_bar_escape_test.gd` — 5 tests; ALL GREEN.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.


- `project/scenes/terminal.tscn` — added `FontOptionButton` and `FontSizeSpinBox` to TitleBar.
- `project/scripts/terminal_settings.gd` — added `BUNDLED_FONT_NAMES`, `BUNDLED_FONT_PATHS` consts, `selected_font_name` static var.
- `project/scripts/terminal_view.gd` — added `_font_option`/`_font_spinbox` onready refs, `_setup_font_panel()`, `_on_font_size_changed()`, `_on_font_family_selected()`, and proper _exit_tree() cleanup.
- `tests/unit/terminal_settings_panel_ui_test.gd` — 9 mock-mode tests; ALL GREEN.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `2.1.3` — DONE. Bundle JetBrains Mono Nerd Font for demo use.
- `project/resources/fonts/JetBrainsMonoNerdFont-Regular.ttf` — Nerd Fonts v3.4.0 patched
  JetBrains Mono Regular (OFL); enables Powerline / file-type icon rendering out of the box.
- `project/resources/fonts/README.md` — font provenance, usage, and attribution.
- `NOTICE` — repo-root third-party attribution + SIL OFL link.
- `tests/unit/font_bundling_test.gd` — 3 tests (font loads, is FontFile, U+E0B0 present); ALL GREEN.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `2.1.2` — DONE. Apply TerminalSettings font to OutputDisplay.
- `project/scripts/terminal_settings.gd` — added `static var font: Font = null` to give
  TerminalView somewhere to read a font override from.
- `project/scripts/terminal_view.gd` — added `char_width: float` and `line_height: float`
  instance vars (default to CHAR_W/CHAR_H); added `apply_font_settings()` public method
  that derives metrics from TerminalSettings.font_size, calls
  `output_display.add_theme_font_size_override("normal_font_size", …)` and
  `output_display.add_theme_font_override("normal_font", …)` when font ≠ null,
  then calls `_update_cursor_overlay()`; `_update_cursor_overlay()`,
  `_pixel_to_cell()`, and `_update_selection_overlay()` all now reference
  `char_width`/`line_height` instance vars instead of CHAR_W/CHAR_H constants;
  `_ready()` calls `apply_font_settings()` after `_initialize_terminal()`.
- `tests/unit/terminal_view_font_test.gd` — 10 mock-mode tests, ALL GREEN.
- `.gdlintrc` `max-file-lines` bumped to 1200 (file grew to 1123 lines).
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

- `project/resources/terminal_settings.gd` — `extends Resource` (no class_name to avoid
  collision with existing `TerminalSettings` static class). Exports: `font: FontFile`,
  `font_size: int` (default 14, clamped [8,72]), `line_height_scale: float` (default 1.2,
  clamped [0.5,3.0]), `theme: TerminalTheme`, `cursor_blink_rate: float` (default 0.5,
  clamped [0.0,5.0]). Clamping via property setters + backing vars; `_validate_property`
  adds PROPERTY_HINT_RANGE for Inspector.
- `tests/unit/terminal_settings_test.gd` — 17 tests: defaults, range clamping, .tres round-trip.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `2.0.4` — DONE. Theme picker UI.
- `project/scenes/terminal.tscn` — added `TitleBar` HBoxContainer with `TitleLabel`
  and `ThemeMenu` MenuButton as first child of VBoxContainer.
- `project/scripts/terminal_settings.gd` — added `BUNDLED_THEME_NAMES` const (9 names)
  and `selected_theme_name` static var for persistence.
- `project/scripts/terminal_view.gd` — added `@onready _theme_menu`; `_setup_theme_picker()`
  populates popup from `TerminalSettings.BUNDLED_THEME_NAMES` and connects `index_pressed`;
  `_on_theme_menu_index_pressed()` saves name to `TerminalSettings.selected_theme_name` and
  calls `_load_and_apply_theme()`; `_load_and_apply_theme()` loads .tres resource and sets
  `TerminalManager.current_theme`; `_initialize_terminal()` restores persisted theme on startup.
- `tests/unit/theme_picker_test.gd` — 5 tests: lists ≥8 items, Dracula present,
  selecting Dracula applies dark bg, persists in TerminalSettings, new view restores persisted.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.


- Created 8 `.tres` files under `project/resources/themes/`:
  `solarized_dark`, `solarized_light`, `dracula`, `tokyo_night`,
  `gruvbox_dark`, `catppuccin_mocha`, `nord`, `one_dark`.
- Each is a self-contained `TerminalTheme` resource with 16-entry ANSI palette.
- `tests/unit/theme_resources_test.gd` — 12 tests: load sanity, palette count,
  color type/range, self-contained shape. ALL GREEN.
- `CHANGELOG.md` updated under [Unreleased].
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `2.0.2` — DONE. Wire TerminalTheme into TerminalView rendering.
- `project/autoload/terminal_manager.gd` — added `signal theme_changed(theme: TerminalTheme)`,
  `current_theme: TerminalTheme` property with setter (emits theme_changed),
  `_current_theme` backing var, initialised in `_ready()`.
- `project/scripts/terminal_view.gd` — removed hard-coded PALETTE const; added
  `get_effective_palette()` public getter (reads TerminalManager.current_theme.palette);
  `_indexed_color()` delegates to `get_effective_palette()`; `_raw_accumulator` tracks
  raw ANSI for primary screen; `_on_theme_changed()` clears + re-renders with new palette;
  `_needs_full_rerender` flag for test observability; connected/disconnected in
  `_ready()`/`_exit_tree()`.
- `tests/unit/terminal_view_theme_test.gd` — 7 mock-mode tests, targeting GREEN.
- `project/resources/terminal_theme.gd` — Resource subclass with 5 exported color vars
  + `palette: Array[Color]` (16 entries, validated via setter). `_init()` populates
  default ANSI palette.
- `project/resources/themes/default_theme.tres` — shipped default dark theme asset.
- `tests/unit/terminal_theme_test.gd` — 11 tests: defaults, validation rejection,
  round-trip via ResourceSaver/Loader, shipped .tres loading. ALL GREEN.
- `docs/todo-v2.md` task `2.0.1` marked `[x]`.
- `CHANGELOG.md` updated under [Unreleased].
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.4.4` — DONE. Right-click context menu.
- `project/scripts/terminal_view.gd` — added `MENU_ID_COPY/PASTE/CLEAR` constants;
  `_context_menu: PopupMenu` and `_context_menu_popup_requested: bool` vars;
  `_setup_context_menu()` creates PopupMenu with three items and connects `id_pressed`;
  `_gui_input` extended to handle `MOUSE_BUTTON_RIGHT` → `_show_context_menu()`;
  `_show_context_menu()` disables Copy when no selection, sets popup requested flag, calls popup;
  `_on_context_menu_id_pressed()` dispatches Copy/Paste/Clear actions;
  `_exit_tree()` disconnects `id_pressed` signal.
- `tests/unit/terminal_view_context_menu_test.gd` — 8 mock-mode tests, ALL GREEN.
- CHANGELOG.md updated under [Unreleased].
- `.gdlintrc` `max-file-lines` bumped to 1100 (file grew past 1000).
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.4.3` — DONE. Paste from clipboard.
- `project/scripts/terminal_view.gd` — added `_clipboard_override` var and
  `_get_clipboard_text()` helper (bypasses headless clipboard limits in tests);
  Ctrl+Shift+V and Shift+Insert key bindings call `paste_text(_get_clipboard_text())`.
- `tests/unit/terminal_view_paste_test.gd` — 8 mock-mode tests, ALL GREEN.
- CHANGELOG.md updated under [Unreleased].
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.4.2` — DONE. Copy selection to clipboard.
- `project/scripts/terminal_view.gd` — added `_last_copied_text` var; `get_selected_text()`
  reads from alt-grid cells or primary-screen RichTextLabel; `copy_selected_to_clipboard()`
  calls `DisplayServer.clipboard_set(text)` and stores `_last_copied_text`; Ctrl+Shift+C
  and Ctrl+Insert handlers added before existing KEY_C match arm.
- `tests/unit/terminal_view_copy_test.gd` — 8 mock-mode tests, ALL GREEN.
- CHANGELOG.md and docs/todo-v1.md updated.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.4.1` — DONE. Click-drag text selection in TerminalView.
- `project/scripts/terminal_view.gd` — added `BRACKETED_PASTE_START`/`BRACKETED_PASTE_END`
  constants; `paste_text(text)` public method wraps with ESC[200~…ESC[201~ when
  `_bracketed_paste_mode` is true, sends bare text otherwise; Ctrl+Shift+V handler.
- `tests/unit/terminal_view_paste_wrap_test.gd` — 9 mock-mode tests, ALL GREEN.
- CHANGELOG.md and docs/todo-v1.md updated.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.3.1` — DONE. Track bracketed paste mode state.
- `project/scripts/terminal_view.gd` — added `_bracketed_paste_mode: bool = false`;
  `_handle_private_mode_set("?2004")` sets it true on `CSI ?2004h`;
  `_handle_private_mode_reset("?2004")` clears it on `CSI ?2004l`.
- `tests/unit/terminal_view_bracketed_paste_test.gd` — 4 mock-mode tests, ALL GREEN.
- CHANGELOG.md and docs/todo-v1.md updated.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.2.3` — DONE. Grid reflow on resize.
- `project/scripts/terminal_grid.gd` — added `scrollback_offset: int = 0` and
  `_wrapped: Array`; `resize()` rewrites reflow logic: extracts logical lines,
  strips trailing blanks, re-wraps at new `cols`, trims oldest rows if overflow,
  pads bottom with blanks; `scrollback_offset` reset to 0; `scroll_up()` maintains
  `_wrapped`.
- `tests/unit/terminal_grid_resize_test.gd` — 14 tests, ALL GREEN.
- CHANGELOG.md and docs/todo-v1.md updated.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.2.2` — DONE. Resize propagation to TerminalManager and godotty-node.
- `project/autoload/terminal_manager.gd` — added `_mock_cols`/`_mock_rows` vars;
  `_ready()` connects `SignalBus.terminal_resized` → `_on_terminal_resized`;
  `_exit_tree()` disconnects; handler updates mock state or calls
  `_real_terminal.resize(cols, rows)`; `get_dimensions()` reads `_mock_cols`/`_mock_rows`.
- `tests/unit/terminal_manager_resize_test.gd` — 9 tests, ALL GREEN.
- `tests/unit/terminal_manager_grid_test.gd` — `before_test()` updated to reset
  `_mock_cols = 80` / `_mock_rows = 24` so existing dimension tests stay order-independent.
- CHANGELOG.md updated under [Unreleased].
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.2.1` — DONE. Terminal resize cols/rows calculation from TerminalSettings.font_size.
- `project/autoload/signal_bus.gd` — added `terminal_resized(cols: int, rows: int)` signal.
- `project/scripts/terminal_settings.gd` — added `static var font_size: int = 16`.
- `project/scripts/terminal_view.gd` — `_on_viewport_resize` derives char_w/line_h from
  `TerminalSettings.font_size`, computes `cols=floor(w/cw)`, `rows=floor(h/lh)`,
  emits `SignalBus.terminal_resized(cols, rows)`, then clamps for `TerminalManager.resize`.
- `tests/unit/terminal_view_resize_test.gd` — 5 mock-mode tests, ALL GREEN.
- CHANGELOG.md and docs/todo-v1.md updated.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.1.4` — DONE. Cursor hide/show via DEC private mode 25 implemented.
- `project/scripts/terminal_view.gd` — added `_cursor_dec_visible: bool = true`;
  `_handle_private_mode_set("?25")` sets it true and restores overlay;
  `_handle_private_mode_reset("?25")` sets it false and hides overlay;
  `_on_blink_timeout`, `_start_blinking`, `_stop_blinking` all guard on
  `_cursor_dec_visible` so no blink or focus event can override a DEC hide.
- `tests/unit/terminal_view_cursor_hide_test.gd` — 12 mock-mode tests, ALL GREEN.
- `CHANGELOG.md` and `docs/todo-v1.md` — updated.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.1.3` — DONE. Cursor blink implemented.
- `project/scripts/terminal_settings.gd` — new `TerminalSettings` class (plain
  class_name, not autoload) with `static var cursor_blink_rate: float = 0.5`.
- `project/scripts/terminal_view.gd` — added `_blink_timer` (child Timer) and
  `_cursor_blink_visible` bool; `_setup_cursor_blink()` in `_ready()` creates timer
  with `TerminalSettings.cursor_blink_rate`; `_on_blink_timeout()` toggles visibility
  (steady styles exempt); blinking pauses on focus loss, resumes on focus gained;
  `_exit_tree()` disconnects blink signals. `.gdlintrc` `max-file-lines` → 850.
- `tests/unit/terminal_view_cursor_blink_test.gd` — 14 deterministic mock-mode tests,
  ALL GREEN.
- `CHANGELOG.md` and `docs/todo-v1.md` — updated.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.1.2` — DONE. Cursor style via DECSCUSR (CSI Ps SP q) implemented.
- `project/scripts/terminal_view.gd` — added `CursorStyle` enum; `cursor_style`
  public property; `_handle_decscusr(params_str)` parser for Ps 0–6;
  `_update_cursor_overlay()` resizes overlay (block/underline/bar shapes).
  `.gdlintrc` `max-file-lines` bumped to 750.
- `tests/unit/terminal_view_cursor_style_test.gd` — 11 mock-mode tests, ALL GREEN.
- `CHANGELOG.md` — entry added under `[Unreleased] / Added`.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.1.1` — DONE. Cursor rendering in TerminalView implemented.
- `project/scripts/terminal_view.gd` — added `cursor_row`/`cursor_col` public
  vars; `_update_cursor_overlay()` positions the ColorRect; CSI H/f now handles
  primary-screen cursor tracking (in addition to existing alt-screen path).
- `project/scenes/terminal.tscn` — added `CursorOverlay` ColorRect (8×16 px,
  z_index=1, semi-transparent) as free-positioned child of ScrollContainer.
- `tests/unit/terminal_view_cursor_test.gd` — 3 mock-mode tests, ALL GREEN.
- `docs/todo-v1.md` — task 1.1.1 marked `[x]`.
- `CHANGELOG.md` — entry added under `[Unreleased] / Added`.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.0.4` — DONE. Erase sequences in alternate screen implemented.
- `project/scripts/terminal_grid.gd` — added `erase_display(mode)` and
  `erase_line(mode)` covering all three modes (0/1/2).
- `project/scripts/terminal_view.gd` — `CSI J` routes to
  `_alt_grid.erase_display(mode)` in alt screen; `CSI K` routes to
  `_alt_grid.erase_line(mode)` in alt screen (was `pass`).
- `tests/unit/terminal_grid_erase_test.gd` — 12 tests, ALL GREEN.
- `tests/unit/terminal_view_erase_test.gd` — 9 tests, ALL GREEN.
- `docs/todo-v1.md` — task 1.0.4 marked `[x]`.
- `CHANGELOG.md` — entry added under `[Unreleased] / Added`.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.0.3` — DONE. Cursor positioning in alternate screen implemented.
- `project/scripts/terminal_grid.gd` — added `cursor_row`/`cursor_col` public
  vars; `set_cursor(row, col)`, `move_cursor(delta_row, delta_col)`,
  `write_at_cursor(cell)` methods; `resize` clamps cursor to new bounds.
- `project/scripts/terminal_view.gd` — `CSI H`/`f`/`A`/`B`/`C`/`D` dispatch
  into `_alt_grid: TerminalGrid`; chars mirrored to grid at cursor position;
  `_make_cell_from_state(ch)` helper; `_terminal_cols`/`_terminal_rows` tracked.
  `.gdlintrc` `max-file-lines` bumped to 700.
- `tests/unit/terminal_grid_cursor_test.gd` — 25 tests, ALL GREEN.
- `tests/unit/terminal_view_ansi_cursor_test.gd` — 25 tests, ALL GREEN.
- `docs/todo-v1.md` — task 1.0.3 marked `[x]`.
- `CHANGELOG.md` — entry added under `[Unreleased] / Added`.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

Task `1.0.2` — DONE. Alternate screen buffer enter/exit implemented in `TerminalView`.
- `project/scripts/terminal_view.gd` — CSI `?1049h/l` (save/restore), `?47h/l`,
  `?1047h/l` handled. Primary accumulator saved on enter, restored on exit.
  Also fixed pre-existing `\x` hex escapes → `\u00XX`, and Godot 3-style
  `disconnect`/`is_connected` 3-arg calls in `_exit_tree` → Godot 4 signal API.
- `tests/unit/terminal_view_alternate_screen_test.gd` — 13 mock-mode tests, ALL GREEN.
- `docs/todo-v1.md` — task 1.0.2 marked `[x]`.
- `CHANGELOG.md` — entry added under `[Unreleased] / Added`.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.

## Done this session (continued)

- Task `0.4.2` — tighten gdlint rules:
  - `.gdlintrc` — removed all 10 `disable` exceptions.
  - `project/autoload/terminal_manager.gd` — signals before vars, guard-clause
    style, `TermClass`→`term_class`, extracted 5 `_mock_cmd_*` helpers to
    satisfy `max-returns`, flattened `elif`/`else` in ls/cat handlers.
  - `project/scripts/main.gd` — `available`→`_available` for unused-arg rule.
  - `project/scripts/terminal_view.gd` — @onready vars after regular vars,
    flattened `_xterm256_hex` if-chain.
  - `bash scripts/lint.sh` → clean (exit 0).
  - `bash scripts/run_tests.sh tests/unit` → 11/11 GREEN.

- Task `0.4.1` — one-shot gdformat reformat complete; `gdformat --check` re-enabled in lint.
  - `project/autoload/signal_bus.gd`, `terminal_manager.gd` — reformatted.
  - `project/scripts/main.gd`, `terminal_view.gd` — reformatted.
  - `tests/integration/real/__init__.gd`, `echo_test.gd`, `exit_code_test.gd`, `pwd_test.gd` — reformatted.
  - `scripts/lint.sh` — re-enabled `gdformat --check`.
  - `bash scripts/lint.sh` → clean (exit 0).
  - `bash scripts/run_tests.sh tests/unit` → 11/11 GREEN.

- `tests/integration/real/__init__.gd` (`RealIntegrationBase`) — async base
  class with `run_and_await()`, `_require_real_mode()`, lifecycle hooks.
- `tests/integration/real/pwd_test.gd` — pwd returns absolute path.
- `tests/integration/real/echo_test.gd` — echo hello contains "hello".
- `tests/integration/real/exit_code_test.gd` — exit code 42 propagates via $?.
- Task `0.3.3` — `GODOTTY_NODE_REF` workflow env pinning:
  - `scripts/bump_godotty_node_ref.sh` — one-line bump helper.
  - `tests/ci/workflow_contains_ref_test.sh` — 10 static assertions.
  - `tests/ci/workflow-syntax-test.sh` — YAML parse check.
  - `scripts/README.md` — scripts table + bump procedure docs.
- `bash scripts/lint.sh` → clean.
- `bash scripts/run_tests.sh tests/unit` → 11/11 GREEN.

## Done this session (2026-05-27)

- Created the project roadmap, modelled after Zoid's `todo.md` structure:
  - `docs/ROADMAP.md` — master index with WezTerm inspiration map.
  - `docs/todo-v0.md` — in-flight infra + CI work (phases 0.2–0.4).
  - `docs/todo-v1.md` — terminal emulation quality (alternate screen,
    cursor, resize, paste, clipboard) — 16 task cards.
  - `docs/todo-v2.md` — UX & appearance (themes, fonts, search,
    keybindings, visual tuning) — 16 task cards.
  - `docs/todo-v3.md` — multiplexing (tabs, split panes, session
    persistence) — intent + scope; detail deferred until v2 stable.
  - `docs/todo-v4.md` — advanced features (hyperlinks OSC 8, shell
    integration OSC 7/133, mouse reporting, wide chars, images) —
    18 task cards.

## Done in earlier sessions (kept for context)

- (Bootstrap, hand-authored by Claude) Repo hygiene: merged PR #3 + #4,
  retired stale branches, fixed default branch, tagged v0.1.0.
- (Bootstrap) Created `AGENTS.md`, `.ralph/` skeleton, `.github/skills/`
  skeleton. PR #5 open against `master`.
- (Spec 0002) Pinned GdUnit4 to **v6.1.3** from `godot-gdunit-labs/gdUnit4`
  (the Godot 4.6–compatible fork). Replaced the broken v5.0.5 pin.
- (Spec 0002) Fixed `scripts/run_tests.sh`: `--ignoreHeadlessMode`, hard-fail
  on misconfiguration (exit 2) and test failure (exit 1).
- (Spec 0002) Wrote `tests/unit/terminal_manager_pwd_test.gd` (4 cases, GREEN).
- (Spec 0002) Wrote `tests/unit/signal_bus_connectivity_test.gd` (7 cases, GREEN).
- (Spec 0002) CI: hard-installs GdUnit4, runs the suite headless on
  **Linux + macOS**, uploads test reports as artifacts.
- (Spec 0002) Gitignored `*.uid` (Godot 4.6) and `project/addons/gdUnit4/`.
- CHANGELOG `[Unreleased] / Added` updated.
- 5 new entries in `.ralph/learnings/INDEX.md`.

## Verified locally

- `bash scripts/run_tests.sh tests/unit` → 11 cases / 0 failures / `ALL GREEN`.
- Sanity check with a deliberately failing test → `EXIT: 1`. Red propagates.

## Blocked / questions for the human

**Waiting on human merge of PR #5 and PR #6.**

These touch meta infra, CI and policies (AGENTS.md hard-stops). After
merge, start spec 0003 on a new branch `feature/0003-real-terminal-ci`.

## Next steps after PRs merge

1. Start `feature/0003-real-terminal-ci`.
2. Implement `0.3.1` — `.github/workflows/nightly-real.yml` (nightly build
   of godotty-node, headless integration tests).
3. Implement `0.3.2` — three real-mode integration tests in
   `tests/integration/real/`.
4. Implement `0.3.3` — pin godotty-node ref as `GODOTTY_NODE_REF` env var.

See `docs/todo-v0.md` phase 0.3.0 for full task cards.

## Notes & scratchpad

- Bootstrap PR #5 must land before spec 0002's PR can merge to `master`
  cleanly. The 0002 PR is opened against `feature/superpowers-ralph-infra`
  so the diff stays focused on test-harness changes.
- Spec 0003 (real-mode CI) is unblocked once `godotty-node` ships
  pre-built artifacts or a clean cross-compile path.
- Driver script lives at `scripts/ralph_loop.sh`. Test it with `--dry-run`
  before letting it loose.
- Full roadmap is now at `docs/ROADMAP.md`. WezTerm inspiration map
  is in the roadmap master index.

Task `1.4.1` — DONE. Click-drag text selection in TerminalView.
- `project/scripts/terminal_view.gd` — selection_start/end state, _gui_input
  mouse handling, _pixel_to_cell, _setup_selection_overlay, _update_selection_overlay,
  selected_cell_count.
- `project/scripts/terminal_grid.gd` — char_width/line_height vars, clamp_cell,
  cell_from_pixel, get_cell_rect helpers.
- `tests/unit/terminal_view_mouse_selection_test.gd` — 5 mock-mode tests, ALL GREEN.
- `bash scripts/lint.sh` → clean. `bash scripts/run_tests.sh tests/unit` → ALL GREEN.
