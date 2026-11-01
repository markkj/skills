#!/usr/bin/env node
"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");

function configDir() {
  if (process.env.MARKKJ_CONFIG_DIR) return process.env.MARKKJ_CONFIG_DIR;
  const base = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config");
  return path.join(base, "markkj-skills");
}

function readStdin() {
  return new Promise((resolve) => {
    let data = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => {
      data += chunk;
    });
    process.stdin.on("end", () => resolve(data));
  });
}

async function main() {
  const raw = (await readStdin()).trim();
  let event = {};
  if (raw) {
    try {
      event = JSON.parse(raw);
    } catch {
      event = {};
    }
  }
  const wrapsDir = path.join(configDir(), "wraps");
  let names = [];
  try {
    names = fs.readdirSync(wrapsDir).filter((name) => name.endsWith(".txt"));
  } catch {
    names = [];
  }
  const pairs = [];
  for (const name of names.sort()) {
    const skill = name.replace(/\.txt$/, "");
    const lines = fs
      .readFileSync(path.join(wrapsDir, name), "utf8")
      .split("\n")
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith("#"));
    if (lines.length) pairs.push(`${skill} → ${lines.join(", ")}`);
  }
  if (!pairs.length) {
    process.stdout.write("{}\n");
    return;
  }
  const text =
    "Skill wraps: " +
    pairs.join("; ") +
    ". When you load that skill, also load each installed skill in the list. A missing skill is a skip.";
  const hook = event.hook_event_name || "";
  if (hook === "beforeSubmitPrompt" || hook === "stop") {
    process.stdout.write(JSON.stringify({ additional_context: text }) + "\n");
    return;
  }
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: hook || "UserPromptSubmit",
        additionalContext: text,
      },
    }) + "\n"
  );
}

main().catch(() => {
  process.stdout.write("{}\n");
});
