#!/usr/bin/env bash
# Hook PreToolUse (Bash) : porte d'oral blanc. Refuse « gh pr merge » sur une PR
# de lot (feat|fix|perf|major/X.Y.Z vers main) ou de specs (docs/X.Y.Z-specs)
# tant que .oc/carnet.md ne contient pas, pour cette porte, une ligne
#   oc-gate: <id> validé <date> sha:<7 car.>
# dont le SHA est celui de la tête actuelle de la PR. Hors projet OC
# (pas de .oc/state.md) ou hors PR soumise à la porte : laisse passer.
set -u

entree="$(cat)"
outil="$(printf '%s' "$entree" | jq -r '.tool_name // ""' 2>/dev/null)"
commande="$(printf '%s' "$entree" | jq -r '.tool_input.command // ""' 2>/dev/null)"
dossier="$(printf '%s' "$entree" | jq -r '.cwd // ""' 2>/dev/null)"
[ -n "$dossier" ] || dossier="$PWD"

refuser() {
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

[ "$outil" = "Bash" ] || exit 0
[[ "$commande" == *"gh pr merge"* ]] || exit 0
[ -f "$dossier/.oc/state.md" ] || exit 0

args=(pr view)
if [[ "$commande" =~ gh\ pr\ merge[[:space:]]+([0-9]+) ]]; then
  args+=("${BASH_REMATCH[1]}")
fi
if [[ "$commande" =~ (-R|--repo)[[:space:]=]+([^[:space:]]+) ]]; then
  args+=(-R "${BASH_REMATCH[2]}")
fi
args+=(--json headRefName,headRefOid,baseRefName)

if ! infos="$(cd "$dossier" && gh "${args[@]}" 2>/dev/null)"; then
  refuser "Porte d'oral blanc : impossible de lire la PR (gh a échoué). Vérifier gh puis relancer."
fi
tete="$(printf '%s' "$infos" | jq -r '.headRefName // ""' 2>/dev/null)"
sha="$(printf '%s' "$infos" | jq -r '.headRefOid // ""' 2>/dev/null)"
base="$(printf '%s' "$infos" | jq -r '.baseRefName // ""' 2>/dev/null)"

if [[ "$tete" =~ ^(feat|fix|perf|major)/([0-9]+\.[0-9]+\.[0-9]+)$ ]] && [ "$base" = "main" ]; then
  id="v${BASH_REMATCH[2]}"
elif [[ "$tete" =~ ^docs/[0-9]+\.[0-9]+\.[0-9]+-specs$ ]]; then
  id="specs"
else
  exit 0
fi

court="${sha:0:7}"
valide=""
if [ -f "$dossier/.oc/carnet.md" ]; then
  id_regex="${id//./\\.}"
  valide="$(grep -oE "oc-gate: ${id_regex} validé [0-9-]+ sha:[0-9a-f]{7}" "$dossier/.oc/carnet.md" \
    | tail -n 1 | sed -E 's/.*sha:([0-9a-f]{7})$/\1/')"
fi

if [ -z "$court" ] || [ "$valide" != "$court" ]; then
  refuser "Porte d'oral blanc non validée pour ${id} (SHA de tête ${court:-inconnu}) : lancer oc-oral-blanc sur cette PR avant de fusionner."
fi
exit 0
