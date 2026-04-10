# Claude Code Theming: Hit the Native Binary Wall

**Date**: 2026-04-10 00:00
**Type**: Incident / Lesson
**Component**: claude-code/theme.sh, claude-code/vietnamese.sh
**Status**: Resolved (partial — patches work for npm only)
**Mode**: [ship] — AI did the patch work, I directed and debugged

## What Happened

Spent a full session trying to apply the sage color theme to Claude Code — dark/light palette separation, Vietnamese IME fix, and proper system appearance detection. Everything looked correct at the JavaScript level, but nothing took effect at runtime. Root cause: the `claude` binary on my machine is a native Mach-O compiled by Bun, not the npm package. The npm package still exists on disk but is never invoked. All sed patches were hitting dead code.

## Why It Matters

This is the kind of failure that wastes hours because the feedback loop is silent — no errors, no indication the wrong binary is running, the patches apply cleanly to the npm JS and the diff looks right. The patches in `theme.sh` and `vietnamese.sh` are valid and may be useful if someone runs the npm version, but they have zero effect on the native installer path.

## Key Decisions

- Kept `theme.sh` and `vietnamese.sh` in the repo rather than deleting — they're documented as npm-only and may be reusable if Claude Code ever exposes a plugin/theme API
- Reverted to the working single-palette `theme.sh` (sage light bg + near-black text) rather than leaving a broken dark/light split in the codebase
- Did not pursue binary patching — Mach-O reverse engineering for a cosmetic theme is not worth it

## Technical Details

**Binary resolution chain:**
- `claude` resolves to `~/.local/bin/claude` (native Mach-O, Bun-compiled)
- Installed via `claude install`, which prepends `~/.local/bin` to PATH through `~/.local/bin/env`
- npm package at `~/.npm-global/bin/claude` exists but is shadowed

**Detection that confirmed the issue:**
```bash
# Debug file in patched JS — never created
/tmp/cc-theme-debug.txt  # absent after running claude

# Confirmed native binary
file ~/.local/bin/claude
# → Mach-O 64-bit executable arm64
```

**Dark/light detection work (now orphaned but documented):**
- Claude Code reads `process.env.COLORFGBG` for dark/light detection; Ghostty does not set this
- Default theme is hardcoded `"dark"` in the CLI; only `"auto"` triggers COLORFGBG check
- `theme` config lives in `~/.claude/.config.json`, not `settings.json` (`theme` is not a valid settings.json field)
- Patched `GT_()` to return `"auto"` and `DT_()` to fallback to `defaults read -g AppleInterfaceStyle` — correct approach, wrong binary

**Vietnamese IME root cause (bonus discovery):**
- Original npm patch searched for escaped `\x7f` string literal
- Actual CLI uses raw DEL byte (0x7f), not the escape sequence — pattern never matched until fixed

## Root Cause

Claude Code migrated to a native installer. The npm package is a deprecated artifact. There is no indication in the install flow that you have the native binary, and the npm package silently remains on disk. Any JS-level patching strategy is now obsolete.

## Lessons Learned

1. **Verify the actual running binary before patching.** `which claude` and `file $(which claude)` take 2 seconds and would have saved hours.
2. **Silent patch failures are the worst.** When a patch applies cleanly but has no effect, suspect you're patching the wrong artifact. Check that the patched file is actually in the execution path.
3. **Closed-source native binaries end the patching game.** For cosmetic customization, look for official config APIs, environment variables, or theme support before reaching for sed.
4. **COLORFGBG is the canonical dark/light signal for terminal apps** — worth knowing when building terminal UIs. Ghostty omits it; many terminals do.

## Approach

The session ran sequentially: Vietnamese fix → theme colors → dark/light split → investigate why dark/light failed. Each step appeared to work until it was tested. The fatal discovery came only after adding a debug file write to the patched JS and checking if it was created post-run — a simple filesystem probe that should have been step one.

Reusable pattern: **when patching a CLI tool, write a canary side-effect (temp file, log line) into the patch immediately — if the canary doesn't fire, you're patching the wrong binary before wasting time on logic.**

## Next Steps

- Watch for Claude Code to expose an official theme/plugin API — the color substitution logic in `theme.sh` is ready to port
- If Ghostty adds `COLORFGBG` support, the dark/light detection patches in this session are ready to reapply to the npm version
- Consider filing a feature request upstream for a `CLAUDE_THEME` env var or config-driven color overrides
