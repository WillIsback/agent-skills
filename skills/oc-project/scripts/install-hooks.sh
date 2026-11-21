#!/usr/bin/env bash
# Installe les hooks Claude Code du skill oc-project dans settings.json :
#   - UserPromptSubmit → hooks/oc-trigger.sh (déclencheur OC / openclassroom)
#   - PreToolUse (Bash) → hooks/oc-merge-gate.sh (porte d'oral blanc)
# Idempotent, conserve les hooks et réglages existants, sauvegarde avant écriture.
# Usage : install-hooks.sh [--settings <chemin>]   (défaut : ~/.claude/settings.json)
set -euo pipefail

settings="$HOME/.claude/settings.json"
while [ $# -gt 0 ]; do
  case "$1" in
    --settings) settings="$2"; shift 2 ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) echo "Option inconnue : $1" >&2; exit 2 ;;
  esac
done

skill_dir="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
trigger="$skill_dir/hooks/oc-trigger.sh"
gate="$skill_dir/hooks/oc-merge-gate.sh"

mkdir -p "$(dirname "$settings")"
[ -f "$settings" ] || echo '{}' > "$settings"
jq -e . "$settings" >/dev/null || { echo "settings.json invalide : $settings" >&2; exit 1; }

a_deja() { # événement commande
  jq -e --arg e "$1" --arg c "$2" \
    '[.hooks[$e][]?.hooks[]?.command] | index($c) != null' "$settings" >/dev/null
}

ajouts=()
filtre='.'
if ! a_deja UserPromptSubmit "$trigger"; then
  filtre+=' | .hooks.UserPromptSubmit += [{hooks: [{type: "command", command: $t}]}]'
  ajouts+=("UserPromptSubmit → $trigger")
fi
if ! a_deja PreToolUse "$gate"; then
  filtre+=' | .hooks.PreToolUse += [{matcher: "Bash", hooks: [{type: "command", command: $g}]}]'
  ajouts+=("PreToolUse (Bash) → $gate")
fi

if [ ${#ajouts[@]} -eq 0 ]; then
  echo "Hooks oc-project déjà installés dans $settings."
  exit 0
fi

cp "$settings" "$settings.bak-oc"
tmp="$(mktemp "$(dirname "$settings")/.settings.XXXXXX")"
jq --arg t "$trigger" --arg g "$gate" "$filtre" "$settings" > "$tmp"
mv "$tmp" "$settings"
printf 'Ajouté dans %s :\n' "$settings"
printf '  - %s\n' "${ajouts[@]}"
echo "Sauvegarde : $settings.bak-oc"
