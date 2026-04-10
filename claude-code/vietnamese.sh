#!/bin/bash
# Vietnamese IME fix for Claude Code
# Fixes input loss when typing with Vietnamese IMEs (Unikey, OpenKey, EVKey, macOS)
#
# How the bug works:
#   IMEs send: DEL + replacement text (e.g. "a" + accent = DEL + "á")
#   Claude Code only processes the DEL chars and drops the rest
#
# This patch replaces that block with character-by-character processing.
#
# Re-run after `npm install -g @anthropic-ai/claude-code` updates

CLI="/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/cli.js"

if [ ! -f "$CLI" ]; then
  echo "Error: Claude Code not found at $CLI"
  exit 1
fi

echo "Applying Vietnamese IME fix..."

sudo node << 'EOF'
const fs = require('fs');
const cliPath = '/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/cli.js';
const PATCH_MARKER = '/* vn-ime-fix */';
const OLD_MARKER   = '/* Vietnamese IME fix */'; // cc-vietnamese compat

let content = fs.readFileSync(cliPath, 'utf8');

if (content.includes(PATCH_MARKER) || content.includes(OLD_MARKER)) {
  console.log('  Already patched — nothing to do.');
  process.exit(0);
}

// New version uses the actual DEL byte (0x7f) in the includes() check
const DEL = String.fromCharCode(127);
const patternIdx = content.indexOf('.includes("' + DEL + '")');
if (patternIdx === -1) {
  console.error('  Error: target pattern not found — Claude Code version may be incompatible.');
  process.exit(1);
}

// Walk back to the start of the enclosing if(! block
const start = content.lastIndexOf('if(!', patternIdx);
if (start === -1) {
  console.error('  Error: could not find start of if block.');
  process.exit(1);
}

// Extract the full block by matching braces
let braceCount = 0, end = start, foundFirst = false;
for (let i = start; i < content.length && i < start + 1000; i++) {
  if (content[i] === '{') { braceCount++; foundFirst = true; }
  else if (content[i] === '}') {
    braceCount--;
    if (foundFirst && braceCount === 0) { end = i + 1; break; }
  }
}

const original = content.substring(start, end);

// Extract minified variable names from the original block
const keyMatch   = original.match(/if\(!([a-zA-Z0-9_$]+)\.backspace/);
const inputMatch = original.match(/([a-zA-Z0-9_$]+)\.includes\("/);
const cursorMatch = original.match(/,([a-zA-Z0-9_$]+)=([a-zA-Z0-9_$]+);for/);
const textMatch  = original.match(/\.text!==\w+\.text\)([a-zA-Z0-9_$]+)\(/);
const offMatch   = original.match(/;([a-zA-Z0-9_$]+)\(\w+\.offset\)/);
const cbMatch    = original.match(/([a-zA-Z0-9_$]+)\(\),([a-zA-Z0-9_$]+)\(\);return/);

if (!keyMatch || !inputMatch || !cursorMatch || !textMatch || !offMatch) {
  console.error('  Error: could not extract variable names — pattern mismatch.');
  console.error('  Block: ' + original.substring(0, 150) + '...');
  process.exit(1);
}

const K  = keyMatch[1];     // key object  (e.g. A6)
const I  = inputMatch[1];   // input string (e.g. l)
const C  = cursorMatch[2];  // original cursor (e.g. b)
const T  = textMatch[1];    // setText func  (e.g. K)
const O  = offMatch[1];     // setOffset func (e.g. h)
const cb = cbMatch ? cbMatch[1] + '(),' + cbMatch[2] + '();' : '';

// Build the replacement: character-by-character processing
// Uses DEL byte directly (same as original) so the condition stays consistent
const delByte = String.fromCharCode(127);
let patch = 'if(!' + K + '.backspace&&!' + K + '.delete&&' + I + '.includes("' + delByte + '")){' + PATCH_MARKER;
patch += 'let _v=' + C + ';';
patch += 'for(let _i=0;_i<' + I + '.length;_i++){';
patch += 'let _c=' + I + '.charCodeAt(_i);';
patch += 'if(_c===127||_c===8){_v=_v.deleteTokenBefore?.()??_v.backspace()}';
patch += 'else{_v=_v.insert(' + I + '[_i])}';
patch += '}';
patch += 'if(!' + C + '.equals(_v)){';
patch += 'if(' + C + '.text!==_v.text)' + T + '(_v.text);';
patch += O + '(_v.offset)}';
patch += cb;
patch += 'return}';

const patched = content.substring(0, start) + patch + content.substring(end);
fs.writeFileSync(cliPath, patched, 'utf8');
console.log('  Applied: Vietnamese IME fix');
EOF

echo ""
echo "Done. Restart Claude Code to apply."
