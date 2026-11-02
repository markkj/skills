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

function trackingOff() {
  const value = process.env.CLAUDE_PLUGIN_OPTION_track_turns ?? "";
  return ["false", "0", "off", "no"].includes(String(value).trim().toLowerCase());
}

// record-turn.js writes the ledger; its last row for a session says whether
// the session has a task yet.
function sessionHasTask(session) {
  if (!session) return true;
  let lines = [];
  try {
    lines = fs.readFileSync(path.join(configDir(), "usage.jsonl"), "utf8").split("\n");
  } catch {
    return false;
  }
  for (let i = lines.length - 1; i >= 0; i--) {
    if (!lines[i].includes(session)) continue;
    try {
      const row = JSON.parse(lines[i]);
      if (row.session === session) return Boolean(row.task_id);
    } catch {
      continue;
    }
  }
  return false;
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
  const parts = [];
  if (pairs.length) {
    parts.push(
      "Skill wraps: " +
        pairs.join("; ") +
        ". When you load that skill, also load each installed skill in the list. A missing skill is a skip."
    );
  }
  if (!trackingOff() && !sessionHasTask(event.session_id)) {
    parts.push(
      "This session has no task name yet. Start your reply with one line `Task: <3-6 word summary of the user's task>`. Write it once; write a new one only if the task changes."
    );
  }
  if (!parts.length) {
    process.stdout.write("{}\n");
    return;
  }
  const text = parts.join("\n\n");
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
