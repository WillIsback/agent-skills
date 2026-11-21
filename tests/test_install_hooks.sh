#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
SCRIPT="$REPO_ROOT/skills/oc-project/scripts/install-hooks.sh"
d="$(mktemp -d)"; S="$d/settings.json"
cat > "$S" <<'JSON'
{"env":{"A":"1"},"permissions":{"allow":["Bash(ls)"]},
 "hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"codegraph prompt-hook"}]}]}}
JSON
chmod 664 "$S"
orig_env="$(jq -S '.env, .permissions' "$S")"

bash "$SCRIPT" --settings "$S" >/dev/null 2>&1
assert_eq 0 $? "première installation : code 0"
assert_eq 2 "$(jq '.hooks.UserPromptSubmit | length' "$S")" "UserPromptSubmit : codegraph + oc-trigger"
assert_eq 1 "$(jq '[.hooks.UserPromptSubmit[].hooks[].command | select(. == "codegraph prompt-hook")] | length' "$S")" "codegraph conservé"
assert_eq 1 "$(jq '[.hooks.UserPromptSubmit[].hooks[].command | select(endswith("/hooks/oc-trigger.sh"))] | length' "$S")" "oc-trigger ajouté"
assert_eq 1 "$(jq '.hooks.PreToolUse | length' "$S")" "PreToolUse : une entrée"
assert_eq Bash "$(jq -r '.hooks.PreToolUse[0].matcher' "$S")" "matcher Bash"
assert_contains "/hooks/oc-merge-gate.sh" "$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$S")" "oc-merge-gate ajouté"
assert_eq "$orig_env" "$(jq -S '.env, .permissions' "$S")" "env et permissions intacts"
[ -f "$S.bak-oc" ] && _ok || _ko "sauvegarde .bak-oc"
assert_eq 664 "$(stat -c %a "$S")" "permissions conservées"
cmd="$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$S")"
[ -x "$cmd" ] && _ok || _ko "chemin de hook absolu et exécutable" "$cmd"

out="$(bash "$SCRIPT" --settings "$S" 2>&1)"
assert_contains "déjà installé" "$out" "seconde installation : message"
assert_eq 2 "$(jq '.hooks.UserPromptSubmit | length' "$S")" "idempotence UserPromptSubmit"
assert_eq 1 "$(jq '.hooks.PreToolUse | length' "$S")" "idempotence PreToolUse"

N="$d/neuf/settings.json"
bash "$SCRIPT" --settings "$N" >/dev/null 2>&1
assert_eq 1 "$(jq '.hooks.UserPromptSubmit | length' "$N")" "fichier absent : créé avec oc-trigger"
assert_eq 1 "$(jq '.hooks.PreToolUse | length' "$N")" "fichier absent : créé avec oc-merge-gate"

finish
