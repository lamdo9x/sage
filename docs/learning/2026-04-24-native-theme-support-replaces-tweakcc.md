# Claude Code Theming: Native Theme API Discovered — tweakcc Retired

**Date**: 2026-04-24
**Type**: Migration / Decision
**Component**: claude-code/apply-theme.js, ~/.claude/themes/sage.json
**Status**: Completed
**Mode**: [ship] — AI drove discovery and implementation, I directed and reviewed

## What Happened

The tweakcc blocker from the previous session (v2.1.118 `✗ Themes`) turned out to be irrelevant. Claude Code v2.1.118+ ships native theme support: drop a JSON file in `~/.claude/themes/` and reference it as `"theme": "custom:sage"` in `~/.claude.json`. No binary patching required.

Migrated the full Sage color palette to `~/.claude/themes/sage.json`. Replaced `apply-tweakcc.js` with a new `apply-theme.js` that simply copies the theme file to the right location — no `sudo`, no `node-lief`, no version caching needed. Updated the `~/.zshrc` `claude()` wrapper to call `apply-theme.js` instead.

Also fixed a text color regression: the theme had a global `"text"` override that forced light text on the light Sage base, breaking readability. Removing it let the default text color inherit correctly.

## Why It Matters

This closes a two-session saga. The approach went: sed patches on cli.js → JS bundle disappeared → tweakcc binary patching → tweakcc broke on v2.1.118 → discovered Anthropic shipped what we actually needed all along. The final solution is simpler than anything attempted before: a JSON file copy.

The lesson is that investing in fragile workarounds while the underlying tool is actively evolving creates compounding technical debt. Checking for official APIs periodically would have saved significant time.

## Key Decisions

- **Retired tweakcc entirely**: the native API is officially supported and requires zero maintenance overhead. No reason to keep a binary patching dependency.
- **Simplified apply-theme.js to a file copy**: previous apply scripts accumulated complexity (version caching, retry logic, sudo invocation). None of that is needed now.
- **Removed global `"text"` color override**: it was a defensive patch from the sed-patching era, compensating for colors that were no longer being overridden. With the full palette declared explicitly, it caused a regression.
- **`"theme": "custom:sage"` vs `"theme": "sage"`**: the `custom:` prefix is required for user-defined themes in `~/.claude/themes/`. Using just `"sage"` silently falls back to the default.

## Technical Details

**Theme file location** (v2.1.118+):
```
~/.claude/themes/sage.json     # color palette
~/.claude.json                 # must have: "theme": "custom:sage"
```

**What apply-theme.js does now:**
```js
fs.copyFileSync(src, dest);  // that's essentially it
```

Previous apply-tweakcc.js: ~80 lines with version caching, sudo invocation, stdout parsing, retry logic.
New apply-theme.js: ~15 lines.

**The text color bug**: `"text": "#F5F0E8"` (near-white) was left from an era when the dark theme base needed explicit light text. With native theming and a light Sage base, the same override made body text invisible on the light background. Removed.

## Root Cause (of the long path here)

Anthropic's theme roadmap was not public. The native themes directory existed in v2.1.118 but wasn't announced. The assumption was "binary patching is the only way" — nobody checked the filesystem for a new support path until the tweakcc blocker forced a deeper investigation.

## Lessons Learned

1. **When a third-party workaround breaks, check if the official tool added native support first.** That's the most likely explanation when a tool version change coincides with a workaround failure.
2. **Complexity in automation scripts is often a smell that you're fighting the tool.** The version caching and retry logic in apply-tweakcc.js were necessary only because patching was fundamentally the wrong layer. Simple tasks should have simple scripts.
3. **The `custom:` prefix for user themes is a non-obvious gotcha.** Without it, Claude Code silently ignores the custom file and uses the default theme. Worth documenting in the theme file itself.
4. **Keep defensive patches scoped.** The global `"text"` override was added to fix a specific dark-base problem and should have been removed when the base changed. Global overrides drift out of context and become invisible bugs.

## Approach

- Started from the tweakcc blocker — instead of fixing tweakcc, questioned whether the dependency was still necessary.
- Checked the Claude Code data directory for new files/directories added in recent versions.
- Found `~/.claude/themes/` and confirmed the JSON format by inspection.
- Replaced the entire apply pipeline before debugging tweakcc — correct prioritization.
- Text color bug was discovered by running the theme and visually inspecting output.

Reusable pattern: **when a workaround breaks after a tool update, check the tool's own directories for new official extension points before debugging the workaround.**

## Next Steps

- Monitor `~/.claude/themes/` JSON schema across CC updates — native APIs can still break on minor version changes, but the breakage surface is much smaller.
- If Anthropic documents the theme schema officially, validate `sage.json` against it.
- `apply-theme.js` can probably be inlined into the `claude()` wrapper directly — it's now trivial enough that a separate file may be unnecessary.
