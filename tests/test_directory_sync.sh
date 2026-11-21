#!/usr/bin/env bash
# Le sous-dossier directory/ (plugin publié au Claude directory) doit refléter
# exactement les skills 100 % Markdown de skills/ : copies conformes, aucun
# fichier restreint. Évite la dérive entre les deux emplacements.
source "$(dirname "$0")/lib.sh"

DIR="$REPO_ROOT/directory"

# 1. Skills « propres » à la racine = ceux sans aucun fichier non-Markdown.
propres=""
for d in "$REPO_ROOT"/skills/*/; do
  s="$(basename "$d")"
  if [ -z "$(find "$d" -type f ! -name '*.md')" ]; then propres="$propres $s"; fi
done

# 2. Chaque skill propre doit être présent dans directory/ et identique à la racine.
for s in $propres; do
  src="$REPO_ROOT/skills/$s/SKILL.md"
  dst="$DIR/skills/$s/SKILL.md"
  if [ ! -f "$dst" ]; then
    _ko "$s : skill propre absent de directory/skills/ (à mirrorer)"
  elif diff -q "$src" "$dst" >/dev/null 2>&1; then
    _ok
  else
    _ko "$s : directory/skills/$s/SKILL.md a dérivé de skills/$s/SKILL.md"
  fi
done

# 3. Chaque skill présent dans directory/ doit exister à la racine et ne contenir
#    aucun fichier restreint (sinon il faut une organisation Vérifiée).
if [ -d "$DIR/skills" ]; then
  for d in "$DIR"/skills/*/; do
    [ -d "$d" ] || continue
    s="$(basename "$d")"
    [ -d "$REPO_ROOT/skills/$s" ] && _ok || _ko "$s : dans directory/ mais absent de skills/"
    assert_empty "$(find "$d" -type f ! -name '*.md')" "$s : fichier non-Markdown dans directory/skills/$s"
  done
fi

# 4. L'icône du plugin directory doit être identique à celle de la racine.
if diff -q "$REPO_ROOT/.claude-plugin/icon.png" "$DIR/.claude-plugin/icon.png" >/dev/null 2>&1; then
  _ok
else
  _ko "icône : directory/.claude-plugin/icon.png diffère de .claude-plugin/icon.png"
fi

finish
