# Sage

A color theme for Zed and Ghostty.

Gray + green. Realistic but hopeful — life isn't black and white, and the future changes based on what you do.

## Palette

- **Gray** — neutral base, no absolutes
- **Sage green** — two tiers:
  - Muted sage (`#7D9E8A` dark / `#8C9E97` light) — UI chrome: borders, selection, active line
  - Bright green (`#4ADE80` dark / `#10A868` light) — syntax keywords, success, git added

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

---

Both themes follow your system light/dark mode automatically.
