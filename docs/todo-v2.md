# Godotty Todo — v2.x: UX & Appearance

> Back to index: [`docs/ROADMAP.md`](ROADMAP.md)

The 2.x series adds the UX polish that transforms a working terminal into a
*pleasant* terminal: multiple color schemes, font configuration, in-terminal
search, and fully rebindable keyboard shortcuts. WezTerm and Kitty popularized
all of these as first-class features.

**Prerequisite:** Phase 1.4.0 (clipboard) merged. Phases 2.0–2.4 are
largely independent of each other and can be parallelized once the
`TerminalSettings` Resource introduced in 2.0.0 stabilizes.

---

## Phase 2.0.0 — Color Scheme System

**Goal:** ship a `TerminalTheme` Resource that encodes a 16-color palette +
fg/bg/cursor/selection colors, bundle 8+ named themes, and let users switch
at runtime.

**Prerequisite:** Phase 1.4.0.

- [x] `2.0.1` `TerminalTheme` Resource definition.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/resources/terminal_theme.gd`,
    `project/resources/themes/`,
    `tests/unit/terminal_theme_test.gd`.
  - Work: a `Resource` subclass with exports:
    `color_background`, `color_foreground`, `color_cursor`,
    `color_selection_bg`, `color_selection_fg`, and `palette: Array[Color]`
    (16 entries: ANSI 0–15). Validate palette size on `_ready`.
    Load/save via `ResourceSaver` / `ResourceLoader`.
  - Tests: default palette has 16 entries; resource round-trips to `.tres`.

- [x] `2.0.2` Wire `TerminalTheme` into `TerminalView` rendering.
  - Complexity: Low-Medium. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: replace the hard-coded `PALETTE` constant in `terminal_view.gd`
    with a lookup into the active `TerminalTheme`. `TerminalManager` exposes
    `current_theme: TerminalTheme` (settable at runtime). Changing it
    triggers a full re-render of the visible viewport.
  - Tests: swap theme at runtime; rendered colors change.

- [x] `2.0.3` Bundle built-in themes.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/resources/themes/`.
  - Work: create `.tres` files for: **Solarized Dark** (current palette,
    migrate to resource), **Solarized Light**, **Dracula**, **Tokyo Night**,
    **Gruvbox Dark**, **Catppuccin Mocha**, **Nord**, **One Dark**.
    Each `.tres` file is self-contained and human-readable.
  - Tests: each theme resource loads without errors; palette has 16 entries.

- [x] `2.0.4` Theme picker UI.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scenes/terminal.tscn`,
    `project/scripts/terminal_view.gd`.
  - Work: a `MenuButton` in the terminal's title bar (or a
    `PopupMenu` on a settings icon) lists all bundled themes by name.
    Selecting one calls `TerminalManager.set_theme(theme)`.
  - Tests: theme picker lists 8+ themes; selecting Dracula applies dark bg.

**Release gate for 2.0.0:** theme picker in the demo app lets users switch
between all 8 themes; colors update immediately; selected theme persists
across scene reloads.

---

## Phase 2.1.0 — Font Configuration

**Goal:** let users choose the terminal font family, size, and line height
via `TerminalSettings`. Nerd Font / powerline glyphs must render without
blank boxes.

**Prerequisite:** Phase 2.0.0 (`TerminalSettings` Resource pattern established).

- [x] `2.1.1` `TerminalSettings` Resource.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/resources/terminal_settings.gd`,
    `tests/unit/terminal_settings_test.gd`.
  - Work: a `Resource` subclass with exports: `font: FontFile` (null →
    use engine default monospace), `font_size: int` (default 14),
    `line_height_scale: float` (default 1.2), `theme: TerminalTheme`,
    `cursor_blink_rate: float`. Validate ranges on `_validate_property`.
  - Tests: default values correct; resource round-trips to `.tres`.

- [x] `2.1.2` Apply `TerminalSettings` font to `OutputDisplay`.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: on settings change, set `output_display.add_theme_font_override`
    and `add_theme_font_size_override`. Recompute `char_width` /
    `line_height` for cursor positioning and resize calculations.
  - Tests: change font_size; char_width and cursor position update.

- [x] `2.1.3` Bundle a Nerd Font for demo use.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/resources/fonts/`.
  - Work: include a single Nerd Fonts–patched monospace font (e.g.,
    JetBrains Mono Nerd Font, OFL license) so the demo app renders
    powerline/file-type icons out of the box. Document attribution
    in `LICENSE` or a `NOTICE` file.
  - Tests: font file loads; powerline separator U+E0B0 renders visible.

- [x] `2.1.4` Font settings panel in demo UI.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scenes/terminal.tscn`.
  - Work: a simple settings panel (SpinBox for size, OptionButton for font
    family from a predefined list of bundled fonts) that updates
    `TerminalSettings` at runtime.
  - Tests: increase font_size; `OutputDisplay` font size updates.

**Release gate for 2.1.0:** change font family and size in the settings
panel; terminal reflows correctly; Nerd Font icons visible with the bundled
font.

---

## Phase 2.2.0 — Search in Scrollback

**Goal:** Ctrl+Shift+F opens a search bar; typing highlights all matches in
the scrollback; Enter / Shift+Enter navigates between them.

**Prerequisite:** Phase 1.4.0 (selection / highlight infrastructure).

- [ ] `2.2.1` Search bar overlay scene and show/hide logic.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scenes/search_bar.tscn`,
    `project/scripts/search_bar.gd`,
    `project/scenes/terminal.tscn`.
  - Work: a `PanelContainer` with a `LineEdit` (query) + match-count label +
    prev/next buttons, anchored to the top-right of `TerminalView`. Hidden by
    default. Ctrl+Shift+F shows it with focus on the `LineEdit`; Escape hides
    it and clears highlights.
  - Tests: Ctrl+Shift+F shows overlay; Escape hides it.

- [ ] `2.2.2` Scrollback search logic.
  - Complexity: Medium. Suggested model: flagship model.
  - Owned paths: `project/scripts/terminal_view.gd`,
    `project/scripts/search_bar.gd`.
  - Work: on query change (text_changed), search the scrollback line array
    for all occurrences (plain string, case-insensitive default; optional
    regex toggle). Store match positions as `Array[Vector2i]` (line, col).
    Inject `[bgcolor=#...][/bgcolor]` BBCode around matches when re-rendering
    matching lines. Display match count.
  - Tests: 3 occurrences of "error" in scrollback; search returns 3 matches.

- [ ] `2.2.3` Navigate matches.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/search_bar.gd`,
    `project/scripts/terminal_view.gd`.
  - Work: Enter / next-button scrolls `ScrollContainer` to the next match
    line and selects it (wraps at end). Shift+Enter / prev-button goes
    backwards. Current match highlighted in a distinct accent color.
  - Tests: navigate forward past end wraps to first match.

**Release gate for 2.2.0:** search for "error" in a scrollback with
several matches; matches highlight; Enter cycles through them; Escape
restores normal view.

---

## Phase 2.3.0 — Configurable Keybindings

**Goal:** all terminal actions have a default key chord that users can
rebind via a `TerminalKeymap` Resource, persisted to `user://`.

**Prerequisite:** Phase 2.1.0 (`TerminalSettings` pattern).

- [ ] `2.3.1` `TerminalKeymap` Resource.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/resources/terminal_keymap.gd`,
    `tests/unit/terminal_keymap_test.gd`.
  - Work: a `Resource` with `bindings: Dictionary` mapping action name →
    `InputEventKey`. Built-in actions: `copy`, `paste`, `clear`,
    `search`, `scroll_page_up`, `scroll_page_down`, `new_tab`,
    `close_tab`, `split_right`, `split_down`, `interrupt` (Ctrl+C),
    `eof` (Ctrl+D). Provide factory method `TerminalKeymap.default()`.
  - Tests: default bindings present; rebind copy action; fires on new key.

- [ ] `2.3.2` Consume `TerminalKeymap` in `TerminalView._input`.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: replace the hard-coded `match event.keycode` block in `_input`
    with a loop over `TerminalManager.keymap.bindings`. Each matching
    binding calls a private `_execute_action(action_name)` method.
  - Tests: rebind `clear` from Ctrl+L to Ctrl+K; Ctrl+K clears.

- [ ] `2.3.3` Keybinding editor panel.
  - Complexity: Medium. Suggested model: standard coding model.
  - Owned paths: `project/scenes/settings_dialog.tscn`,
    `project/scripts/settings_dialog.gd`.
  - Work: a scrollable list of (action name, current key chord, [Edit]
    button) rows. Clicking Edit captures the next keypress and updates
    the binding. Save button writes the keymap to `user://keymap.tres`.
  - Tests: click Edit; press F5; action now bound to F5.

**Release gate for 2.3.0:** rebind `copy` to a custom key via the UI;
the change survives a game restart; the default keymap loads when
`user://keymap.tres` does not exist.

---

## Phase 2.4.0 — Visual Tuning

**Goal:** background transparency, configurable padding / line spacing,
cursor blink rate, and a visual bell — the finishing touches that make
the terminal feel polished.

**Prerequisite:** Phase 2.1.0 (`TerminalSettings`).

- [ ] `2.4.1` Background transparency.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scenes/terminal.tscn`,
    `project/scripts/terminal_view.gd`.
  - Work: `TerminalSettings.background_opacity: float` (0.0–1.0, default
    1.0). Apply to the terminal panel's `self_modulate.a`. Requires the
    Godot window to have `transparent = true` and `ProjectSettings
    rendering/environment/defaults/default_clear_color` set with
    alpha < 1.0.
  - Tests: opacity 0.5 sets panel alpha; opacity 1.0 fully opaque.

- [ ] `2.4.2` Configurable padding.
  - Complexity: Very Low. Suggested model: standard coding model.
  - Owned paths: `project/scenes/terminal.tscn`,
    `project/scripts/terminal_view.gd`.
  - Work: `TerminalSettings.padding: Vector2i` (default (4, 4) px).
    Apply as `Constants` overrides on the `VBoxContainer` theme or as a
    `MarginContainer` wrapping the output display.
  - Tests: padding (10, 10) adds 10 px inset on each side.

- [ ] `2.4.3` Visual bell.
  - Complexity: Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: on `\x07` (BEL), briefly flash the terminal background by
    modulating `self_modulate` to a configurable `bell_color`
    (default white) for ~150 ms via a `Tween`. Optionally also call
    `DisplayServer.beep()` (audio bell, gated by `TerminalSettings
    .audio_bell: bool`, default false).
  - Tests: BEL character triggers modulate tween; returns to normal.

- [ ] `2.4.4` Scrollback buffer size setting.
  - Complexity: Very Low. Suggested model: standard coding model.
  - Owned paths: `project/scripts/terminal_view.gd`.
  - Work: expose `TerminalSettings.scrollback_lines: int` (default 1000,
    max 100000). Replace the hard-coded `MAX_LINES` constant in
    `terminal_view.gd` with the settings value. Enforce at write time.
  - Tests: set scrollback to 5; write 10 lines; only last 5 retained.

**Release gate for 2.4.0:** background opacity slider in settings demo;
visual bell fires on `echo -e '\a'`; scrollback limit respected.
