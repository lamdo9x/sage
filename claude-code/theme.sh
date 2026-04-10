#!/bin/bash
# Sage theme patch for Claude Code
# Re-run this after `npm install -g @anthropic-ai/claude-code` updates

CLI="/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/cli.js"

if [ ! -f "$CLI" ]; then
  echo "Error: Claude Code not found at $CLI"
  exit 1
fi

echo "Patching Claude Code with Sage theme..."

# Backup (overwrite to match current version)
sudo cp "$CLI" "$CLI.bak"
echo "  Backed up cli.js.bak"

# 1. Command/skill highlight background (userMessageBackground)
#    Patch all theme variants: light (wL_), dark default (JL_), dark-daltonized (XL_)
#    Original dark: rgb(55, 55, 55); original light: rgb(245, 245, 245) or similar
#    → sage light #BDD0C2 for all themes
sudo sed -i '' \
  's/"rgb(55, 55, 55)"/"rgb(189, 208, 194)"/g; s/"rgb(70, 70, 70)"/"rgb(200, 218, 206)"/g' \
  "$CLI"
# Also patch dark-theme-specific values (in case of prior deep-green patch or fresh install variant)
sudo sed -i '' \
  's/userMessageBackground:"rgb(24, 56, 38)"/userMessageBackground:"rgb(189, 208, 194)"/g' \
  "$CLI"
sudo sed -i '' \
  's/userMessageBackgroundHover:"rgb(44, 76, 58)"/userMessageBackgroundHover:"rgb(200, 218, 206)"/g' \
  "$CLI"
sudo sed -i '' \
  's/userMessageBackgroundHover:"rgb(34, 66, 48)"/userMessageBackgroundHover:"rgb(200, 218, 206)"/g' \
  "$CLI"
echo "  Applied: command highlight → sage (#BDD0C2) [all themes]"

# 2. Inline code / codespan (permission color)
#    Original blues → sage green (#34A85F dark, #10A868 light)
sudo sed -i '' 's/permission:"rgb(153,204,255)"/permission:"rgb(52,168,95)"/g' "$CLI"
sudo sed -i '' 's/permission:"rgb(177,185,249)"/permission:"rgb(74,200,120)"/g' "$CLI"
sudo sed -i '' 's/permission:"rgb(87,105,247)"/permission:"rgb(16,168,104)"/g' "$CLI"
sudo sed -i '' 's/permission:"rgb(51,102,255)"/permission:"rgb(12,140,84)"/g' "$CLI"
sudo sed -i '' 's/permissionShimmer:"rgb(101,152,255)"/permissionShimmer:"rgb(140,175,155)"/g' "$CLI"
sudo sed -i '' 's/permissionShimmer:"rgb(137,155,255)"/permissionShimmer:"rgb(155,190,170)"/g' "$CLI"
sudo sed -i '' 's/permissionShimmer:"rgb(183,224,255)"/permissionShimmer:"rgb(165,200,180)"/g' "$CLI"
sudo sed -i '' 's/permissionShimmer:"rgb(207,215,255)"/permissionShimmer:"rgb(180,210,192)"/g' "$CLI"
echo "  Applied: inline code (codespan) → sage green"

# 3. Suggestion color (selected options, some UI labels)
#    Original blues → muted sage
sudo sed -i '' 's/suggestion:"rgb(153,204,255)"/suggestion:"rgb(125,158,138)"/g' "$CLI"
sudo sed -i '' 's/suggestion:"rgb(177,185,249)"/suggestion:"rgb(145,178,158)"/g' "$CLI"
sudo sed -i '' 's/suggestion:"rgb(87,105,247)"/suggestion:"rgb(100,140,120)"/g' "$CLI"
sudo sed -i '' 's/suggestion:"rgb(51,102,255)"/suggestion:"rgb(80,120,100)"/g' "$CLI"
echo "  Applied: suggestion → muted sage"

# 4. Inline code bold (matches Zed keyword font_weight: 700)
sudo sed -i '' \
  's/case"codespan":return EA("permission",q)(A\.text)/case"codespan":return Y8.bold(EA("permission",q)(A.text))/' \
  "$CLI"
echo "  Applied: codespan bold"

# 5. User message text color → near-black (dark on sage green background)
#    Default "text" token is white in dark mode → unreadable on light sage bg
#    a. Main user text in message box (1 occurrence)
sudo sed -i '' 's/createElement(V,{color:"text"},_)/createElement(V,{color:"rgb(30,30,30)"},_)/' "$CLI"
#    b. Brief layout user text (1 occurrence)
sudo sed -i '' 's/?"subtle":"text"/?"subtle":"rgb(30,30,30)"/' "$CLI"
#    c. Rainbow text plain segments
sudo sed -i '' 's/key:`plain-\${P}`,color:"text"}/key:`plain-${P}`,color:"rgb(30,30,30)"}/' "$CLI"
echo "  Applied: user message text → near-black"

echo ""
echo "Done. Restart Claude Code to apply."
echo "Note: Ghosty minimum-contrast = 1.15 handles dim text readability."
