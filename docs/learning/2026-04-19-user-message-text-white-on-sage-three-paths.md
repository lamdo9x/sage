# Bug: User Message Text Rendering White on Sage Green — Three Separate Paths

**Date**: 2026-04-19 00:00
**Type**: Bug
**Component**: claude-code/theme.sh — user message text color patches
**Status**: Resolved
**Mode**: [ship]

## What Happened

User message text was rendering white on the sage green chat background after the theme patch was applied. The existing patches (a, b, c) handled rainbow/highlight text segments but missed the common case: plain submitted user messages. Three new sed patches (d, e, f) were added to force `rgb(30,30,30)` across all remaining rendering paths.

## Why It Matters

White-on-green is unreadable. This was the dominant visual regression in the themed UI — every user message looked broken. The fix is non-obvious because the root cause is split across three distinct code paths in a minified binary.

## Root Cause

The minified Claude Code CLI renders user message text through multiple branches depending on message state. Three were unpatched:

1. **History path** (`isCurrent:!1`) — non-selected (past) user messages used `color:"text"`, which resolves to white in dark mode.
2. **Current message branch** (`color:t?"suggestion":void 0`) — the conditional either applies a muted "suggestion" color (low contrast on sage) or `void 0` (no color, falls back to white). Both are unacceptable on a light background.
3. **`vq7` fallback path** — when user text has no rainbow/highlight segments (the common case for most submitted messages), it falls through to `color:"text"` in the `vq7` component's break-case. This is the path that fires for almost every message.

A compounding factor: Ghosty terminal's minimum-contrast enforcement auto-brightened any low-contrast text to white, masking what the actual color value was and making it look like a theme failure rather than a contrast correction.

## What We Tried

The existing patches (a–c) targeted `color:"text"` in rainbow/plain segment rendering. They were correct but incomplete — they only covered the highlighted token paths, not the plain message render path or the current-message branch.

## Technical Details

Three patches added to `claude-code/theme.sh`:

```bash
# d. Non-selected (history) user message display
sudo sed -i '' 's/color:"text",isCurrent:!1/color:"rgb(30,30,30)",isCurrent:!1/g' "$CLI"

# e. Current user message — both branches (suggestion + void 0) render badly on sage
sudo sed -i '' 's/color:t?"suggestion":void 0,isCurrent/color:"rgb(30,30,30)",isCurrent/g' "$CLI"

# f. vq7 fallback — most submitted messages hit this path
sudo sed -i '' 's|color:"text"},_);break q|color:"rgb(30,30,30)"},_);break q|' "$CLI"
```

Patch f uses `|` as delimiter because the pattern contains `/` characters that would break the standard `s/.../.../` syntax.

## Approach

- Identified the symptom (white text on sage) and ruled out the obvious: existing patches were present but incomplete.
- Searched the minified binary for all occurrences of `color:"text"` and `color:` near user-message-related identifiers (`isCurrent`, `suggestion`, `vq7`).
- Mapped three distinct rendering paths rather than assuming a single fix would cover all cases.
- Ghosty's auto-contrast behavior was a diagnostic red herring — once recognized, it confirmed the patches were working (Ghosty had nothing left to correct).
- Reusable pattern: when theming a minified binary, assume the same logical concept (e.g., "user message color") is scattered across multiple code paths. Audit all before patching.

## Lessons Learned

- Minified UIs often have parallel rendering branches for the same visual element (selected vs. unselected, highlighted vs. plain). One `sed` patch rarely covers all of them.
- Terminal emulators with minimum-contrast settings can silently override your theme colors, making it look like the patch failed when it actually succeeded — Ghosty was correcting low-contrast values to white, not ignoring the patch.
- When `void 0` appears as a color value in a conditional, it means "inherit from context" — on a dark-mode-designed component mounted on a light background, that context is going to be wrong.
- Use `|` as the `sed` delimiter when patterns contain forward slashes.

## Next Steps

- Watch for breakage after npm updates — the zsh `claude()` wrapper already auto-reapplies the theme, but new Claude Code versions may rename minified identifiers (e.g., `vq7` becomes something else), silently breaking patches without error.
- Consider a validation step in `theme.sh` that confirms at least one patch per section actually matched something in `$CLI`.
