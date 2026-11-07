#!/usr/bin/env bash
# Réglages GitHub du workflow « lots de version semver ». Idempotent : chaque
# sous-commande peut être relancée sans effet de bord.
#
# Usage : github-setup.sh -R <owner>/<repo> <commande> [arguments]
#
#   repo [--private] [--description TXT]  crée le dépôt depuis le dossier courant (si absent),
#                                         pousse main, règle les options de fusion et la sécurité
#   labels                                labels type:* , semver:* , dependencies
#   secrets KEY [KEY...]                  copie des clés de .env vers les secrets du dépôt
#   milestones vX.Y.Z=AAAA-MM-JJ[=desc]…  crée ou met à jour les milestones (lots) datés
#   project "Titre"                       crée le Project (si absent), le lie, configure Status ;
#                                         affiche son numéro sur la dernière ligne
#   protect                               protège main avec les jobs « ci-* » des workflows
#   checks                                affiche les checks requis déduits des workflows
#
# Prérequis : gh authentifié avec les scopes repo, workflow et project
#   (gh auth refresh -h github.com -s project).
set -euo pipefail

die() { echo "❌ $*" >&2; exit 1; }
REPO=""
if [ "${1:-}" = "-R" ]; then REPO="$2"; shift 2; fi
CMD="${1:-}"; shift || true
[ -n "$REPO" ] || REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null) \
  || die "dépôt inconnu : passer -R <owner>/<repo>"
OWNER="${REPO%%/*}"

required_checks() {
  # Noms des jobs (indentation 4) commençant par « ci- » dans les workflows.
  grep -hE '^    name: ci-' .github/workflows/*.yml | sed -E 's/^    name: //; s/[[:space:]]+$//' | sort -u
}

cmd_repo() {
  local visibility="--public" description=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --private) visibility="--private" ;;
      --description) description="$2"; shift ;;
      *) die "option inconnue : $1" ;;
    esac
    shift
  done
  if gh repo view "$REPO" >/dev/null 2>&1; then
    echo "= dépôt $REPO déjà présent"
  else
    git rev-parse HEAD >/dev/null 2>&1 || die "aucun commit : faire un commit d'amorçage sur main d'abord"
    gh repo create "$REPO" "$visibility" ${description:+--description "$description"} \
      --source . --remote origin --push
  fi
  gh repo edit "$REPO" --enable-auto-merge --delete-branch-on-merge --enable-squash-merge \
    --enable-merge-commit --enable-rebase-merge=false --enable-wiki=false >/dev/null
  gh api -X PUT "repos/$REPO/vulnerability-alerts" >/dev/null
  gh api -X PATCH "repos/$REPO" -f 'security_and_analysis[dependabot_security_updates][status]=enabled' >/dev/null \
    || echo "⚠️  mises à jour de sécurité Dependabot non activées (plan ou visibilité)"
  if [ "$visibility" = "--private" ]; then
    echo "⚠️  Dépôt privé sur un plan gratuit : protection de branche, CodeQL et Dependency Review"
    echo "    ne sont pas disponibles — adapter les gates (voir SKILL.md)."
  fi
  echo "✅ dépôt $REPO configuré"
}

cmd_labels() {
  local l
  for l in "type:bug|d73a4a|Comportement inattendu ou régression" \
           "type:feature|a2eeef|Nouvelle fonctionnalité (user story)" \
           "type:refactor|fbca04|Amélioration sans changement fonctionnel" \
           "type:docs|0075ca|Documentation" \
           "type:chore|c5def5|Maintenance, CI/CD, dépendances" \
           "type:test|bfdadc|Tests" \
           "type:epic|3e4b9e|Issue parente fonctionnelle (sous-issues = user stories)" \
           "dependencies|0366d6|Mise à jour de dépendances" \
           "semver:patch|0e8a16|Lot patch" "semver:minor|1d76db|Lot minor" "semver:major|b60205|Lot major"; do
    IFS='|' read -r name color desc <<<"$l"
    gh label create "$name" --color "$color" --description "$desc" -R "$REPO" --force >/dev/null
  done
  echo "✅ labels"
}

cmd_secrets() {
  [ -f .env ] || die ".env introuvable"
  local key value
  for key in "$@"; do
    value=$(grep -E "^${key}=" .env | tail -1 | cut -d= -f2- | sed -E 's/^["'\'']//; s/["'\'']$//')
    [ -n "$value" ] || die "$key absent ou vide dans .env"
    printf '%s' "$value" | gh secret set "$key" -R "$REPO"
  done
  echo "✅ secrets : $*"
}

cmd_milestones() {
  local spec title due desc number
  for spec in "$@"; do
    IFS='=' read -r title due desc <<<"$spec"
    number=$(gh api "repos/$REPO/milestones?state=all&per_page=100" \
      --jq ".[] | select(.title==\"$title\") | .number")
    if [ -z "$number" ]; then
      gh api "repos/$REPO/milestones" -f title="$title" -f due_on="${due}T23:59:59Z" \
        ${desc:+-f description="$desc"} >/dev/null
      echo "+ milestone $title ($due)"
    else
      gh api -X PATCH "repos/$REPO/milestones/$number" -f due_on="${due}T23:59:59Z" \
        ${desc:+-f description="$desc"} >/dev/null
      echo "= milestone $title mis à jour ($due)"
    fi
  done
}

cmd_project() {
  local title="${1:?titre du Project requis}" number field_id
  number=$(gh project list --owner "$OWNER" --format json --limit 200 \
    --jq ".projects[] | select(.title==\"$title\") | .number" | head -1)
  if [ -z "$number" ]; then
    number=$(gh project create --owner "$OWNER" --title "$title" --format json --jq .number)
    echo "+ project #$number « $title »"
  else
    echo "= project #$number « $title » déjà présent"
  fi
  gh project link "$number" --owner "$OWNER" --repo "$REPO" >/dev/null 2>&1 || true
  field_id=$(gh project field-list "$number" --owner "$OWNER" --format json \
    --jq '.fields[] | select(.name=="Status") | .id')
  local current
  current=$(gh project field-list "$number" --owner "$OWNER" --format json \
    --jq '[.fields[] | select(.name=="Status") | .options[].name] | join("|")')
  if [ "$current" != "Backlog|Planifié|En cours|Intégré au lot|Fait" ]; then
    # Remplacer les options réinitialise le Status des items existants.
    # shellcheck disable=SC2016 # variables GraphQL, pas shell
    gh api graphql -f f="$field_id" -f query='
      mutation($f: ID!) { updateProjectV2Field(input: { fieldId: $f, singleSelectOptions: [
        { name: "Backlog", color: GRAY, description: "Issue créée, sans milestone" },
        { name: "Planifié", color: BLUE, description: "Rattachée à un milestone = lot de version" },
        { name: "En cours", color: YELLOW, description: "Sous-branche <type>/<version>-<tâche> ouverte" },
        { name: "Intégré au lot", color: PURPLE, description: "Sous-branche fusionnée dans la branche de lot" },
        { name: "Fait", color: GREEN, description: "PR de lot fusionnée sur main, issue fermée" }
      ] }) { projectV2Field { ... on ProjectV2SingleSelectField { id } } } }' >/dev/null
    echo "+ colonnes Status configurées"
  fi
  echo "✅ project https://github.com/users/$OWNER/projects/$number"
  echo "$number"
}

cmd_protect() {
  local checks payload
  checks=$(required_checks)
  [ -n "$checks" ] || die "aucun job « ci-* » trouvé dans .github/workflows"
  payload=$(jq -n --arg c "$checks" '{
    required_status_checks: { strict: false, contexts: ($c | split("\n")) },
    enforce_admins: true, required_pull_request_reviews: null, restrictions: null,
    required_linear_history: false, allow_force_pushes: false, allow_deletions: false,
    required_conversation_resolution: true }')
  printf '%s' "$payload" | gh api -X PUT "repos/$REPO/branches/main/protection" --input - >/dev/null
  echo "✅ main protégée — checks requis :"; sed 's/^/   - /' <<<"$checks"
}

case "$CMD" in
  repo) cmd_repo "$@" ;;
  labels) cmd_labels ;;
  secrets) cmd_secrets "$@" ;;
  milestones) cmd_milestones "$@" ;;
  project) cmd_project "$@" ;;
  protect) cmd_protect ;;
  checks) required_checks ;;
  *) sed -n '2,19p' "$0"; exit 1 ;;
esac
