#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const SOURCE = path.join(__dirname, "sage-theme.json");
const THEMES_DIR = path.join(process.env.HOME, ".claude", "themes");
const DEST = path.join(THEMES_DIR, "sage.json");
const CLAUDE_JSON = path.join(process.env.HOME, ".claude.json");

function ensureThemesDir() {
  if (!fs.existsSync(THEMES_DIR)) {
    fs.mkdirSync(THEMES_DIR, { recursive: true });
    console.log("  Created ~/.claude/themes/");
  }
}

function copyTheme() {
  fs.writeFileSync(DEST, fs.readFileSync(SOURCE, "utf8"));
  console.log("  Installed sage theme");
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
if (!fs.existsSync(DEST)) {
  copyTheme();
  setThemeConfig();
}
