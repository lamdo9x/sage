#!/usr/bin/env node
// Vietnamese IME fix for Claude Code — re-run after each `npm install -g @anthropic-ai/claude-code`

const fs = require("fs");
const { execSync } = require("child_process");

const PATCH_MARKER = "/* vn-ime-fix */";
const OLD_MARKER = "/* Vietnamese IME fix */";

// Resolve symlink: `which claude` returns a symlink, readlink gives the real install path
function findCliPath() {
  const candidates = [
    "/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/cli.js",
    "/usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js",
  ];
  try {
    const which = execSync("which claude 2>/dev/null", {
      encoding: "utf8",
    }).trim();
    if (which) {
      const real = execSync(
        `readlink -f "${which}" 2>/dev/null || realpath "${which}" 2>/dev/null`,
        { encoding: "utf8" },
      ).trim();
      candidates.unshift(
        real.replace(/\/bin\/claude$/, "") +
          "/lib/node_modules/@anthropic-ai/claude-code/cli.js",
      );
    }
  } catch (e) {}
  return candidates.find((p) => {
    try {
      fs.accessSync(p);
      return true;
    } catch (e) {}
  });
}

function isAlreadyPatched(content) {
  return content.includes(PATCH_MARKER) || content.includes(OLD_MARKER);
}

// cli.js is minified — find the input-handler block that checks for the DEL byte (\x7f).
// Strategy: locate `.includes("\x7f")`, walk back to the enclosing `if(!`, then
// match braces to extract the full block.
function findTargetBlock(content) {
  const DEL = String.fromCharCode(127);
  const patternIdx = content.indexOf('.includes("' + DEL + '")');
  if (patternIdx === -1) return null;

  const start = content.lastIndexOf("if(!", patternIdx);
  if (start === -1) return null;

  let braceCount = 0,
    end = start,
    foundFirst = false;
  for (let i = start; i < content.length && i < start + 1000; i++) {
    if (content[i] === "{") {
      braceCount++;
      foundFirst = true;
    } else if (content[i] === "}") {
      if (foundFirst && --braceCount === 0) {
        end = i + 1;
        break;
      }
    }
  }
  return { start, end, original: content.substring(start, end) };
}

// cli.js is minified so variable names are single chars like A6, l, b, K, h.
// Each regex captures a specific name from the known structure of the block:
//   if (!key.backspace && !key.delete && (input.includes(DEL) || ...)) {
//     let cursor = originalCursor;
//     for (...) { ... }
//     if (!originalCursor.equals(cursor)) { setText(cursor.text); setOffset(cursor.offset) }
//     cb1(), cb2(); return
//   }
function extractVarNames(original) {
  const keyMatch = original.match(/if\(!([a-zA-Z0-9_$]+)\.backspace/); // key event object
  const inputMatch = original.match(/([a-zA-Z0-9_$]+)\.includes\("/); // raw input string
  const cursorMatch = original.match(/,([a-zA-Z0-9_$]+)=([a-zA-Z0-9_$]+);for/); // cursor var in for-loop
  const textMatch = original.match(/\.text!==\w+\.text\)([a-zA-Z0-9_$]+)\(/); // setText callback
  const offMatch = original.match(/;([a-zA-Z0-9_$]+)\(\w+\.offset\)/); // setOffset callback
  const cbMatch = original.match(
    /([a-zA-Z0-9_$]+)\(\),([a-zA-Z0-9_$]+)\(\);return/,
  ); // optional callbacks
  if (!keyMatch || !inputMatch || !cursorMatch || !textMatch || !offMatch)
    return null;
  return {
    key: keyMatch[1],
    input: inputMatch[1],
    cursor: cursorMatch[2],
    setText: textMatch[1],
    setOffset: offMatch[1],
    callbacks: cbMatch ? cbMatch[1] + "()," + cbMatch[2] + "();" : "",
  };
}

// Generate minified JS using the extracted var names — must match surrounding minified style.
// Logic: instead of inserting the whole input string at once (which embeds DEL bytes literally),
// process each char: DEL/backspace = delete previous token, everything else = insert.
function buildPatch(vars) {
  const {
    key: K,
    input: I,
    cursor: C,
    setText: T,
    setOffset: O,
    callbacks: cb,
  } = vars;
  const DEL = String.fromCharCode(127);
  return [
    `if(!${K}.backspace&&!${K}.delete&&(${I}.includes("${DEL}")||${I}.includes("\\x08"))){${PATCH_MARKER}`,
    `let _v=${C};`,
    `for(let _i=0;_i<${I}.length;_i++){`,
    `let _c=${I}.charCodeAt(_i);`,
    `if(_c===127||_c===8){_v=_v.deleteTokenBefore?.()??_v.backspace()}`,
    `else{_v=_v.insert(${I}[_i])}`,
    `}`,
    `if(!${C}.equals(_v)){`,
    `if(${C}.text!==_v.text)${T}(_v.text);`,
    `${O}(_v.offset)}`,
    `${cb}return}`,
  ].join("");
}

// --- main ---
// 1. Find cli.js
// 2. Skip if already patched
// 3. Find the DEL-handling block (null = new version handles IME natively, no patch needed)
// 4. Extract minified var names from the block
// 5. Splice in the patched block

console.log("Applying Vietnamese IME fix...");

const cliPath = findCliPath();
if (!cliPath) {
  console.error(
    "  Error: cli.js not found. Try: npm install -g @anthropic-ai/claude-code",
  );
  process.exit(1);
}
console.log("  Found CLI at: " + cliPath);

const content = fs.readFileSync(cliPath, "utf8");

if (isAlreadyPatched(content)) {
  console.log("  Already patched — nothing to do.");
  process.exit(0);
}

const block = findTargetBlock(content);
if (!block) {
  console.log(
    "  Pattern not found — this version handles Vietnamese IME natively. No patch needed.",
  );
  process.exit(0);
}

const vars = extractVarNames(block.original);
if (!vars) {
  console.error(
    "  Error: could not extract variable names — pattern mismatch.",
  );
  console.error("  Block: " + block.original.substring(0, 150) + "...");
  process.exit(1);
}

const patched =
  content.substring(0, block.start) +
  buildPatch(vars) +
  content.substring(block.end);

// backup once so we can recover without npm reinstall
const backup = cliPath + ".bak";
if (!fs.existsSync(backup)) fs.copyFileSync(cliPath, backup);

// write to .tmp, syntax-check before replacing
const tmp = cliPath + ".tmp";
fs.writeFileSync(tmp, patched, "utf8");
try {
  execSync(`node --check "${tmp}"`, { stdio: "pipe" });
} catch (e) {
  fs.unlinkSync(tmp);
  console.error(
    "  Patched file failed syntax check — aborting. cli.js unchanged.",
  );
  process.exit(1);
}
fs.renameSync(tmp, cliPath);
console.log("  Applied: Vietnamese IME fix");
console.log("\nDone. Restart Claude Code to apply.");
