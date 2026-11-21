#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
HOOK="$REPO_ROOT/skills/oc-project/hooks/oc-merge-gate.sh"
export PATH="$REPO_ROOT/tests/fixtures:$PATH"
SHA_OK=3f2a9c1e0b9d8c7a6f5e4d3c2b1a0f9e8d7c6b5a

# projet <avec_state:0|1> [ligne de carnet] -> chemin d'un projet temporaire
projet() {
  local d; d="$(mktemp -d)"
  if [ "$1" = 1 ]; then mkdir -p "$d/.oc"; printf -- '---\nphase: livraison\n---\n' > "$d/.oc/state.md"; fi
  if [ -n "${2:-}" ]; then printf '# Carnet\n%s\n' "$2" > "$d/.oc/carnet.md"; fi
  printf '%s' "$d"
}
# gate <cwd> <commande> [tool_name]
gate() {
  jq -n --arg c "$2" --arg d "$1" --arg t "${3:-Bash}" \
    '{tool_name:$t, tool_input:{command:$c}, cwd:$d}' | bash "$HOOK" 2>/dev/null
}
pr() { export GH_STUB_JSON="{\"headRefName\":\"$1\",\"headRefOid\":\"$2\",\"baseRefName\":\"${3:-main}\"}"; }
decision() { printf '%s' "$1" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null; }
raison() { printf '%s' "$1" | jq -r '.hookSpecificOutput.permissionDecisionReason' 2>/dev/null; }
reset() { unset GH_STUB_EXIT; export GH_STUB_LOG; GH_STUB_LOG="$(mktemp)"; }

reset; d=$(projet 1); pr feat/0.3.0 $SHA_OK
assert_empty "$(gate "$d" "gh pr merge 5" Read)" "hors_bash"
assert_empty "$(gate "$d" "git push")" "autre_commande"

reset; d=$(projet 0); pr feat/0.3.0 $SHA_OK
assert_empty "$(gate "$d" "gh pr merge 5")" "hors_projet"
assert_empty "$(cat "$GH_STUB_LOG")" "hors_projet : gh non appelé"

reset; d=$(projet 1); pr chore/outillage $SHA_OK
assert_empty "$(gate "$d" "gh pr merge 1 --squash")" "outillage_exempte"
pr dependabot/pip/x-1.2 $SHA_OK
assert_empty "$(gate "$d" "gh pr merge 7")" "dependabot_exempte"
pr feat/0.3.0-durcir $SHA_OK feat/0.3.0
assert_empty "$(gate "$d" "gh pr merge 9")" "sous_branche_exemptee"

reset; d=$(projet 1); pr feat/0.3.0 $SHA_OK
out=$(gate "$d" "gh pr merge 12 --squash")
assert_eq deny "$(decision "$out")" "lot_sans_carnet : deny"
assert_contains "v0.3.0" "$(raison "$out")" "lot_sans_carnet : raison"
assert_eq PreToolUse "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.hookEventName' 2>/dev/null)" "hookEventName"

reset; d=$(projet 1 '<!-- oc-gate: v0.3.0 validé 2026-12-18 sha:3f2a9c1 -->'); pr feat/0.3.0 $SHA_OK
assert_empty "$(gate "$d" "gh pr merge 12 --squash")" "lot_valide"
pr feat/0.3.0 9999999aaaaaaa
assert_eq deny "$(decision "$(gate "$d" "gh pr merge 12")")" "sha_perime"

reset; d=$(projet 1 '<!-- oc-gate: specs validé 2026-12-01 sha:3f2a9c1 -->'); pr docs/0.2.0-specs $SHA_OK
assert_empty "$(gate "$d" "gh pr merge 4")" "specs_valide"

reset; d=$(projet 1 '<!-- oc-gate: v0.2.0 validé 2026-12-10 sha:3f2a9c1 -->'); pr feat/0.3.0 $SHA_OK
assert_eq deny "$(decision "$(gate "$d" "gh pr merge 12")")" "autre_lot_ne_compte_pas"

reset; d=$(projet 1 "$(printf '<!-- oc-gate: v0.3.0 validé 2026-12-18 sha:3f2a9c1 -->\n<!-- oc-gate: v0.3.0 validé 2026-12-19 sha:1111111 -->')"); pr feat/0.3.0 $SHA_OK
assert_eq deny "$(decision "$(gate "$d" "gh pr merge 12")")" "derniere_occurrence_fait_foi"

reset; d=$(projet 1); export GH_STUB_EXIT=1
out=$(gate "$d" "gh pr merge 12")
assert_eq deny "$(decision "$out")" "gh_echec : deny"
assert_contains "gh a échoué" "$(raison "$out")" "gh_echec : raison"

reset; d=$(projet 1 '<!-- oc-gate: v0.3.0 validé 2026-12-18 sha:3f2a9c1 -->'); pr feat/0.3.0 $SHA_OK
gate "$d" "gh pr merge 81 -R o/r --squash" >/dev/null
assert_contains "pr view 81 -R o/r" "$(cat "$GH_STUB_LOG")" "numero_et_repo_transmis"
gate "$d" "cd x && gh pr merge --repo o/r" >/dev/null
assert_contains "pr view -R o/r" "$(cat "$GH_STUB_LOG")" "repo_long_sans_numero"

finish
