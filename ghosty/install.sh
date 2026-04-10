#!/bin/bash
# Install Sage themes for Ghostty

GHOSTTY_THEMES_DIR="$HOME/.config/ghostty/themes"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$GHOSTTY_THEMES_DIR"

cp "$SCRIPT_DIR/sage-light" "$GHOSTTY_THEMES_DIR/sage-light"
cp "$SCRIPT_DIR/sage-dark" "$GHOSTTY_THEMES_DIR/sage-dark"

echo "Installed sage-light and sage-dark to $GHOSTTY_THEMES_DIR"

# Apply theme in Ghostty config (replace existing theme line if present)
GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
THEME_LINE="theme = light:sage-light,dark:sage-dark"
CONTRAST_LINE="minimum-contrast = 1.15"
if [ -f "$GHOSTTY_CONFIG" ]; then
    if grep -q "^theme" "$GHOSTTY_CONFIG"; then
        sed -i '' "s|^theme.*|$THEME_LINE|" "$GHOSTTY_CONFIG"
        echo "Replaced existing theme in $GHOSTTY_CONFIG"
    else
        echo "$THEME_LINE" >> "$GHOSTTY_CONFIG"
        echo "Applied theme in $GHOSTTY_CONFIG"
    fi
    if grep -q "^minimum-contrast" "$GHOSTTY_CONFIG"; then
        sed -i '' "s|^minimum-contrast.*|$CONTRAST_LINE|" "$GHOSTTY_CONFIG"
    else
        echo "$CONTRAST_LINE" >> "$GHOSTTY_CONFIG"
    fi
else
    mkdir -p "$(dirname "$GHOSTTY_CONFIG")"
    printf "%s\n%s\n" "$THEME_LINE" "$CONTRAST_LINE" > "$GHOSTTY_CONFIG"
    echo "Created $GHOSTTY_CONFIG with theme applied"
fi

echo "Done."

# Reload Ghostty config if it's running
if pgrep -x "ghostty" > /dev/null 2>&1; then
    ghostty +reload-config 2>/dev/null && echo "Ghostty config reloaded." || echo "Restart Ghostty to apply."
else
    echo "Open Ghostty to apply."
fi
