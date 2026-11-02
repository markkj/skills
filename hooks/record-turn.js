#!/usr/bin/env node
"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");

function configDir() {
  if (process.env.MARKKJ_CONFIG_DIR) return process.env.MARKKJ_CONFIG_DIR;
  const base = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config");
  return path.join(base, "markkj-skills");
}

// The plugin setting track_turns reaches command hooks as this variable.
function trackingOff() {
  const value = process.env.CLAUDE_PLUGIN_OPTION_track_turns ?? "";
  return ["false", "0", "off", "no"].includes(String(value).trim().toLowerCase());
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

function projectPath(dir) {
  if (process.env.PROJECT_PATH) return process.env.PROJECT_PATH;
  const file = path.join(dir, "project-path");
  if (!fs.existsSync(file)) return "";
  return fs.readFileSync(file, "utf8").split("\n")[0].trim();
}

function findTask(start, root) {
  if (!start) return { task_id: "", task_path: "" };
  let dir = path.resolve(start);
  const stop = root ? path.resolve(root) : path.parse(dir).root;
  while (true) {
    let names = [];
    try {
      names = fs.readdirSync(dir);
    } catch {
      names = [];
    }
    const task = names.find((name) => name.startsWith("task-") && name.endsWith(".md"));
    if (task) {
      return { task_id: path.basename(dir), task_path: path.join(dir, task) };
    }
    if (dir === stop || dir === path.parse(dir).root) break;
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return workTask(start);
}

// coding-plan worktrees live at <hub>/<WORK_NAME>/<repo> on branch mark/<WORK_NAME>
// and hold no task-*.md, so the work name stands in for the task.
function workTask(start) {
  const none = { task_id: "", task_path: "" };
  const hub = hubDir();
  const rel = path.relative(hub, path.resolve(start));
  if (rel && !rel.startsWith("..") && !path.isAbsolute(rel)) {
    return { task_id: rel.split(path.sep)[0], task_path: "" };
  }
  const git = spawnSync("git", ["-C", start, "branch", "--show-current"], { encoding: "utf8", timeout: 3000 });
  const branch = git.status === 0 ? git.stdout.trim() : "";
  return branch.startsWith("mark/") ? { task_id: branch.slice(5), task_path: "" } : none;
}

function folderTask(root, project, workId) {
  const dir = path.join(root, project, workId);
  let names = [];
  try {
    names = fs.readdirSync(dir);
  } catch {
    return null;
  }
  const task = names.find((name) => name.startsWith("task-") && name.endsWith(".md"));
  return task ? { task_id: workId, task_path: path.join(dir, task) } : null;
}

function hubDir() {
  return path.resolve(process.env.MARKKJ_WORKTREE_ROOT || path.join(os.homedir(), "workspace", "working-place"));
}

// A shell variable like $WORK_NAME is not a name.
function leadingName(text) {
  const match = text.match(/^[A-Za-z0-9._-]+/);
  return match && !/^\.+$/.test(match[0]) ? match[0] : "";
}

function eachIndex(text, prefix, visit) {
  for (let at = text.indexOf(prefix); at !== -1; at = text.indexOf(prefix, at + 1)) {
    visit(at, text.slice(at + prefix.length));
  }
}

// Each match is { at, task }: where in the text it starts, and the task it names.
function tasksIn(text, root) {
  const found = [];
  if (root) {
    eachIndex(text, path.resolve(root) + path.sep, (at, rest) => {
      const [project = ""] = rest.split(path.sep);
      const workId = leadingName(rest.slice(project.length + 1));
      const task = project && workId ? folderTask(root, project, workId) : null;
      if (task) found.push({ at, task });
    });
  }
  const hub = hubDir();
  const home = os.homedir();
  const prefixes = [hub];
  if (hub.startsWith(home + path.sep)) {
    const tail = hub.slice(home.length);
    prefixes.push(`~${tail}`, `$HOME${tail}`, `\${HOME}${tail}`);
  }
  for (const prefix of prefixes) {
    eachIndex(text, prefix + path.sep, (at, rest) => {
      const name = leadingName(rest);
      if (name) found.push({ at, task: { task_id: name, task_path: "" } });
    });
  }
  return found.sort((a, b) => a.at - b.at);
}

// The session cwd stays in the checkout the user started from, while the task
// folder and the worktree live elsewhere. The last one a tool call touched wins.
function taskFromRows(rows, root) {
  let last = null;
  for (const row of rows) {
    const message = row && row.message;
    if (!message || !Array.isArray(message.content)) continue;
    for (const part of message.content) {
      if (!part || part.type !== "tool_use" || !part.input) continue;
      for (const key of ["file_path", "path", "notebook_path", "command"]) {
        const text = part.input[key];
        if (typeof text !== "string") continue;
        const found = tasksIn(text, root);
        if (found.length) last = found[found.length - 1].task;
      }
    }
  }
  return last;
}

// Light work has no task folder or worktree; wrap-prompt.js asks Claude to
// name it in a "Task:" line instead. The latest line wins.
function summaryFromRows(rows) {
  let name = "";
  for (const row of rows) {
    const message = row && row.message;
    if (!row || row.type !== "assistant" || !message || !Array.isArray(message.content)) continue;
    for (const part of message.content) {
      if (!part || part.type !== "text" || typeof part.text !== "string") continue;
      for (const match of part.text.matchAll(/^\s*\**Task:\**\s*(.+)$/gm)) {
        const value = match[1].replace(/[`*]/g, "").trim().slice(0, 60);
        if (value) name = value;
      }
    }
  }
  return name ? { task_id: name, task_path: "" } : null;
}

function emptyUsage() {
  return { input_tokens: null, output_tokens: null, cache_read_tokens: null, cache_write_tokens: null };
}

function isPrompt(row) {
  if (!row || row.type !== "user" || row.isMeta || !row.message) return false;
  const content = row.message.content;
  if (typeof content === "string") return true;
  return Array.isArray(content) && !content.some((part) => part && part.type === "tool_result");
}

function add(total, field, value) {
  if (!Number.isFinite(value)) return;
  total[field] = (total[field] || 0) + value;
}

// A turn makes many API calls. Count every one since the last prompt.
// Claude writes one row per content block, each repeating its message's usage,
// so a message id counts once.
function readRows(file) {
  const rows = [];
  if (!file || !fs.existsSync(file)) return rows;
  for (const line of fs.readFileSync(file, "utf8").split("\n")) {
    if (!line.trim()) continue;
    try {
      rows.push(JSON.parse(line));
    } catch {
      continue;
    }
  }
  return rows;
}

function usageFromRows(rows) {
  if (rows.length === 0) return emptyUsage();
  let from = 0;
  rows.forEach((row, i) => {
    if (isPrompt(row)) from = i + 1;
  });
  const usage = emptyUsage();
  const seen = new Set();
  let model = "";
  let counted = false;
  for (const row of rows.slice(from)) {
    const message = row && row.message;
    if (!message || !message.usage) continue;
    if (message.id && seen.has(message.id)) continue;
    if (message.id) seen.add(message.id);
    counted = true;
    if (message.model) model = message.model;
    const split = message.usage.cache_creation;
    add(usage, "cache_write_1h_tokens", split ? split.ephemeral_1h_input_tokens : null);
    add(usage, "input_tokens", message.usage.input_tokens);
    add(usage, "output_tokens", message.usage.output_tokens);
    add(usage, "cache_read_tokens", message.usage.cache_read_input_tokens);
    add(usage, "cache_write_tokens", message.usage.cache_creation_input_tokens);
  }
  return counted ? { ...usage, model } : emptyUsage();
}

const PLUGIN = "markkj-skills";
// Loaded on almost every turn, so they would hide the step being worked on.
const HELPERS = new Set(["humanizer", "problem-decompose"]);
const OWN_SKILLS = (() => {
  try {
    return new Set(fs.readdirSync(path.join(__dirname, "..", "skills")));
  } catch {
    return new Set();
  }
})();

function actionOf(called) {
  if (!called) return "";
  const name = String(called).trim();
  const own = name.startsWith(`${PLUGIN}:`);
  const bare = own ? name.slice(PLUGIN.length + 1) : name;
  if (!own && !OWN_SKILLS.has(bare)) return "";
  return HELPERS.has(bare) ? "" : bare;
}

// The last markkj skill called in the session; later turns keep it until
// another one is called.
function actionFromRows(rows) {
  let action = "other";
  for (const row of rows) {
    const message = row && row.message;
    const found = [];
    if (message && Array.isArray(message.content)) {
      for (const part of message.content) {
        if (part && part.type === "tool_use" && part.name === "Skill" && part.input) found.push(part.input.skill);
      }
    }
    if (isPrompt(row) && typeof message.content === "string") {
      const command = message.content.match(/<command-name>\/([\w:-]+)<\/command-name>/);
      if (command) found.push(command[1]);
    }
    for (const called of found) {
      const next = actionOf(called);
      if (next) action = next;
    }
  }
  return action;
}

// Claude's Stop event has no turn id; the prompt row's uuid stands in, so a
// second Stop for the same turn adds nothing.
function turnOf(rows) {
  let id = "";
  for (const row of rows) {
    if (isPrompt(row) && row.uuid) id = row.uuid;
  }
  return id;
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

const PRICES = (() => {
  try {
    return require("./prices.json");
  } catch {
    return {};
  }
})();

function priceOf(model) {
  const id = String(model || "");
  const key = Object.keys(PRICES)
    .filter((name) => id.startsWith(name))
    .sort((a, b) => b.length - a.length)[0];
  return key ? PRICES[key] : null;
}

// Rows from before the 1-hour split: Claude Code writes 1-hour cache entries.
function costOf(row) {
  const price = priceOf(row.model);
  if (!price) return null;
  const n = (field) => (Number.isFinite(row[field]) ? row[field] : 0);
  const writes = n("cache_write_tokens");
  const hour = Number.isFinite(row.cache_write_1h_tokens) ? row.cache_write_1h_tokens : writes;
  const dollars =
    n("input_tokens") * price.input +
    n("output_tokens") * price.output +
    n("cache_read_tokens") * price.cache_read +
    hour * price.input * 2 +
    (writes - hour) * price.input * 1.25;
  return dollars / 1e6;
}

function tokens(value) {
  if (!Number.isFinite(value)) return "—";
  if (value >= 1e6) return `${(value / 1e6).toFixed(1)}M tok`;
  if (value >= 1e3) return `${(value / 1e3).toFixed(1)}k tok`;
  return `${value} tok`;
}

function dollars(rows) {
  const costs = rows.map(costOf);
  if (costs.every((cost) => cost === null)) return "—";
  const sum = costs.reduce((total, cost) => total + (cost || 0), 0);
  const mark = costs.some((cost) => cost === null) ? "+" : "";
  return `$${sum.toFixed(2)}${mark}`;
}

function total(rows, field) {
  return rows.reduce((sum, row) => sum + (Number.isFinite(row[field]) ? row[field] : 0), 0);
}

function actionTable(rows) {
  const byAction = new Map();
  for (const row of rows) {
    const key = row.action || "other";
    if (!byAction.has(key)) byAction.set(key, []);
    byAction.get(key).push(row);
  }
  const keys = [...byAction.keys()].sort((a, b) => (a === "other") - (b === "other") || a.localeCompare(b));
  const body = keys
    .map((key) => {
      const group = byAction.get(key);
      return `<tr><td>${escapeHtml(key)}</td><td>${group.length}</td><td>${tokens(total(group, "input_tokens"))}</td><td>${tokens(total(group, "output_tokens"))}</td><td>${tokens(total(group, "cache_read_tokens"))}</td><td>${tokens(total(group, "cache_write_tokens"))}</td><td>${dollars(group)}</td></tr>`;
    })
    .join("");
  return `<h3>By action</h3><table><thead><tr><th>Action</th><th>Turns</th><th>In</th><th>Out</th><th>Cache read</th><th>Cache write</th><th>Cost (USD)</th></tr></thead><tbody>${body}</tbody></table>`;
}

function writeReport(file, rows) {
  const groups = new Map();
  for (const row of rows) {
    const key = row.task_id || "(no task)";
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(row);
  }
  const keys = [...groups.keys()].sort((a, b) => {
    if (a === "(no task)") return 1;
    if (b === "(no task)") return -1;
    return a.localeCompare(b);
  });
  const sections = [];
  if (rows.length > 0) {
    sections.push(`<section><h2>All tasks</h2>${actionTable(rows)}</section>`);
  }
  if (keys.length === 0) {
    sections.push("<p>No turns yet.</p>");
  }
  for (const key of keys) {
    const group = groups.get(key);
    const sum = (field) => group.reduce((total, row) => total + (Number.isFinite(row[field]) ? row[field] : 0), 0);
    const body = group
      .map(
        (row) =>
          `<tr><td>${escapeHtml(row.ts)}</td><td>${escapeHtml(row.action || "other")}${row.agent ? ` <small>(subagent: ${escapeHtml(row.agent)})</small>` : ""}</td><td>${escapeHtml(row.model || "—")}</td><td>${tokens(row.input_tokens)}</td><td>${tokens(row.output_tokens)}</td><td>${tokens(row.cache_read_tokens)}</td><td>${tokens(row.cache_write_tokens)}</td><td>${dollars([row])}</td></tr>`
      )
      .join("");
    sections.push(
      `<section><h2>${escapeHtml(key)}</h2><p>Path: ${escapeHtml(group[0].task_path || "—")}</p><p>Turns: ${group.length}. Input: ${tokens(sum("input_tokens"))}. Output: ${tokens(sum("output_tokens"))}. Cost: ${dollars(group)}.</p>${actionTable(group)}<table><thead><tr><th>Time</th><th>Action</th><th>Model</th><th>In</th><th>Out</th><th>Cache read</th><th>Cache write</th><th>Cost (USD)</th></tr></thead><tbody>${body}</tbody></table></section>`
    );
  }
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Task report</title>
<style>
body { font-family: sans-serif; margin: 2rem; line-height: 1.4; }
table { border-collapse: collapse; width: 100%; margin: 1rem 0 2rem; }
th, td { border: 1px solid #ccc; padding: 0.4rem 0.6rem; text-align: left; }
th { background: #f4f4f4; }
</style>
</head>
<body>
<h1>Task report</h1>
<p>Each row is one finished turn. The same task can have more than one row. Every task in the ledger is listed.</p>
<p>Cost is an estimate at Anthropic API list prices (hooks/prices.json). On a Claude subscription you are not billed per token. "—" means the model has no price; "+" means some turns in the total have none.</p>
${sections.join("\n")}
</body>
</html>
`;
  // Sessions that stop together each rewrite the report; rename swaps it in
  // whole, so no reader sees half a file.
  const temp = `${file}.${process.pid}.tmp`;
  fs.writeFileSync(temp, html);
  fs.renameSync(temp, file);
}

async function main() {
  if (trackingOff()) return;
  const raw = (await readStdin()).trim();
  if (!raw) return;
  let event;
  try {
    event = JSON.parse(raw);
  } catch {
    return;
  }
  const dir = configDir();
  fs.mkdirSync(dir, { recursive: true });
  const ledger = path.join(dir, "usage.jsonl");
  const report = path.join(dir, "report.html");
  const root = projectPath(dir);
  const cwd = event.cwd || process.cwd();
  const rows = readRows(event.transcript_path);
  // A subagent writes its own transcript, which the parent's turn never counts.
  const agentRows = event.hook_event_name === "SubagentStop" ? readRows(event.agent_transcript_path) : null;
  const seen = [...rows, ...(agentRows || [])];
  let task = taskFromRows(seen, root) || findTask(cwd, root);
  if (!task.task_id) task = summaryFromRows(rows) || task;
  // Claude Code also stops internal helper agents that leave no transcript.
  if (agentRows && !agentRows.some((row) => row && row.message && row.message.usage)) return;
  const ownRows = agentRows || rows;
  const { model, ...tokens } = { model: "", ...usageFromRows(ownRows) };
  const session = event.session_id || "";
  let turn = turnOf(rows);
  let action = actionFromRows(rows);
  const extra = {};
  if (agentRows) {
    // One row per subagent run: a run resumed with a new prompt counts again.
    turn = `${event.agent_id || "agent"}#${agentRows.filter(isPrompt).length}`;
    const own = actionFromRows(agentRows);
    if (own !== "other") action = own;
    extra.agent = event.agent_type || "subagent";
  }
  const row = {
    ts: new Date().toISOString(),
    session,
    turn,
    model,
    task_id: task.task_id,
    task_path: task.task_path,
    project_path: root,
    action,
    ...extra,
    ...tokens,
  };
  let existing = [];
  if (fs.existsSync(ledger)) {
    existing = fs
      .readFileSync(ledger, "utf8")
      .split("\n")
      .filter(Boolean)
      .map((line) => {
        try {
          return JSON.parse(line);
        } catch {
          return null;
        }
      })
      .filter(Boolean);
  }
  const duplicate =
    turn &&
    existing.some((item) => item.session === session && item.turn === turn);
  if (!duplicate) {
    fs.appendFileSync(ledger, JSON.stringify(row) + "\n");
    existing.push(row);
  }
  writeReport(report, existing);
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error.message || String(error));
    process.exit(0);
  });
}

module.exports = { readRows, usageFromRows, actionFromRows, isPrompt, findTask, projectPath, configDir, writeReport };
