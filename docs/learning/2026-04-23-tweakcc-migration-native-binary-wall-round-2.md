# Claude Code Theming: Native Binary Wall Round 2 — Migration to tweakcc

**Date**: 2026-04-23
**Type**: Incident / Migration
**Component**: claude-code/theme.sh, claude-code/vietnamese.js → claude-code/apply-tweakcc.js, claude-code/sage-tweakcc.json
**Status**: Blocked (tweakcc v2.1.118 patch patterns failing)
**Mode**: [ship] — AI built the migration, I directed and reviewed

## What Happened

Claude Code v2.1.113+ completed the native binary migration. The npm package path (`cli.js`) is now fully gone — replaced by a native Mach-O `bin/claude.exe`. Every sed-based patch in `theme.sh` and `vietnamese.js` broke silently again, this time permanently. There is no JS to patch.

Discovered `tweakcc` (Piebald-AI), a third-party tool that patches the native Claude Code binary using `node-lief` — a Node.js binding to the LIEF binary analysis library. It supports color theme injection at the binary level. Migrated the full 57-color Sage theme to tweakcc's JSON format (`sage-tweakcc.json`) and built `apply-tweakcc.js` to automate sync: reads the tweakcc config, injects Sage colors, runs `sudo npx tweakcc --apply`, caches the CC version to skip unnecessary re-runs, and retries if the `✗ Themes` patch marker appears in output.

Deleted `theme.sh` and `vietnamese.js`. They are no longer useful.

Currently blocked: tweakcc v2.1.118 reports `✗ Themes` — its own patch patterns don't match the binary at this version. Waiting for a tweakcc update.

## Why It Matters

This is the second time the native binary wall has caused a full patching strategy collapse. The first time (2026-04-10) ended with "Mach-O reverse engineering is not worth it." This session found that someone else has already done that work — tweakcc exists precisely for this. The right move now is to depend on that tool rather than maintain our own binary patching.

The `.zshrc` `claude()` wrapper was also cleaned up: removed all patch invocation logic (guarded by `[ -f "$CLI" ]` check, then simplified further to remove patching entirely since it no longer applies).

## Key Decisions

- **Deleted theme.sh and vietnamese.js**: no path to cli.js means no value in keeping them. Keeping dead scripts creates confusion about what actually runs.
- **Adopted tweakcc over rolling our own**: node-lief-based patching requires maintaining binary offsets per CC version. tweakcc absorbs that maintenance cost. Depending on it is correct even though it introduces an external blocker.
- **Created apply-tweakcc.js with version caching**: avoids re-running `sudo npx tweakcc --apply` on every shell start. Caches the last-patched CC version; only re-runs when CC updates.
- **Retry on `✗ Themes`**: tweakcc sometimes requires a second apply pass. The script detects the failure marker in stdout and retries once before surfacing the error.

## Technical Details

**Why cli.js is gone:**
```
file /opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe
# → Mach-O 64-bit executable arm64
```
The npm package shell is still installed but `bin/claude.exe` is the actual entrypoint. No JS bundle ships with v2.1.113+.

**tweakcc mechanism**: uses `node-lief` to parse Mach-O sections, locate string/byte patterns corresponding to theme color tokens, and overwrite them in-place. The JSON config (`sage-tweakcc.json`) maps semantic color names to hex values — 57 color entries covering all UI surfaces.

**Current block**: tweakcc's internal pattern search for v2.1.118 returns `✗ Themes`, meaning its hardcoded offsets or byte signatures no longer match. This is a tweakcc versioning problem, not a Sage config problem. The `apply-tweakcc.js` retry logic handles transient failures but cannot fix a stale pattern — requires tweakcc upstream update.

**Files changed:**
- `claude-code/sage-tweakcc.json` — 57-color Sage theme in tweakcc format (new)
- `claude-code/apply-tweakcc.js` — auto-sync + version cache + retry logic (new)
- `claude-code/theme.sh` — deleted
- `claude-code/vietnamese.js` — deleted

## Root Cause

Anthropic completed its native binary migration. The npm JS bundle was always the unofficial patching surface — a convenient accident, never a supported API. v2.1.113 closed it. The patching approach was always fragile; the migration forced an overdue move to tooling that at least tracks binary changes intentionally.

## Lessons Learned

1. **Depending on a JS bundle for patching is renting, not owning.** It worked for ~6 months. When the bundle disappeared, everything broke. For long-lived patching strategies, find tooling designed for the binary format (LIEF, Frida, etc.) or accept that patches are version-locked.
2. **When the binary wall appears, search for existing community tooling before building your own.** tweakcc was findable. The first session (2026-04-10) decided "not worth it" — correct for DIY, but community tooling changes the calculus.
3. **Version-caching in apply scripts prevents sudo spam.** `sudo npx tweakcc --apply` on every shell open would be unusable. Caching the last-patched CC version is the minimum viable automation pattern for any patch-on-update workflow.
4. **External tool blockers are a real dependency risk.** tweakcc breaking on v2.1.118 means the theme is currently not applied. There is no fallback. This is the cost of outsourcing the hard part.

## Approach

- Confirmed the break: checked if `cli.js` existed, confirmed it does not, confirmed `bin/claude.exe` is Mach-O.
- Searched for community native-binary patching tools before attempting DIY.
- Found tweakcc, validated it supports the color token surface we need.
- Translated existing sed patch color values to tweakcc JSON format (mechanical but needed care to get all 57 tokens).
- Built automation script incrementally: basic apply → version cache → retry logic.
- Deleted deprecated scripts to avoid confusion.

Reusable pattern: **when a patch surface disappears, search "[tool name] theme patch" or "[tool name] binary patch" before spending time on DIY binary analysis — the community may have already absorbed the maintenance cost.**

## Next Steps

- Watch tweakcc releases for v2.1.118+ pattern support; re-run `apply-tweakcc.js` when it ships.
- If tweakcc lags consistently, evaluate maintaining a fork with updated patterns (low priority — one file change per CC version).
- Consider filing an issue in Piebald-AI/tweakcc for v2.1.118 support.
- If Anthropic ever ships an official theme API, `sage-tweakcc.json` colors are already catalogued and ready to port.
