#!/usr/bin/env bash
# Checks that guard.sh blocks what it must and lets the rest through.
# Run it after any change to guard.sh, and once per harness before the first
# risky gesture (AGENTS.md asks for one end-to-end block observed on each).
# Usage: bash .claude/hooks/test-guard.sh   (exit 0 when every case conforms)
#
# The suite runs in a throwaway project (a temporary directory with its own
# .claude/hooks/) and points the refusal trace at a temporary file: it never
# writes to this MOS's .claude/guard-refusals.log.
GUARD="$(cd "$(dirname "$0")" && pwd)/guard.sh"
ok=0; ko=0

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/test-guard.XXXXXX") || exit 1
trap 'rm -r "$SANDBOX"' EXIT
mkdir -p "$SANDBOX/proj/.claude/hooks" "$SANDBOX/proj/implementation/mos/.claude/hooks"
SANDBOX=$(cd "$SANDBOX" && pwd -P)
PROJ="$SANDBOX/proj"
export CLAUDE_PROJECT_DIR="$PROJ"
export MANENCE_GUARD_LOG="$SANDBOX/refusals.log"

check() {  # expected label payload
  local output got
  output=$(printf '%s' "$3" | bash "$GUARD" 2>/dev/null)
  if echo "$output" | grep -q '"deny"'; then got="BLOCK"; else got="PASS"; fi
  if [ "$got" = "$1" ]; then
    ok=$((ok+1)); printf '  ok  %-5s %s\n' "$got" "$2"
  else
    ko=$((ko+1)); printf '  KO  expected %s, got %s: %s\n' "$1" "$got" "$2"
  fi
}

# --- Shell commands, Claude/Codex dialect. Each case: "expected|command". ---
cases=(
  # --- must be BLOCKED ---
  'BLOCK|git push origin main'
  'BLOCK|git push origin master'
  'BLOCK|git push -u origin main'
  'BLOCK|git push --force origin ops/week'
  'BLOCK|git push -f origin ops/week'
  'BLOCK|git -C /path/to/repo push origin main'
  'BLOCK|git -c x=y push --force'
  'BLOCK|cd /tmp && git push origin main'
  'BLOCK|git commit -m "fix" ; git push --force-with-lease'
  'BLOCK|for b in a b; do git push --force origin $b; done'
  'BLOCK|GIT_SSH_COMMAND="ssh -i k" git push origin main'
  'BLOCK|(git push origin main)'
  'BLOCK|git push origin \
    --force ops/week'
  'BLOCK|rm -rf /tmp/x'
  'BLOCK|rm --recursive --force /tmp/x'
  'BLOCK|rm -r /tmp/x -f'
  'BLOCK|:(){ :|:& };:'
  # rule 4: a shell write to the guardrail's own files
  'BLOCK|echo "exit 0" > .claude/hooks/guard.sh'
  'BLOCK|printf "{}" >| ./.claude/settings.json'
  'BLOCK|sed -i "" "s/deny/allow/" .claude/settings.json'
  'BLOCK|perl -pi -e "s/deny/ask/" .claude/hooks/guard.sh'
  'BLOCK|cat new.json | tee .claude/settings.local.json'
  'BLOCK|cp /tmp/guard.sh .claude/hooks/guard.sh'
  'BLOCK|mv /tmp/x.json .claude/settings.json'
  'BLOCK|trash .claude/hooks/guard.sh'
  'BLOCK|cd docs && truncate -s 0 .claude/hooks/lint.sh'
  'BLOCK|echo "{}" > '"$PROJ"'/.claude/settings.json'
  # --- must PASS (the lived false positives, and their neighbours) ---
  'PASS|git push origin publish/my-article && gh pr create --base main'
  'PASS|git commit -m "inbox: the guard blocks on the word main in a message"'
  'PASS|git push -u origin ops/week-21-27-09'
  'PASS|git push -q origin ops/week'
  'PASS|tail -f /var/log/x && git push origin ops/week'
  'PASS|gh pr merge 98 --repo org/repo --squash'
  'PASS|echo "the default branch is called main" > note.md'
  'PASS|echo "never git push --force here" > note.md'
  'PASS|cat >> note.md <<EOF
A note about the guard: it used to read git push and --force on the same line.
EOF'
  'PASS|git push origin HEAD'
  'PASS|git -C /path push origin fix/date'
  'PASS|rm -r /tmp/x && tail -f log'
  'PASS|git log --oneline -3 && git status'
  # rule 4: reading and running the guardrail stay free; other copies are not ours
  'PASS|cat .claude/settings.json && bash .claude/hooks/test-guard.sh'
  'PASS|cp .claude/hooks/guard.sh /tmp/guard-backup.sh'
  'PASS|diff .claude/hooks/guard.sh /tmp/guard.sh > /tmp/guard.diff'
  'PASS|sed -n 1,20p .claude/hooks/guard.sh'
  'PASS|cp /tmp/guard.sh implementation/mos/.claude/hooks/guard.sh'
  'PASS|bash upgrade.sh /path/to/core --apply'
  'PASS|chmod +x .claude/hooks/*.sh'
)

for c in "${cases[@]}"; do
  expected="${c%%|*}"; cmd="${c#*|}"
  payload=$(jq -cn --arg cmd "$cmd" --arg cwd "$PROJ" '{tool_name:"Bash",tool_input:{command:$cmd},cwd:$cwd}')
  check "$expected" "${cmd%%$'\n'*}" "$payload"
done

# The same refusal in Grok's dialect (camelCase payload, native tool name, answer in kind).
payload=$(jq -cn '{toolName:"run_terminal_command",toolInput:{command:"git push -f origin ops/week"}}')
out=$(printf '%s' "$payload" | bash "$GUARD" 2>/dev/null)
if echo "$out" | jq -e '.decision == "deny"' >/dev/null 2>&1; then
  ok=$((ok+1)); printf '  ok  BLOCK run_terminal_command (grok) answered in its dialect\n'
else
  ko=$((ko+1)); printf '  KO  grok dialect: %s\n' "$out"
fi

# --- File tools. Each case: "expected|dialect|tool|path" (path relative to the project). ---
edits=(
  'BLOCK|claude|Edit|.claude/hooks/guard.sh'
  'BLOCK|claude|Write|.claude/settings.json'
  'BLOCK|claude|Write|.claude/settings.local.json'
  'BLOCK|claude|MultiEdit|.claude/hooks/lint.sh'
  'BLOCK|claude|Edit|ABS:.claude/hooks/test-guard.sh'
  'BLOCK|grok|search_replace|.claude/settings.json'
  'BLOCK|grok|write_file|ABS:.claude/hooks/guard.sh'
  'BLOCK|claude|apply_patch|PATCH:.claude/hooks/guard.sh'
  'PASS|claude|Edit|log.md'
  'PASS|claude|Write|.claude/skills/my-skill/SKILL.md'
  'PASS|claude|Edit|.claude/mos.json'
  'PASS|claude|Edit|implementation/mos/.claude/hooks/guard.sh'
  'PASS|grok|search_replace|knowledge-base/index.md'
  'PASS|claude|apply_patch|PATCH:inbox/note.md'
)

for c in "${edits[@]}"; do
  IFS='|' read -r expected dialect tool path <<< "$c"
  case "$path" in
    ABS:*)   path="$PROJ/${path#ABS:}"; field=file_path ;;
    PATCH:*) path="${path#PATCH:}"; field=command ;;
    *)       field=file_path ;;
  esac
  if [ "$field" = command ]; then
    value=$(printf '*** Begin Patch\n*** Update File: %s\n@@\n-a\n+b\n*** End Patch' "$path")
  else
    value=$path
  fi
  if [ "$dialect" = grok ]; then
    payload=$(jq -cn --arg t "$tool" --arg v "$value" --arg cwd "$PROJ" '{toolName:$t,toolInput:{path:$v},cwd:$cwd}')
  else
    payload=$(jq -cn --arg t "$tool" --arg f "$field" --arg v "$value" --arg cwd "$PROJ" '{tool_name:$t,tool_input:{($f):$v},cwd:$cwd}')
  fi
  check "$expected" "$tool ($dialect) $path" "$payload"
done

# --- The refusal trace: one line per BLOCK above, none per PASS; and a trace
# that cannot be written never turns a refusal into a pass. ---
blocks=0
blocks=1  # the Grok case above
for c in "${cases[@]}" "${edits[@]}"; do [ "${c%%|*}" = BLOCK ] && blocks=$((blocks+1)); done
lines=$(wc -l < "$MANENCE_GUARD_LOG" 2>/dev/null | tr -d ' ')
if [ "${lines:-0}" -eq "$blocks" ] && awk -F'\t' 'NF != 4 || length($4) > 200 { bad = 1 } END { exit bad }' "$MANENCE_GUARD_LOG"; then
  ok=$((ok+1)); printf '  ok  TRACE %s lines for %s refusals, four tab-separated fields\n' "$lines" "$blocks"
else
  ko=$((ko+1)); printf '  KO  TRACE expected %s lines, got %s (or a malformed line)\n' "$blocks" "${lines:-0}"
fi
payload=$(jq -cn --arg cmd 'rm -rf /tmp/x' '{tool_name:"Bash",tool_input:{command:$cmd}}')
MANENCE_GUARD_LOG="$SANDBOX/no/such/dir/refusals.log" check BLOCK "unwritable trace still refuses" "$payload"

printf '\n%d cases conform, %d deviate\n' "$ok" "$ko"
[ "$ko" -eq 0 ]
