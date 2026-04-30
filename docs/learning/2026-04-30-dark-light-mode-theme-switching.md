# Dark/Light Mode Auto-Detection for Sage Theme

**Date**: 2026-04-30 20:09
**Type**: Feature
**Component**: claude-code/apply-theme.js
**Mode**: [ship]
**Status**: Completed

## What Happened

Added automatic dark/light mode switching to the Sage theme system. Instead of always copying a single `sage-theme.json`, `apply-theme.js` now detects macOS appearance via `defaults read -g AppleInterfaceStyle` and copies either `sage-dark.json` or `sage-light.json` to `~/.claude/themes/sage.json` on every launch.

Two new files were split out: `sage-light.json` (extracted from the original `sage-theme.json`) and `sage-dark.json` (new dark variant with adjusted colors for dark terminal backgrounds).

The "skip if already exists" guard was also removed — theme sync now runs unconditionally on every `claude` invocation.

## Why It Matters

The Sage theme was designed for light mode. Without this, switching to macOS Dark Mode left Claude Code with a light-tuned palette on a dark background — wrong contrast, wrong feel. Now the theme follows the system.

## Key Decisions

**launchd WatchPaths was considered but rejected.** The idea was to watch `~/Library/Preferences/.GlobalPreferences.plist` and sync the theme automatically when the system appearance changes — without needing to relaunch Claude Code. But Claude Code requires a restart to reload themes anyway, so seamless in-session switching offered no real benefit.

The existing `claude()` wrapper in `.zshrc` — which already calls `apply-theme.js` before launching CC — made launchd completely unnecessary. Every `claude` invocation already re-syncs to the current system appearance. Zero new infrastructure needed.

**Dropped the existence check.** The old guard (`if (!fs.existsSync(DEST))`) prevented re-applying the theme on subsequent launches. Removing it means the theme always reflects the current mode, at the cost of one tiny file write per launch — acceptable.

## Technical Details

Mode detection:

```js
function isDarkMode() {
  try {
    const result = execSync("defaults read -g AppleInterfaceStyle 2>/dev/null", {
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"],
    }).trim();
    return result === "Dark";
  } catch {
    return false; // light mode: key doesn't exist, defaults throws
  }
}
```

`AppleInterfaceStyle` is absent (not just empty) in light mode — `defaults read` throws rather than returning an empty string. The catch block defaulting to `false` handles this correctly.

## Approach

Broke the problem into two parts: (1) detecting the system mode, (2) selecting the right source file. Implemented detection first, then restructured the copy logic around it. The wrapper-in-`.zshrc` insight eliminated a whole class of complexity (daemon, file watcher, IPC) — checking existing infrastructure before adding new pieces.

Reusable pattern: before wiring up a background watcher, check if the existing launch path already covers the sync moment.

## Lessons Learned

- `defaults read -g AppleInterfaceStyle` throws (not empty string) in light mode — always wrap in try/catch and default to the light-mode branch.
- The "skip if exists" guard on theme install is a footgun when the theme has variants. Idempotent overwrites are safer than conditional skips for config files that legitimately change.
- Check what already runs at launch before adding a daemon. The `.zshrc` wrapper provided a free sync point that made launchd unnecessary.

## Next Steps

- If Claude Code ever adds hot-reload for theme files, the launchd WatchPaths approach becomes worth revisiting for seamless in-session switching.
