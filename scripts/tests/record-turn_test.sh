#!/bin/sh
# One turn appends one row. The same turn id does not append twice.
# The report lists every task, including a task that already had a row.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
RECORD="$ROOT/hooks/record-turn.js"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "fail: $1" >&2
  exit 1
}

mkdir -p "$TMP/proj/alpha/WORK-1" "$TMP/proj/beta/WORK-2" "$TMP/cfg/wraps"
printf '%s\n' "$TMP/proj" > "$TMP/cfg/project-path"
echo "# one" > "$TMP/proj/alpha/WORK-1/task-one.md"
echo "# two" > "$TMP/proj/beta/WORK-2/task-two.md"

export MARKKJ_CONFIG_DIR="$TMP/cfg"
export PROJECT_PATH="$TMP/proj"

# One small Claude turn, reused wherever only the task or session matters.
cat > "$TMP/one.jsonl" <<'JSON'
{"type":"user","uuid":"p1","message":{"role":"user","content":"do it"}}
{"type":"assistant","message":{"id":"o1","model":"claude-opus-5-5","usage":{"input_tokens":5,"output_tokens":6,"cache_read_input_tokens":4}}}
JSON

stop() {
  node "$RECORD" <<EOF
{"hook_event_name":"Stop","session_id":"$1","cwd":"$2","transcript_path":"$TMP/one.jsonl"}
EOF
}

stop s1 "$TMP/proj/alpha/WORK-1"
stop s1 "$TMP/proj/alpha/WORK-1"
stop s2 "$TMP/proj/beta/WORK-2"

rows=$(grep -c . "$TMP/cfg/usage.jsonl" || true)
[ "$rows" = "2" ] || fail "expected 2 rows (second Stop of one turn adds nothing), got $rows"
grep -q '"turn":"p1"' "$TMP/cfg/usage.jsonl" || fail "prompt uuid not used as turn id"
grep -q '"task_id":"WORK-1"' "$TMP/cfg/usage.jsonl" || fail "missing WORK-1"
grep -q '"task_id":"WORK-2"' "$TMP/cfg/usage.jsonl" || fail "missing WORK-2"
grep -q '"input_tokens":5' "$TMP/cfg/usage.jsonl" || fail "usage not read from transcript"
grep -q 'WORK-1' "$TMP/cfg/report.html" || fail "report missing first task"
grep -q 'WORK-2' "$TMP/cfg/report.html" || fail "report missing second task"
grep -q '<h1>Task report</h1>' "$TMP/cfg/report.html" || fail "report is not html"

# A worktree under the hub with no task-*.md takes its WORK_NAME from the path.
mkdir -p "$TMP/hub/WORK-9/repo/src"
MARKKJ_WORKTREE_ROOT="$TMP/hub" stop s3 "$TMP/hub/WORK-9/repo/src"
grep -q '"task_id":"WORK-9"' "$TMP/cfg/usage.jsonl" || fail "worktree path not used as task"

# Outside the hub, a branch named mark/<WORK_NAME> names the task.
mkdir -p "$TMP/elsewhere"
git -C "$TMP/elsewhere" init -q -b mark/WORK-8
stop s4 "$TMP/elsewhere"
grep -q '"task_id":"WORK-8"' "$TMP/cfg/usage.jsonl" || fail "mark/ branch not used as task"

# The session cwd stays in the original checkout. A tool call that touched a
# task folder names the task; a folder with no task-*.md does not count.
mkdir -p "$TMP/plain" "$TMP/proj/beta/NOTASK"
cat > "$TMP/touch.jsonl" <<JSON
{"type":"user","uuid":"t1","message":{"role":"user","content":"start it"}}
{"type":"assistant","message":{"id":"w1","content":[{"type":"tool_use","name":"Write","input":{"file_path":"$TMP/proj/beta/WORK-2/plan-two.md"}}],"usage":{"input_tokens":1,"output_tokens":1}}}
{"type":"assistant","message":{"id":"w2","content":[{"type":"tool_use","name":"Read","input":{"file_path":"$TMP/proj/beta/NOTASK/notes.md"}}],"usage":{"input_tokens":1,"output_tokens":1}}}
JSON
node "$RECORD" <<EOF
{"hook_event_name":"Stop","session_id":"s11","cwd":"$TMP/plain","transcript_path":"$TMP/touch.jsonl"}
EOF
last=$(tail -n 1 "$TMP/cfg/usage.jsonl")
printf '%s' "$last" | grep -q '"task_id":"WORK-2"' || fail "task folder in transcript not used: $last"
printf '%s' "$last" | grep -q "task-two.md" || fail "task path not set from transcript: $last"

# A worktree path in a Bash command names the task too, as written by
# coding-plan (~ or \$HOME form). A shell variable is not a name.
# The last path touched wins, even over an earlier task folder.
cat >> "$TMP/touch.jsonl" <<JSON
{"type":"assistant","message":{"id":"w3","content":[{"type":"tool_use","name":"Bash","input":{"command":"cd ~/workspace/working-place/WORK-7/repo && sh test.sh; ls \\"\$HOME/workspace/working-place/\$WORK_NAME\\""}}],"usage":{"input_tokens":1,"output_tokens":1}}}
JSON
HOME="$TMP/home" MARKKJ_WORKTREE_ROOT="$TMP/home/workspace/working-place" node "$RECORD" <<EOF
{"hook_event_name":"Stop","session_id":"s12","cwd":"$TMP/plain","transcript_path":"$TMP/touch.jsonl"}
EOF
last=$(tail -n 1 "$TMP/cfg/usage.jsonl")
printf '%s' "$last" | grep -q '"task_id":"WORK-7"' || fail "worktree path in command not used: $last"

# Claude usage is the sum of every API call since the last prompt.
# Rows that repeat one message id count once; tool results are not prompts.
cat > "$TMP/claude.jsonl" <<'JSON'
{"type":"user","message":{"role":"user","content":"old prompt"}}
{"type":"assistant","message":{"id":"m0","usage":{"input_tokens":1000,"output_tokens":1000,"cache_read_input_tokens":1000,"cache_creation_input_tokens":1000}}}
{"type":"user","message":{"role":"user","content":"new prompt"}}
{"type":"assistant","message":{"id":"m1","usage":{"input_tokens":3,"output_tokens":10,"cache_read_input_tokens":100,"cache_creation_input_tokens":5}}}
{"type":"assistant","message":{"id":"m1","usage":{"input_tokens":3,"output_tokens":10,"cache_read_input_tokens":100,"cache_creation_input_tokens":5}}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"x","content":"ok"}]}}
{"type":"assistant","message":{"id":"m2","usage":{"input_tokens":4,"output_tokens":20,"cache_read_input_tokens":200,"cache_creation_input_tokens":6}}}
JSON
node "$RECORD" <<EOF
{"hook_event_name":"Stop","session_id":"s5","cwd":"$TMP/proj/alpha/WORK-1","transcript_path":"$TMP/claude.jsonl"}
EOF
tail -n 1 "$TMP/cfg/usage.jsonl" | grep -q '"input_tokens":7,"output_tokens":30,"cache_read_tokens":300,"cache_write_tokens":11' || fail "claude turn usage not summed: $(tail -n 1 "$TMP/cfg/usage.jsonl")"

# The action is the last markkj skill called in the session, and it sticks to
# later turns. Always-on helpers and other plugins' skills do not change it.
cat > "$TMP/act.jsonl" <<'JSON'
{"type":"user","message":{"role":"user","content":"design the export"}}
{"type":"assistant","message":{"id":"a1","content":[{"type":"tool_use","name":"Skill","input":{"skill":"markkj-skills:design"}}],"usage":{"input_tokens":1,"output_tokens":1}}}
{"type":"assistant","message":{"id":"a2","content":[{"type":"tool_use","name":"Skill","input":{"skill":"markkj-skills:humanizer"}}],"usage":{"input_tokens":1,"output_tokens":1}}}
{"type":"assistant","message":{"id":"a3","content":[{"type":"tool_use","name":"Skill","input":{"skill":"simplify"}}],"usage":{"input_tokens":1,"output_tokens":1}}}
{"type":"user","message":{"role":"user","content":"fix that"}}
{"type":"assistant","message":{"id":"a4","usage":{"input_tokens":2,"output_tokens":2}}}
JSON
node "$RECORD" <<EOF
{"hook_event_name":"Stop","session_id":"s8","cwd":"$TMP/proj/alpha/WORK-1","transcript_path":"$TMP/act.jsonl"}
EOF
tail -n 1 "$TMP/cfg/usage.jsonl" | grep -q '"action":"design"' || fail "sticky action not design: $(tail -n 1 "$TMP/cfg/usage.jsonl")"

# A slash command names the action too.
cat >> "$TMP/act.jsonl" <<'JSON'
{"type":"user","message":{"role":"user","content":"<command-message>plan</command-message>\n<command-name>/plan</command-name>"}}
{"type":"assistant","message":{"id":"a5","usage":{"input_tokens":3,"output_tokens":3}}}
JSON
node "$RECORD" <<EOF
{"hook_event_name":"Stop","session_id":"s8","cwd":"$TMP/proj/alpha/WORK-1","transcript_path":"$TMP/act.jsonl"}
EOF
tail -n 1 "$TMP/cfg/usage.jsonl" | grep -q '"action":"plan"' || fail "slash command action not plan"

# A subagent run adds its own row to the parent session. Its tokens come from
# its own transcript; its action is the skill it called, else the parent's step.
cat > "$TMP/sub.jsonl" <<'JSON'
{"type":"user","message":{"role":"user","content":"look into it"}}
{"type":"assistant","message":{"id":"s1","model":"claude-haiku-5-5","usage":{"input_tokens":10,"output_tokens":20}}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"x","content":"ok"}]}}
{"type":"assistant","message":{"id":"s2","model":"claude-haiku-5-5","usage":{"input_tokens":30,"output_tokens":40}}}
JSON
node "$RECORD" <<EOF
{"hook_event_name":"SubagentStop","session_id":"s8","agent_id":"ag1","agent_type":"Explore","cwd":"$TMP/proj/alpha/WORK-1","transcript_path":"$TMP/act.jsonl","agent_transcript_path":"$TMP/sub.jsonl"}
EOF
node "$RECORD" <<EOF
{"hook_event_name":"SubagentStop","session_id":"s8","agent_id":"ag1","agent_type":"Explore","cwd":"$TMP/proj/alpha/WORK-1","transcript_path":"$TMP/act.jsonl","agent_transcript_path":"$TMP/sub.jsonl"}
EOF
sub=$(grep '"turn":"ag1#' "$TMP/cfg/usage.jsonl" || true)
[ "$(printf '%s\n' "$sub" | grep -c .)" = "1" ] || fail "subagent run not recorded once: $sub"
printf '%s' "$sub" | grep -q '"session":"s8"' || fail "subagent row not in parent session"
printf '%s' "$sub" | grep -q '"agent":"Explore"' || fail "subagent type missing"
printf '%s' "$sub" | grep -q '"action":"plan"' || fail "subagent did not take parent step: $sub"
printf '%s' "$sub" | grep -q '"input_tokens":40,"output_tokens":60' || fail "subagent tokens not summed over its whole run: $sub"

# Claude Code also stops internal helper agents that leave no transcript.
# Nothing to count means no row.
before=$(grep -c . "$TMP/cfg/usage.jsonl")
node "$RECORD" <<EOF
{"hook_event_name":"SubagentStop","session_id":"s8","agent_id":"ag2","cwd":"$TMP/proj/alpha/WORK-1","transcript_path":"$TMP/act.jsonl","agent_transcript_path":"$TMP/missing.jsonl"}
EOF
after=$(grep -c . "$TMP/cfg/usage.jsonl")
[ "$before" = "$after" ] || fail "empty subagent run wrote a row"

# No markkj skill yet: other. The report totals each action per task and overall.
grep -q '"task_id":"WORK-9".*"action":"other"' "$TMP/cfg/usage.jsonl" || fail "turn without skill is not other"
grep -q 'By action' "$TMP/cfg/report.html" || fail "report has no per-action totals"
grep -q 'All tasks' "$TMP/cfg/report.html" || fail "report has no overall totals"

# A skill's text is added as a meta user row mid-turn. It is not a new prompt.
cat > "$TMP/meta.jsonl" <<'JSON'
{"type":"user","message":{"role":"user","content":"go"}}
{"type":"assistant","message":{"id":"b1","usage":{"input_tokens":5,"output_tokens":5}}}
{"type":"user","isMeta":true,"message":{"role":"user","content":"Base directory for this skill: /x"}}
{"type":"assistant","message":{"id":"b2","usage":{"input_tokens":6,"output_tokens":6}}}
JSON
node "$RECORD" <<EOF
{"hook_event_name":"Stop","session_id":"s9","cwd":"$TMP/proj/alpha/WORK-1","transcript_path":"$TMP/meta.jsonl"}
EOF
tail -n 1 "$TMP/cfg/usage.jsonl" | grep -q '"input_tokens":11,"output_tokens":11' || fail "meta row split the turn: $(tail -n 1 "$TMP/cfg/usage.jsonl")"

# Cost uses the model's price and the cache TTL: 1M in ($4) + 100k out ($2)
# + 1M cache read ($0.20) + 100k 1-hour cache write ($0.80) on Opus 5.5 = $7.00.
cat > "$TMP/cost.jsonl" <<'JSON'
{"type":"user","message":{"role":"user","content":"price it"}}
{"type":"assistant","message":{"id":"c1","model":"claude-opus-5-5","usage":{"input_tokens":1000000,"output_tokens":100000,"cache_read_input_tokens":1000000,"cache_creation_input_tokens":100000,"cache_creation":{"ephemeral_1h_input_tokens":100000,"ephemeral_5m_input_tokens":0}}}}
JSON
node "$RECORD" <<EOF
{"hook_event_name":"Stop","session_id":"s10","cwd":"$TMP/hub/WORK-9/repo","transcript_path":"$TMP/cost.jsonl"}
EOF
last=$(tail -n 1 "$TMP/cfg/usage.jsonl")
printf '%s' "$last" | grep -q '"model":"claude-opus-5-5"' || fail "model not read from transcript: $last"
printf '%s' "$last" | grep -q '"cache_write_1h_tokens":100000' || fail "1-hour cache writes not split: $last"
grep -q '\$7\.00' "$TMP/cfg/report.html" || fail "report missing cost \$7.00"
grep -q '1\.0M tok' "$TMP/cfg/report.html" || fail "report missing token units"

# The report is swapped in whole; no temp file is left behind.
left=$(ls "$TMP/cfg" | grep -v -e '^usage.jsonl$' -e '^report.html$' -e '^project-path$' -e '^wraps$' || true)
[ -z "$left" ] || fail "temp files left: $left"

# Tracking off (the track_turns plugin setting) writes nothing.
before=$(grep -c . "$TMP/cfg/usage.jsonl")
CLAUDE_PLUGIN_OPTION_track_turns=false stop s6 "$TMP"
after=$(grep -c . "$TMP/cfg/usage.jsonl")
[ "$before" = "$after" ] || fail "tracking off still wrote a row"
# sh keeps a prefix assignment after a function call.
unset CLAUDE_PLUGIN_OPTION_track_turns MARKKJ_WORKTREE_ROOT

printf '%s\n' ponytail > "$TMP/cfg/wraps/code-review.txt"
out=$(node "$ROOT/hooks/wrap-prompt.js" <<'EOF'
{"hook_event_name":"UserPromptSubmit","prompt":"review"}
EOF
)
printf '%s\n' "$out" | grep -q ponytail || fail "wrap list missing from prompt hook: $out"
printf '%s\n' "$out" | grep -q code-review || fail "skill name missing from prompt hook"

# Light work has no task folder or worktree. Until the session has a task,
# the prompt hook asks Claude for a "Task:" line; once it has one, it stops asking.
rm "$TMP/cfg/wraps/code-review.txt"
out=$(node "$ROOT/hooks/wrap-prompt.js" <<'EOF'
{"hook_event_name":"UserPromptSubmit","session_id":"fresh","prompt":"fix the typo"}
EOF
)
printf '%s\n' "$out" | grep -q 'Task: ' || fail "no task-name ask for a session without a task: $out"
out=$(node "$ROOT/hooks/wrap-prompt.js" <<'EOF'
{"hook_event_name":"UserPromptSubmit","session_id":"s11","prompt":"go on"}
EOF
)
printf '%s\n' "$out" | grep -q 'Task: ' && fail "asked for a task name when the session has one: $out"

# The latest "Task:" line Claude wrote names a light task.
cat > "$TMP/light.jsonl" <<'JSON'
{"type":"user","uuid":"l1","message":{"role":"user","content":"fix the typo"}}
{"type":"assistant","message":{"id":"l2","content":[{"type":"text","text":"Task: Fix README typo\n\nDone."}],"usage":{"input_tokens":1,"output_tokens":1}}}
JSON
node "$RECORD" <<EOF
{"hook_event_name":"Stop","session_id":"fresh","cwd":"$TMP/plain","transcript_path":"$TMP/light.jsonl"}
EOF
tail -n 1 "$TMP/cfg/usage.jsonl" | grep -q '"task_id":"Fix README typo"' || fail "Task: line not used: $(tail -n 1 "$TMP/cfg/usage.jsonl")"

# A task folder or worktree still beats a "Task:" line.
cat "$TMP/light.jsonl" >> "$TMP/touch.jsonl"
HOME="$TMP/home" MARKKJ_WORKTREE_ROOT="$TMP/home/workspace/working-place" node "$RECORD" <<EOF
{"hook_event_name":"Stop","session_id":"s12","cwd":"$TMP/plain","transcript_path":"$TMP/touch.jsonl"}
EOF
tail -n 1 "$TMP/cfg/usage.jsonl" | grep -q '"task_id":"WORK-7"' || fail "Task: line beat the worktree: $(tail -n 1 "$TMP/cfg/usage.jsonl")"

echo "ok"
