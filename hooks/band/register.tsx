import type { Engine, Register } from "claude-code";

type Row = { session?: string; task_id?: string; action?: string };

let task = "";
let action = "";
let configDir: string | undefined;

// Same folder hooks/record-turn.js writes to.
async function findConfig($: Engine) {
  const own = await $.env.get("MARKKJ_CONFIG_DIR");
  if (own) return own;
  const xdg = await $.env.get("XDG_CONFIG_HOME");
  if (xdg) return `${xdg}/markkj-skills`;
  const home = await $.env.get("HOME");
  return home ? `${home}/.config/markkj-skills` : "";
}

// The ledger is the one source of task and action, so the band and the
// report never disagree. It holds this session's state as of its last turn.
async function refresh($: Engine) {
  if (configDir === undefined) configDir = await findConfig($);
  if (!configDir) return;
  const session = await $.session.id();
  let text: unknown;
  try {
    text = await $.fs.read(`${configDir}/usage.jsonl`);
  } catch {
    return;
  }
  if (typeof text !== "string") return;
  const lines = text.split("\n");
  for (let i = lines.length - 1; i >= 0; i--) {
    if (!lines[i].includes(session)) continue;
    try {
      const row = JSON.parse(lines[i]) as Row;
      if (row.session !== session) continue;
      task = row.task_id ?? "";
      action = row.action ?? "";
      return;
    } catch {
      continue;
    }
  }
}

// `open` on macOS, `xdg-open` on Linux. A terminal link is not enough:
// VS Code's terminal does not open file:// links.
async function openReport($: Engine) {
  if (configDir === undefined) configDir = await findConfig($);
  const path = configDir ? `${configDir}/report.html` : "";
  if (!path || !(await $.fs.exists(path))) {
    $.ui.toast("No report yet. Finish a turn first.");
    return;
  }
  for (const cmd of ["open", "xdg-open"]) {
    try {
      const { exitCode } = await $.process.run([cmd, path]);
      if (exitCode === 0) return;
    } catch {
      // Not on this system; try the next one.
    }
  }
  $.ui.toast(`Could not open ${path}`);
}

export const register: Register = (on, options) => {
  const tracking = (options as { track_turns?: boolean }).track_turns !== false;
  let loaded = false;

  // The Stop hook writes the row after the turn ends, so read again when the
  // next prompt starts as well.
  on("turn.complete", async ($, event, next) => {
    const result = await next(event);
    if (tracking) await refresh($).catch(() => undefined);
    return result;
  }).catch((_$, event, next) => next(event));

  on("prompt.submit", async ($, event, next) => {
    if (tracking) await refresh($).catch(() => undefined);
    return next(event);
  }).catch((_$, event, next) => next(event));

  on("ui.render", { component: "AbovePrompt" }, async ($, event, next) => {
    const below = await next(event).catch(() => undefined);
    if (!tracking) return below;
    if (!loaded) {
      loaded = true;
      await refresh($).catch(() => undefined);
    }
    const { Box, Text, Button } = $.ui.resolve(event);
    const where = [task || "no task", action || "other"].join(" · ");
    const mine = (
      <Box>
        <Text>markkj · {where} · </Text>
        <Button key="open-report" label="open report" onPress={() => openReport($)} />
      </Box>
    );
    if (!below) return mine;
    return (
      <Box>
        {mine}
        {below}
      </Box>
    );
  }).catch((_$, event, next) => next(event));
};
