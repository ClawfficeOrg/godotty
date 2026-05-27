# Bundled Fonts

## JetBrains Mono Nerd Font — Regular

**File:** `JetBrainsMonoNerdFont-Regular.ttf`
**Version:** 3.4.0 (from Nerd Fonts release 2025-04-24)
**Source:** <https://github.com/ryanoasis/nerd-fonts/releases/tag/v3.4.0>
**License:** SIL Open Font License 1.1 — see `NOTICE` at the repository root.

### Purpose

This font is bundled so the godotty demo renders Powerline / file-type icons
(e.g. U+E0B0 `` and friends) out of the box without requiring the end user
to install a Nerd Font separately.

### Usage in Godot

```gdscript
var nerd_font: FontFile = load("res://resources/fonts/JetBrainsMonoNerdFont-Regular.ttf")
TerminalSettings.font = nerd_font
```

### Attribution

**JetBrains Mono** is designed by Philipp Nurullin and Konstantin Bulenkov at
JetBrains (https://www.jetbrains.com/lp/mono/).

**Nerd Fonts** patching by Ryan L McIntyre and the Nerd Fonts contributors
(https://nerdfonts.com / https://github.com/ryanoasis/nerd-fonts).

Both the upstream font and the Nerd Fonts patch are released under the
SIL Open Font License 1.1.  Full attribution is in the repo-root `NOTICE` file.
