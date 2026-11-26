#!/usr/bin/env bash
# Scaffold de semver-repo-setup : génère les deux variantes (avec/sans Docker),
# vérifie l'absence de variables non remplacées, la validité YAML des pipelines et
# le registre d'exceptions de sécurité.
source "$(dirname "$0")/lib.sh"

SETUP="$REPO_ROOT/skills/semver-repo-setup"
SCAFFOLD="$SETUP/scripts/scaffold.py"
[ -f "$SCAFFOLD" ] && _ok || _ko "scaffold.py absent"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

gen() { # dest [--docker]
  python3 "$SCAFFOLD" --dest "$1" --namespace WillIsback --repo P9-demo \
    --title "Projet démo" --description "POC de démonstration" --author "William Derue" \
    --profile python-uv "${@:2}" >/dev/null 2>"$tmp/err"
}

for variant in nodocker docker; do
  dest="$tmp/$variant"; mkdir -p "$dest"
  if [ "$variant" = docker ]; then gen "$dest" --docker; else gen "$dest"; fi
  [ $? -eq 0 ] && _ok || _ko "$variant : scaffold échoue" "$(cat "$tmp/err")"

  # Aucune variable __NOM__ résiduelle (hors noms de package déjà substitués en chemins).
  leftover="$(grep -rlIE '__[A-Z][A-Z_]+__' "$dest" 2>/dev/null || true)"
  assert_empty "$leftover" "$variant : variables non remplacées"

  # Les fichiers de pipeline sont du YAML valide.
  if python3 -c 'import yaml' 2>/dev/null; then
    for f in "$dest/.gitlab-ci.yml" "$dest/.gitlab/ci/"*.yml; do
      if python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1],encoding='utf-8'))" "$f" 2>"$tmp/err"; then
        _ok; else _ko "$variant : YAML invalide $(basename "$f")" "$(cat "$tmp/err")"; fi
    done
  fi
done

# Le job image n'existe qu'en variante Docker ; docker-build de même.
grep -q '^image:' "$tmp/docker/.gitlab/ci/release.yml" && _ok || _ko "docker : job image absent"
grep -q '^image:' "$tmp/nodocker/.gitlab/ci/release.yml" && _ko "nodocker : job image présent" || _ok

# Registre d'exceptions de sécurité valide dans l'arbre généré.
if python3 -c 'import yaml' 2>/dev/null; then
  ( cd "$tmp/docker" && python3 -I scripts/ci/check_security_exceptions.py >/dev/null 2>&1 ) \
    && _ok || _ko "check_security_exceptions échoue dans l'arbre généré"
fi

finish
