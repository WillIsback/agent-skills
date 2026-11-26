#!/usr/bin/env bash
# Réglages GitLab du workflow « lots de version semver ». Idempotent : chaque
# sous-commande peut être relancée sans effet de bord.
#
# Usage : gitlab-setup.sh -R <namespace>/<repo> <commande> [arguments]
#
#   project [--visibility V] [--description TXT]  crée le projet depuis le dossier courant (si
#                                                 absent), pousse main, règle fusion et sécurité
#                                                 (V = public | internal | private ; défaut public)
#   labels                                        labels type::* , semver::* , status::* , dependencies
#   variables KEY [KEY...]                        copie des clés de .env vers les variables CI/CD
#   milestones vX.Y.Z=AAAA-MM-JJ[=desc]…          crée ou met à jour les milestones (lots) datés
#   board                                         crée le board et ses listes à portée status::*
#   protect                                       protège main (MR obligatoire, pipeline requis,
#                                                 threads résolus, pas de push direct)
#   checks                                        affiche les jobs de .gitlab/ci/*.yml (pour info)
#
# Prérequis : glab authentifié (glab auth login) ou GITLAB_TOKEN, scopes api + write_repository.
set -euo pipefail

die() { echo "❌ $*" >&2; exit 1; }
REPO=""
if [ "${1:-}" = "-R" ]; then REPO="$2"; shift 2; fi
CMD="${1:-}"; shift || true
if [ -z "$REPO" ]; then
  REPO=$(glab repo view --output json 2>/dev/null | jq -r '.path_with_namespace // empty') \
    || die "projet inconnu : passer -R <namespace>/<repo>"
fi
[ -n "$REPO" ] || die "projet inconnu : passer -R <namespace>/<repo>"
NAMESPACE="${REPO%/*}"
# Identifiant projet encodé pour l'API (namespace/repo → namespace%2Frepo).
ENC="${REPO//\//%2F}"

api() { glab api "$@"; }

required_checks() {
  # Noms de jobs déclarés dans les fichiers de pipeline (hors clés réservées).
  grep -rhoE '^[a-zA-Z][a-zA-Z0-9_.-]*:' .gitlab/ci/*.yml 2>/dev/null \
    | sed 's/:$//' \
    | grep -vE '^(stages|variables|default|include|workflow|image|services|cache|rules|script|before_script|after_script|needs|artifacts|stage|tags|interruptible|timeout|release|coverage|dependencies|environment|resource_group|when|allow_failure)$' \
    | sort -u
}

label_upsert() { # name color description
  local name="$1" color="$2" desc="$3"
  if api "projects/$ENC/labels/${name//\//%2F}" >/dev/null 2>&1; then
    api -X PUT "projects/$ENC/labels/${name//\//%2F}" \
      -f "new_name=$name" -f "color=$color" -f "description=$desc" >/dev/null
  else
    api -X POST "projects/$ENC/labels" \
      -f "name=$name" -f "color=$color" -f "description=$desc" >/dev/null
  fi
}

cmd_project() {
  local visibility="public" description=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --visibility) visibility="$2"; shift ;;
      --description) description="$2"; shift ;;
      *) die "option inconnue : $1" ;;
    esac
    shift
  done
  if api "projects/$ENC" >/dev/null 2>&1; then
    echo "= projet $REPO déjà présent"
  else
    git rev-parse HEAD >/dev/null 2>&1 || die "aucun commit : faire un commit d'amorçage sur main d'abord"
    glab repo create "$REPO" --"$visibility" ${description:+--description "$description"} \
      --source . --remote origin --push
  fi
  # Fusion : squash encouragé, suppression de la branche source, fast-forward only.
  api -X PUT "projects/$ENC" \
    -f "squash_option=default_on" \
    -f "remove_source_branch_after_merge=true" \
    -f "only_allow_merge_if_pipeline_succeeds=true" \
    -f "only_allow_merge_if_all_discussions_are_resolved=true" \
    -f "merge_method=ff" \
    -f "wiki_enabled=false" >/dev/null
  echo "✅ projet $REPO configuré (visibilité $visibility)"
}

cmd_labels() {
  local l
  for l in "type::bug|#d73a4a|Comportement inattendu ou régression" \
           "type::feature|#a2eeef|Nouvelle fonctionnalité (user story)" \
           "type::refactor|#fbca04|Amélioration sans changement fonctionnel" \
           "type::docs|#0075ca|Documentation" \
           "type::chore|#c5def5|Maintenance, CI/CD, dépendances" \
           "type::test|#bfdadc|Tests" \
           "type::epic|#3e4b9e|Issue parente fonctionnelle (éléments enfants = user stories)" \
           "dependencies|#0366d6|Mise à jour de dépendances" \
           "status::planifié|#1d76db|Rattachée à un milestone = lot de version" \
           "status::en-cours|#fbca04|Sous-branche <type>/<version>-<tâche> ouverte" \
           "status::intégré|#8250df|Sous-branche fusionnée dans la branche de lot" \
           "semver::patch|#0e8a16|Lot patch" \
           "semver::minor|#1d76db|Lot minor" \
           "semver::major|#b60205|Lot major"; do
    IFS='|' read -r name color desc <<<"$l"
    label_upsert "$name" "$color" "$desc"
  done
  echo "✅ labels"
}

cmd_variables() {
  [ -f .env ] || die ".env introuvable"
  local key value
  for key in "$@"; do
    value=$(grep -E "^${key}=" .env | tail -1 | cut -d= -f2- | sed -E 's/^["'\'']//; s/["'\'']$//')
    [ -n "$value" ] || die "$key absent ou vide dans .env"
    # glab variable set : crée ou met à jour (masquée, non protégée par défaut).
    printf '%s' "$value" | glab variable set "$key" -R "$REPO" --masked 2>/dev/null \
      || glab variable set "$key" -R "$REPO" --value "$value" --masked
  done
  echo "✅ variables CI/CD : $*"
}

cmd_milestones() {
  local spec title due desc id
  for spec in "$@"; do
    IFS='=' read -r title due desc <<<"$spec"
    id=$(api "projects/$ENC/milestones?per_page=100&state=active" --jq ".[] | select(.title==\"$title\") | .id" 2>/dev/null | head -1)
    if [ -z "$id" ]; then
      api -X POST "projects/$ENC/milestones" -f "title=$title" -f "due_date=$due" \
        ${desc:+-f "description=$desc"} >/dev/null
      echo "+ milestone $title ($due)"
    else
      api -X PUT "projects/$ENC/milestones/$id" -f "due_date=$due" \
        ${desc:+-f "description=$desc"} >/dev/null
      echo "= milestone $title mis à jour ($due)"
    fi
  done
}

cmd_board() {
  # Board piloté par les labels à portée status::* (les créer d'abord avec « labels »).
  local board_id lid name
  board_id=$(api "projects/$ENC/boards" --jq '.[0].id' 2>/dev/null || true)
  if [ -z "$board_id" ] || [ "$board_id" = "null" ]; then
    board_id=$(api -X POST "projects/$ENC/boards" -f "name=Lots de version" --jq '.id')
    echo "+ board « Lots de version » (#$board_id)"
  else
    echo "= board #$board_id déjà présent"
  fi
  # Une liste par label status:: (ordre = flux kanban).
  for name in "status::planifié" "status::en-cours" "status::intégré"; do
    lid=$(api "projects/$ENC/labels/${name//\//%2F}" --jq '.id' 2>/dev/null || true)
    [ -n "$lid" ] && [ "$lid" != "null" ] || { echo "⚠️  label $name absent (lancer « labels »)"; continue; }
    api -X POST "projects/$ENC/boards/$board_id/lists" -f "label_id=$lid" >/dev/null 2>&1 \
      && echo "+ liste $name" || echo "= liste $name déjà présente"
  done
  echo "✅ board : $(api "projects/$ENC" --jq '.web_url')/-/boards"
}

cmd_protect() {
  # Pas de push direct sur main (push_access_level=0), fusion réservée aux mainteneurs.
  api -X DELETE "projects/$ENC/protected_branches/main" >/dev/null 2>&1 || true
  api -X POST "projects/$ENC/protected_branches" \
    -f "name=main" \
    -f "push_access_level=0" \
    -f "merge_access_level=40" \
    -f "allow_force_push=false" >/dev/null
  api -X PUT "projects/$ENC" \
    -f "only_allow_merge_if_pipeline_succeeds=true" \
    -f "only_allow_merge_if_all_discussions_are_resolved=true" >/dev/null
  echo "✅ main protégée — MR obligatoire, pipeline requis, threads résolus."
  echo "   Jobs du pipeline (doivent passer) :"; required_checks | sed 's/^/   - /'
}

case "$CMD" in
  project) cmd_project "$@" ;;
  labels) cmd_labels ;;
  variables) cmd_variables "$@" ;;
  milestones) cmd_milestones "$@" ;;
  board) cmd_board ;;
  protect) cmd_protect ;;
  checks) required_checks ;;
  *) sed -n '2,20p' "$0"; exit 1 ;;
esac
