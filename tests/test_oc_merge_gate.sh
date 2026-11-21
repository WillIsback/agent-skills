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

# --- Correctifs de la revue finale ---
reset(){ unset GH_STUB_EXIT GH_STUB_JSON_ARG; export GH_STUB_LOG; GH_STUB_LOG="$(mktemp)"; }
lot_non_valide='{"headRefName":"feat/0.4.0","headRefOid":"4444444aaaa","baseRefName":"main"}'

# C1 : cwd dans un sous-dossier du projet
reset; d=$(projet 1); mkdir -p "$d/apps/api"; pr feat/0.3.0 $SHA_OK
assert_eq deny "$(decision "$(gate "$d/apps/api" "gh pr merge 12")")" "sous_dossier : porte appliquée"
# C1 : « cd <projet> && gh pr merge » depuis ailleurs
reset; d=$(projet 1); pr feat/0.3.0 $SHA_OK
assert_eq deny "$(decision "$(gate /tmp "cd $d && gh pr merge 12")")" "cd_prefixe : porte appliquée"
# C1 : worktree git (sans .oc/) du projet principal
reset; d=$(projet 1); ( cd "$d" && git init -q -b main && printf '.oc/\n' > .gitignore && git add .gitignore && git -c user.email=t@t -c user.name=t commit -qm init && git worktree add -q "$d-wt" -b feat/0.3.0 ) >/dev/null 2>&1
pr feat/0.3.0 $SHA_OK
assert_eq deny "$(decision "$(gate "$d-wt" "gh pr merge 12")")" "worktree : porte appliquée"

# C2 : la PR fusionnée est celle désignée, même après des options
reset; d=$(projet 1 '<!-- oc-gate: v0.3.0 validé 2026-12-18 sha:3f2a9c1 -->'); pr chore/outillage $SHA_OK
export GH_STUB_JSON_ARG="$lot_non_valide"
assert_eq deny "$(decision "$(gate "$d" "gh pr merge --squash 14")")" "options_avant_numero"
assert_contains "pr view 14" "$(cat "$GH_STUB_LOG")" "options_avant_numero : PR 14 lue"
assert_eq deny "$(decision "$(gate "$d" "gh pr merge -s -d -t 'titre long' 14")")" "option_avec_valeur"
assert_eq deny "$(decision "$(gate "$d" "gh pr merge https://github.com/o/r/pull/14 --squash")")" "url"
assert_contains "pr view 14" "$(tail -n1 "$GH_STUB_LOG")" "url : numéro extrait"
assert_eq deny "$(decision "$(gate "$d" "gh pr merge feat/0.4.0")")" "nom_de_branche"
assert_contains "pr view feat/0.4.0" "$(tail -n1 "$GH_STUB_LOG")" "nom_de_branche : transmis"
out=$(gate "$d" "gh pr merge 3 && gh pr merge 12")
assert_eq deny "$(decision "$out")" "deux_merges : refus"
assert_contains "une seule" "$(raison "$out")" "deux_merges : raison"

# I3 : autres formes
reset; d=$(projet 1); pr feat/0.3.0 $SHA_OK
assert_eq deny "$(decision "$(gate "$d" "gh  pr   merge 12")")" "espaces_multiples"
assert_eq deny "$(decision "$(gate "$d" "gh api -X PUT repos/o/r/pulls/12/merge")")" "gh_api_merge"
assert_eq deny "$(decision "$(gate "$d" "gh api graphql -f query='mutation { mergePullRequest(input:{}) { clientMutationId } }'")")" "gh_api_graphql"
assert_empty "$(gate "$d" "gh api repos/o/r/pulls/12")" "gh_api_lecture_autorisee"

# I4 : --auto refusé même porte validée
reset; d=$(projet 1 '<!-- oc-gate: v0.3.0 validé 2026-12-18 sha:3f2a9c1 -->'); pr feat/0.3.0 $SHA_OK
out=$(gate "$d" "gh pr merge 12 --auto --squash")
assert_eq deny "$(decision "$out")" "auto_refuse"
assert_contains "--auto" "$(raison "$out")" "auto_refuse : raison"

# I5 : tout lot <type>/X.Y.Z vers main est soumis à la porte
reset; d=$(projet 1); pr docs/0.5.0 $SHA_OK
assert_eq deny "$(decision "$(gate "$d" "gh pr merge 20")")" "lot_docs_soumis"
pr chore/0.5.1 $SHA_OK
assert_eq deny "$(decision "$(gate "$d" "gh pr merge 21")")" "lot_chore_soumis"

# Regrade : JSON de gh sans headRefName → refus (pas d'exemption silencieuse)
reset; d=$(projet 1); export GH_STUB_JSON='{"message":"Not Found"}'
assert_eq deny "$(decision "$(gate "$d" "gh pr merge 12")")" "json_incomplet_refuse"
# Regrade : erreur de gh reprise dans la raison
reset; d=$(projet 1); export GH_STUB_EXIT=1
assert_contains "erreur simulée" "$(raison "$(gate "$d" "gh pr merge 12")")" "erreur_gh_dans_raison"

finish
