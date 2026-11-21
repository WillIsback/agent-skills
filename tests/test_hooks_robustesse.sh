#!/usr/bin/env bash
# Un hook cassé bloque toutes les commandes (bash sort en 2 sur erreur de syntaxe,
# code que Claude Code lit comme un refus) : vérifier syntaxe et sorties inattendues.
source "$(dirname "$0")/lib.sh"
HOOKS="$REPO_ROOT/skills/oc-project/hooks"

for h in "$HOOKS"/*.sh "$REPO_ROOT"/skills/oc-project/scripts/*.sh; do
  bash -n "$h" 2>/dev/null && _ok || _ko "syntaxe : $(basename "$h")"
done

for h in "$HOOKS"/*.sh; do
  for entree in '' 'pas du json' '{}' '{"tool_name":"Bash","tool_input":{"command":"ls"},"cwd":"/tmp"}'; do
    printf '%s' "$entree" | bash "$h" >/dev/null 2>&1
    assert_eq 0 $? "$(basename "$h") sort en 0 sur « $entree »"
  done
done

# Sans jq : la porte bloque une fusion (sortie 2), laisse passer le reste.
bin="$(mktemp -d)"
for c in bash cat grep dirname tr wc sed head mktemp rm git python3; do
  p="$(command -v "$c")" && ln -s "$p" "$bin/$c"
done
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"gh pr merge 3"},"cwd":"/tmp"}' | PATH="$bin" bash "$HOOKS/oc-merge-gate.sh" >/dev/null 2>&1
assert_eq 2 $? "sans jq : fusion bloquée"
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"ls"},"cwd":"/tmp"}' | PATH="$bin" bash "$HOOKS/oc-merge-gate.sh" >/dev/null 2>&1
assert_eq 0 $? "sans jq : commande ordinaire autorisée"

finish
