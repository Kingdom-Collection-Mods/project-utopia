#!/usr/bin/env node
/**
 * Paradox/Clausewitz script parser + transformer (Node.js)
 *
 * Supports:
 * - identifiers: STATE_SVEALAND, building_iron_mine, etc.
 * - strings: "building_subsistence_farm"
 * - numbers: 60, 3019
 * - blocks: { ... }
 * - arrays: provinces = { "x123" "x456" }  (parsed as arrays)
 * - maps: capped_resources = { building_iron_mine = 60 ... } (parsed as objects)
 *
 * Usage:
 *   node tool.js <inputDir> [--dry-run]
 *
 * Example:
 *   node tool.js ./game/common/history/states
 */

const { stat } = require("fs");
const fs = require("fs/promises");
const path = require("path");

const utopiaResources = [
  {
    newResourceKey: "building_rare_earths_mine",
    formula: {
      resources: {
        building_bauxite_mine: 0.5
      },
      operation: "sum",
      custom: {
        // --- LARGE (30) ---
        STATE_CALIFORNIA: 30,
        STATE_HINGGAN: 30,

        // --- MEDIUM (20) ---
        STATE_SOUTH_MADAGASCAR: 20,
        STATE_CONGO: 20,
        STATE_TONKIN: 20,
        STATE_MALAYA: 20,
        STATE_KOLA: 20,

        // --- SMALL (10) ---
        STATE_NORRLAND: 10,
        STATE_QUEBEC: 10,
        STATE_NORTHWEST_TERRITORIES: 10,
        STATE_BAJA_CALIFORNIA: 10,
        STATE_FORMOSA: 10,

        // --- TINY (3) ---
        STATE_RHONE: 3,
        STATE_AQUITAINE: 3,
        STATE_BAVARIA: 3,
        STATE_SAXONY: 3,
        STATE_WESTERN_SERBIA: 3,
        STATE_TALLINN: 3
      }
    }
  },
  {
    newResourceKey: "building_bauxite_mine",
    formula: {
      resources: ["building_lead_mine","building_sulfur_mine"],
      operation: "sum",
      multiplier: 0.5
    }
  }
]
 

// ------------------------------
// Tokenizer
// ------------------------------
function tokenize(text) {
  const tokens = [];
  const n = text.length;
  let i = 0;

  const isWS = (c) => c === " " || c === "\t" || c === "\r" || c === "\n" || c === "\uFEFF";
  const isBOM = (c) => c ===  "\uFEFF";
  const isIdentStart = (c) => /[A-Za-z0-9_:.@\-]/.test(c); // allow common pdx chars

  while (i < n) {
    const c = text[i];

    
    if (isBOM(c)) {
      i++;
      continue;
    }

    // whitespace
    if (isWS(c)) {
      i++;
      continue;
    }

    // comments: # ... endline
    if (c === "#") {
      while (i < n && text[i] !== "\n") i++;
      continue;
    }

    // single-char tokens
    if (c === "{" || c === "}" || c === "=") {
      tokens.push({ type: c, value: c });
      i++;
      continue;
    }

    // quoted string
    if (c === '"') {
      i++; // skip opening quote
      let s = "";
      while (i < n) {
        const ch = text[i];
        if (ch === "\\") {
          // minimal escapes
          const next = text[i + 1];
          if (next === '"' || next === "\\" || next === "n" || next === "t") {
            s += next === "n" ? "\n" : next === "t" ? "\t" : next;
            i += 2;
            continue;
          }
        }
        if (ch === '"') break;
        s += ch;
        i++;
      }
      if (text[i] !== '"') throw new Error("Unterminated string");
      i++; // closing quote
      tokens.push({ type: "STRING", value: s });
      continue;
    }

    // number (int) - allow leading -
    if (c === "-" || /[0-9]/.test(c)) {
      let j = i;
      if (text[j] === "-") j++;
      let hasDigit = false;
      while (j < n && /[0-9]/.test(text[j])) {
        hasDigit = true;
        j++;
      }
      if (hasDigit) {
        const raw = text.slice(i, j);
        tokens.push({ type: "NUMBER", value: Number(raw) });
        i = j;
        continue;
      }
      // fallthrough to ident if just '-'
    }

    // identifier
    if (isIdentStart(c)) {
      let j = i;
      while (j < n && isIdentStart(text[j])) j++;
      const ident = text.slice(i, j);
      tokens.push({ type: "IDENT", value: ident });
      i = j;
      continue;
    }

    throw new Error(`Unexpected character '${c}' at ${i}`);
  }

  return tokens;
}

// ------------------------------
// Parser (recursive descent)
// Grammar (loose):
// - document := { pair | value }*
// - pair := IDENT '=' value
// - value := IDENT | STRING | NUMBER | block
// - block := '{' (pair | value)* '}'
// We interpret a block as:
// - object if it contains any "pair"
// - array otherwise
// ------------------------------
function parseTokens(tokens) {
  let idx = 0;

  const peek = () => tokens[idx];
  const next = () => tokens[idx++];
  

  function parseValue() {
    const t = peek();
    if (!t) throw new Error("Unexpected EOF while parsing value");

    if (t.type === "IDENT") return next().value;
    if (t.type === "STRING") return next().value;
    if (t.type === "NUMBER") return next().value;
    if (t.type === "{") return parseBlock();

    throw new Error(`Unexpected token ${t.type} while parsing value`);
  }

  function parsePair(obj, key, val) {
    if (key === "resource") {
      if (!Object.prototype.hasOwnProperty.call(obj, key)) {
        obj[key] = [val];
        return;
      }
      const cur = obj[key];
      if (Array.isArray(cur)) {
        cur.push(val);
      } else {
        // In case some file had only one resource first as object (older parse),
        // normalize to array:
        obj[key] = [cur, val];
      }
      return;
    }

    // default behavior for all other keys: last-one-wins overwrite
    obj[key] = val;
  }

  function parseBlock() {
    const open = next();
    if (open.type !== "{") throw new Error("Expected '{'");

    const items = [];
    let hasPairs = false;

    while (true) {
      const t = peek();
      if (!t) throw new Error("Unexpected EOF in block");
      if (t.type === "}") {
        next(); // consume
        break;
      }

      // pair?
      if (t.type === "IDENT" && tokens[idx + 1] && tokens[idx + 1].type === "=") {
        hasPairs = true;
        const key = next().value; // IDENT
        next(); // '='
        const val = parseValue();
        items.push({ kind: "pair", key, val });
      } else {
        const val = parseValue();
        items.push({ kind: "value", val });
      }
    }

    if (hasPairs) {
      const obj = Object.create(null);
      for (const it of items) {
        if (it.kind === "pair") parsePair(obj, it.key, it.val)
        else {
          // Rare edge case: mixed content, preserve as special array entry
          if (!obj.__values) obj.__values = [];
          obj.__values.push(it.val);
        }
      }
      return obj;
    }

    return items.map((x) => x.val);
  }

  // top-level: sequence of pairs/values
  const doc = Object.create(null);
  const topValues = [];

  while (idx < tokens.length) {
    const t = peek();

    if (t.type === "IDENT" && tokens[idx + 1] && tokens[idx + 1].type === "=") {
      const key = next().value;
      next(); // '='
      const val = parseValue();
      doc[key] = val;
    } else {
      topValues.push(parseValue());
    }
  }

  if (topValues.length) doc.__values = topValues;
  return doc;
}

function parseText(text) {
  const tokens = tokenize(text);
  return parseTokens(tokens);
}

// ------------------------------
// Writer (pretty-printer)
// Note: This will reformat files. If you need 100% formatting preservation,
// switch to "patch-in-place" (brace-aware slicing) later.
// ------------------------------
function stringifyValue(v, indent) {
  const pad = "    ".repeat(indent);

  if (Array.isArray(v)) {
    // arrays in pdx script are commonly inline, but we’ll do one-liners for primitives
    const allPrim = v.every((x) => typeof x === "string" || typeof x === "number");
    if (allPrim) {
      const inner = v
        .map((x) => (typeof x === "string" ? `"${x}"` : String(x)))
        .join(" ");
      return `{ ${inner} }`;
    }
    // multi-line array
    const inner = v.map((x) => `${pad}    ${stringifyValue(x, indent + 1)}`).join("\n");
    return `{\n${inner}\n${pad}}`;
  }

  if (v && typeof v === "object") {
    const keys = Object.keys(v).filter((k) => k !== "__values");
    const lines = [];
    for (const k of keys) {
      const val = v[k];

      // Special-case: resource can be repeated; we store it as an array
      if (k === "resource" && Array.isArray(val)) {
        for (const item of val) {
          lines.push(`${pad}    resource = ${stringifyValue(item, indent + 1)}`);
        }
        continue;
      }

      // Normal behavior for everything else
      lines.push(`${pad}    ${k} = ${stringifyValue(val, indent + 1)}`);
    }

    // preserve odd mixed values if present
    if (Array.isArray(v.__values)) {
      for (const x of v.__values) {
        lines.push(`${pad}    ${stringifyValue(x, indent + 1)}`);
      }
    }
    return `{\n${lines.join("\n")}\n${pad}}`;
  }

  if (typeof v === "string") return `"${v}"`;
  if (typeof v === "number") return String(v);

  return `"${String(v)}"`;
}

function stringifyDoc(doc) {
  const keys = Object.keys(doc).filter((k) => k !== "__values");
  const lines = [];
  for (const k of keys) {
    lines.push(`${k} = ${stringifyValue(doc[k], 0)}`);
    lines.push(""); // blank line between entries
  }
  return lines.join("\n").trimEnd() + "\n";
}

// ------------------------------
// Transform: sum capped_resources + add new entry
// ------------------------------
function transformStates(doc, opts) {


  for (const [k, v] of Object.entries(doc)) {
    if (!k.startsWith("STATE_")) continue;
    if (!v || typeof v !== "object") continue;

    let stateName = k;
    const cappedResources = v.capped_resources;
    if (!cappedResources || typeof cappedResources !== "object" || Array.isArray(cappedResources)) continue;

    for (const resOpt of opts) {
      let val;
      if(resOpt.formula.operation === "sum"){
        let sum = 0;
        for (const [resourceKey, resourceValue] of Object.entries(cappedResources)) {
          if (resOpt.formula.resources.includes(resourceKey)){
            if (typeof resourceValue === "number") sum += resourceValue;
          }
        }

        val = Math.ceil(sum * resOpt.formula.multiplier);
      }
      if (Object.prototype.hasOwnProperty.call(cappedResources, resOpt.newResourceKey)) {
        console.error(`[ERROR] Resource key ${resOpt.newResourceKey} already exists in state ${k}`);
        continue;
      }

      if (resOpt.formula.custom && stateName in resOpt.formula.custom) {
        val += resOpt.formula.custom[stateName];
      }

      if (val > 0) {
        cappedResources[resOpt.newResourceKey] = val;
      }    
    }
  }
}

function resetFile(text) {
  for (const res of utopiaResources) {
      regex = new RegExp(`(\\s*${res.newResourceKey}\\s*=\\s*\\d+)`, 'g');
      text = text.replaceAll(regex, "");
  }
  return text;
}

// ------------------------------
// File walking
// ------------------------------
async function listFilesRecursive(dir) {
  const out = [];
  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const ent of entries) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) {
      out.push(...(await listFilesRecursive(full)));
    } else {
      // adjust extensions if you want
      if (ent.name.endsWith(".txt") || ent.name.endsWith(".state") || ent.name.endsWith(".script")) {
        out.push(full);
      }
    }
  }
  return out;
}

// ------------------------------
// Main
// ------------------------------
async function main() {
  const inputDir = process.argv[2];
  const dryRun = process.argv.includes("--dry-run");

  if (!inputDir) {
    console.error("Usage: node tool.js <inputDir> [--dry-run]");
    process.exit(1);
  }

  const files = await listFilesRecursive(inputDir);
  if (!files.length) {
    console.log("No matching files found.");
    return;
  }

  let changed = 0;
  for (const file of files) {
    const original = await fs.readFile(file, "utf8");
    let resetOriginal;
    try {
        resetOriginal = resetFile(original)
    }
    catch (e) {
      console.warn(`[SKIP] Reset error in ${file}: ${e.message}`);
      continue;
    }

    try {
      doc = parseText(resetOriginal);
    } catch (e) {
      console.warn(`[SKIP] Parse error in ${file}: ${e.message}`);
      continue;
    }

    transformStates(doc, utopiaResources);

    const outText = stringifyDoc(doc);
    if (outText !== original) {
      changed++;
      if (!dryRun) await fs.writeFile(file, outText, "utf8");
      console.log(`${dryRun ? "[DRY]" : "[OK] "} Updated ${file}`);
    }
  }

  console.log(`Done. Changed ${changed}/${files.length} files.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
