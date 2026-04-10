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
#    dark: rgb(55, 55, 55) → sage light #BDD0C2
#    hover: rgb(70, 70, 70) → slightly lighter sage
sudo sed -i '' \
  's/"rgb(55, 55, 55)"/"rgb(189, 208, 194)"/g; s/"rgb(70, 70, 70)"/"rgb(200, 218, 206)"/g' \
  "$CLI"
echo "  Applied: command highlight → sage (#BDD0C2)"

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

# 5. Diff removed colors (fix invisible on light background)
sudo sed -i '' 's/diffRemoved:"rgb(255,204,204)"/diffRemoved:"rgb(210,100,110)"/g' "$CLI"
sudo sed -i '' 's/diffRemovedDimmed:"rgb(255,233,233)"/diffRemovedDimmed:"rgb(160,60,70)"/g' "$CLI"
sudo sed -i '' 's/diffRemovedDimmed:"rgb(253,210,216)"/diffRemovedDimmed:"rgb(140,50,60)"/g' "$CLI"
sudo sed -i '' 's/diffAddedDimmed:"rgb(199,225,203)"/diffAddedDimmed:"rgb(80,120,90)"/g' "$CLI"
sudo sed -i '' 's/diffAddedDimmed:"rgb(209,231,253)"/diffAddedDimmed:"rgb(70,100,130)"/g' "$CLI"
echo "  Applied: diff colors → readable on light bg"

echo ""
echo "Done. Restart Claude Code to apply."
echo "Note: Ghosty minimum-contrast = 1.15 handles dim text readability."
