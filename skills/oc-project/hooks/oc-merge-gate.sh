#!/usr/bin/env bash
# Hook PreToolUse (Bash) : porte d'oral blanc des projets OpenClassrooms.
#
# Dans un projet OC (dossier, sous-dossier ou worktree d'un dépôt dont la racine
# contient .oc/state.md), refuse :
#   - « gh pr merge » sur une PR de lot (<type>/X.Y.Z vers main) ou de specs
#     (docs/X.Y.Z-specs) tant que .oc/carnet.md ne contient pas, pour cette porte,
#     une ligne « oc-gate: <id> validé <date> sha:<7 car.> » dont le SHA est celui
#     de la tête actuelle de la PR ;
#   - toute fusion par « gh api » (REST pulls/N/merge ou GraphQL mergePullRequest) ;
#   - « --auto » (la fusion différée porterait sur des commits non vus à l'oral) ;
#   - plusieurs « gh pr merge » dans une même commande.
# Dans le doute (gh, jq ou python3 en échec, PR illisible), la porte refuse.
set -u

CONSIGNE="Ne jamais contourner ce refus (gh api, autre forme de commande) : lancer oc-oral-blanc."

if ! command -v jq >/dev/null 2>&1; then
  # Sans jq, impossible de lire l'entrée : bloquer tout ce qui ressemble à une fusion.
  if grep -qiE 'merge' 2>/dev/null; then
    echo "Porte d'oral blanc : jq est absent, fusion bloquée par précaution. Installer jq." >&2
    exit 2
  fi
  exit 0
fi

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

normal="$(printf '%s' "$commande" | tr -s ' \t\n' '   ')"
nb_merge="$(printf '%s' "$normal" | grep -oE 'gh pr merge' | wc -l)"
api_merge=0
if [[ "$normal" == *"gh api"* ]] && printf '%s' "$normal" | grep -qE 'pulls/[0-9]+/merge|mergePullRequest'; then
  api_merge=1
fi
[ "$nb_merge" -gt 0 ] || [ "$api_merge" -eq 1 ] || exit 0

# Dossier de départ : un « cd <chemin> » placé avant la fusion l'emporte sur le cwd.
depart="$dossier"
re_cd='(^|[;&|][[:space:]]*)cd[[:space:]]+([^;&|[:space:]]+)[[:space:]]*(&&|;)[^;]*(gh pr merge|gh api)'
if [[ "$normal" =~ $re_cd ]]; then
  cible_cd="${BASH_REMATCH[2]}"
  case "$cible_cd" in
    /*) depart="$cible_cd" ;;
    *) depart="$dossier/$cible_cd" ;;
  esac
fi

# Racine du projet OC : remonter jusqu'à .oc/state.md, puis essayer le worktree principal.
racine=""
d="$depart"
while [ -n "$d" ] && [ "$d" != "/" ]; do
  if [ -f "$d/.oc/state.md" ]; then racine="$d"; break; fi
  d="$(dirname "$d")"
done
if [ -z "$racine" ] && [ -d "$depart" ]; then
  commun="$(git -C "$depart" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  if [ -n "$commun" ] && [ -f "$(dirname "$commun")/.oc/state.md" ]; then
    racine="$(dirname "$commun")"
  fi
fi
[ -n "$racine" ] || exit 0

if [ "$api_merge" -eq 1 ]; then
  refuser "Porte d'oral blanc : fusion par gh api interdite dans un projet OC. Utiliser gh pr merge une fois l'oral blanc validé. $CONSIGNE"
fi
if [ "$nb_merge" -gt 1 ]; then
  refuser "Porte d'oral blanc : une seule fusion par commande (gh pr merge apparaît $nb_merge fois)."
fi

# Analyse des arguments de « gh pr merge » (guillemets compris).
if ! command -v python3 >/dev/null 2>&1; then
  refuser "Porte d'oral blanc : python3 est absent, impossible d'identifier la PR. Fusion bloquée par précaution."
fi
analyse="$(printf '%s' "$commande" | python3 -c '
import re, shlex, sys
s = sys.stdin.read()
try:
    toks = shlex.split(s, posix=True)
except ValueError:
    print("ERREUR"); sys.exit(0)
i = next((k for k in range(len(toks) - 2) if toks[k:k+3] == ["gh", "pr", "merge"]), None)
if i is None:
    print("ERREUR"); sys.exit(0)
avec_valeur = {"-t", "--subject", "-b", "--body", "-F", "--body-file", "-A",
               "--author-email", "--match-head-commit", "-R", "--repo"}
cible, repo, auto = "", "", 0
k = i + 3
while k < len(toks):
    t = toks[k]
    if t in {"&&", "||", ";", "|"} or t.endswith(";"):
        break
    if t == "--auto":
        auto = 1
    elif t in avec_valeur:
        if t in {"-R", "--repo"} and k + 1 < len(toks):
            repo = toks[k + 1]
        k += 1
    elif t.startswith("--repo="):
        repo = t.split("=", 1)[1]
    elif t.startswith("-"):
        pass
    elif not cible:
        m = re.search(r"/pull/([0-9]+)", t)
        cible = m.group(1) if m else t
    k += 1
print(f"{cible}|{repo}|{auto}")
')"
[ "$analyse" != "ERREUR" ] || refuser "Porte d'oral blanc : commande gh pr merge illisible, PR non identifiable. Fusion bloquée par précaution."
IFS="|" read -r cible repo auto <<< "$analyse"

if [ "$auto" = "1" ]; then
  refuser "Porte d'oral blanc : --auto est interdit dans un projet OC (GitHub fusionnerait plus tard des commits non vus à l'oral). Fusionner sans --auto une fois l'oral validé."
fi

args=(pr view)
[ -n "$cible" ] && args+=("$cible")
[ -n "$repo" ] && args+=(-R "$repo")
args+=(--json headRefName,headRefOid,baseRefName)

erreurs="$(mktemp)"
[ -d "$depart" ] || depart="$racine"
if ! infos="$(cd "$depart" 2>/dev/null && gh "${args[@]}" 2>"$erreurs")"; then
  msg="$(head -c 300 "$erreurs" | tr '\n' ' ')"; rm -f "$erreurs"
  refuser "Porte d'oral blanc : impossible de lire la PR (gh a échoué : ${msg:-sans message}). Vérifier gh puis relancer."
fi
rm -f "$erreurs"
tete="$(printf '%s' "$infos" | jq -r '.headRefName // ""' 2>/dev/null)"
sha="$(printf '%s' "$infos" | jq -r '.headRefOid // ""' 2>/dev/null)"
base="$(printf '%s' "$infos" | jq -r '.baseRefName // ""' 2>/dev/null)"
if [ -z "$tete" ] || [ -z "$sha" ]; then
  refuser "Porte d'oral blanc : réponse de gh incomplète (branche ou SHA de tête absents). Fusion bloquée par précaution."
fi

if [[ "$tete" =~ ^docs/[0-9]+\.[0-9]+\.[0-9]+-specs$ ]]; then
  id="specs"
elif [[ "$tete" =~ ^[a-z]+/([0-9]+\.[0-9]+\.[0-9]+)$ ]] && [ "$base" = "main" ]; then
  id="v${BASH_REMATCH[1]}"
else
  exit 0
fi

court="${sha:0:7}"
valide=""
if [ -f "$racine/.oc/carnet.md" ]; then
  id_regex="${id//./\\.}"
  valide="$(grep -oE "oc-gate: ${id_regex} validé [0-9-]+ sha:[0-9a-f]{7}" "$racine/.oc/carnet.md" \
    | tail -n 1 | sed -E 's/.*sha:([0-9a-f]{7})$/\1/')"
fi

if [ "$valide" != "$court" ]; then
  refuser "Porte d'oral blanc non validée pour ${id} (SHA de tête ${court}) : lancer oc-oral-blanc sur cette PR avant de fusionner. $CONSIGNE"
fi
exit 0
