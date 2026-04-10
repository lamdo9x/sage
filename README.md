# Sage

A color theme for Zed, Ghostty, and Claude Code.

Gray + green. Realistic but hopeful — life isn't black and white, and the future changes based on what you do.

## Palette

- **Gray** — neutral base, no absolutes
- **Sage green** — three tiers:
  - Deep green (`#183826` dark / `#BDD0C2` light) — selection background, highlights
  - Muted sage (`#7D9E8A` dark / `#8C9E97` light) — UI chrome: borders, active line, accents
  - Bright green (`#4ADE80` dark / `#10A868` light) — syntax keywords, cursor, success, git added

## Install

### Zed

```bash
cd zed && bash install.sh
```

Copies `sage.json` to `~/.config/zed/themes/` and updates your Zed settings automatically.

### Ghostty

```bash
cd ghosty && bash install.sh
```

Copies `sage-light` and `sage-dark` to `~/.config/ghostty/themes/` and sets `theme = light:sage-light,dark:sage-dark` in your Ghostty config.

### Claude Code

```bash
cd claude-code && bash patch.sh
```

Patches the Claude Code CLI to render with sage green as the background color.

---

Zed and Ghostty themes follow your system light/dark mode automatically.
