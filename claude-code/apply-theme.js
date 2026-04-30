#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const THEMES_DIR = path.join(process.env.HOME, ".claude", "themes");
const DEST = path.join(THEMES_DIR, "sage.json");
const CLAUDE_JSON = path.join(process.env.HOME, ".claude.json");

function isDarkMode() {
  try {
    const result = execSync("defaults read -g AppleInterfaceStyle 2>/dev/null", {
      encoding: "utf8",
      stdio: ["pipe", "pipe", "pipe"],
    }).trim();
    return result === "Dark";
  } catch {
    return false;
  }
}

function getSourceTheme() {
  const variant = isDarkMode() ? "dark" : "light";
  const src = path.join(__dirname, `sage-${variant}.json`);
  return { src, variant };
}

function ensureThemesDir() {
  if (!fs.existsSync(THEMES_DIR)) {
    fs.mkdirSync(THEMES_DIR, { recursive: true });
    console.log("  Created ~/.claude/themes/");
  }
}

function syncTheme() {
  const { src, variant } = getSourceTheme();
  fs.writeFileSync(DEST, fs.readFileSync(src, "utf8"));
  console.log(`  Installed sage theme (${variant} mode)`);
}

function setThemeConfig() {
  try {
    const config = JSON.parse(fs.readFileSync(CLAUDE_JSON, "utf8"));
    if (config.theme !== "custom:sage") {
      config.theme = "custom:sage";
      fs.writeFileSync(CLAUDE_JSON, JSON.stringify(config, null, 2));
      console.log("  Set theme to custom:sage");
    }
  } catch {
    console.log("  Note: Set theme manually via /theme");
  }
}

ensureThemesDir();
syncTheme();
setThemeConfig();
