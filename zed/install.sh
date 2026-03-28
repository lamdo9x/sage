#!/bin/bash
# Install Sage theme for Zed

ZED_THEMES_DIR="$HOME/.config/zed/themes"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$ZED_THEMES_DIR"

cp "$SCRIPT_DIR/sage.json" "$ZED_THEMES_DIR/sage.json"
echo "Installed sage.json to $ZED_THEMES_DIR"

# Apply theme in Zed settings if not already set
ZED_SETTINGS="$HOME/.config/zed/settings.json"
if [ -f "$ZED_SETTINGS" ]; then
    if grep -q '"theme"' "$ZED_SETTINGS"; then
        # Replace existing theme block (light and dark values)
        sed -i '' 's/"light": ".*"/"light": "Sage Light"/' "$ZED_SETTINGS"
        sed -i '' 's/"dark": ".*"/"dark": "Sage Dark"/' "$ZED_SETTINGS"
        echo "Replaced existing theme in $ZED_SETTINGS"
    else
        echo "No theme key found in $ZED_SETTINGS — add manually:"
        echo '  "theme": { "mode": "system", "light": "Sage Light", "dark": "Sage Dark" }'
    fi
else
    echo "Zed settings not found at $ZED_SETTINGS"
fi

echo "Done. Zed auto-detects new themes — no restart needed."
