#!/usr/bin/env node
// Sync Sage theme into tweakcc config and apply to Claude Code binary.
// Run after each `npm install -g @anthropic-ai/claude-code` update.

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const CC_PKG = "/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/package.json";
const TWEAKCC_CONFIG = path.join(process.env.HOME, ".tweakcc", "config.json");
const CACHE = path.join(process.env.HOME, ".cache", "tweakcc-sage-version");
const SAGE_JSON = path.join(__dirname, "sage-tweakcc.json");

function getCCVersion() {
  try {
    return JSON.parse(fs.readFileSync(CC_PKG, "utf8")).version;
  } catch {
    return null;
  }
}

function getCachedVersion() {
  try {
    return fs.readFileSync(CACHE, "utf8").trim();
  } catch {
    return null;
  }
}

const ccVersion = getCCVersion();
if (!ccVersion) {
  console.error("  Error: Claude Code not found at", CC_PKG);
  process.exit(1);
}

if (getCachedVersion() === ccVersion) {
  process.exit(0);
}

console.log("🎨  Re-applying Sage theme (CC", ccVersion + ")...");

// Read current tweakcc config
let config;
try {
  config = JSON.parse(fs.readFileSync(TWEAKCC_CONFIG, "utf8"));
} catch {
  console.error("  Error: tweakcc config not found at", TWEAKCC_CONFIG);
  console.error("  Run `npx tweakcc` once first to initialize.");
  process.exit(1);
}

// Read sage theme
const sage = JSON.parse(fs.readFileSync(SAGE_JSON, "utf8"));

// Upsert sage theme in config
const themes = config.settings.themes;
const idx = themes.findIndex((t) => t.id === sage.id);
if (idx >= 0) {
  themes[idx] = sage;
} else {
  themes.push(sage);
}

fs.writeFileSync(TWEAKCC_CONFIG, JSON.stringify(config, null, 2));
console.log("  Updated config.json with Sage theme");

// Apply via tweakcc --apply (needs sudo to write native binary)
let output = "";
try {
  output = execSync("sudo npx --yes tweakcc --apply 2>&1", { encoding: "utf8" });
  process.stdout.write(output);
} catch (e) {
  process.stdout.write(e.stdout || "");
  console.error("  Error: tweakcc --apply failed");
  process.exit(1);
}

// Only cache version if themes patch succeeded
if (output.includes("✗ Themes")) {
  console.log("  Warning: themes patch failed — will retry on next launch.");
  process.exit(0);
}

fs.writeFileSync(CACHE, ccVersion);
console.log("  Done. Restart Claude Code to apply.");
