#!/usr/bin/env bash
# Le sous-dossier directory/ (plugin publié au Claude directory) est un
# sous-ensemble choisi des skills de skills/. Chaque skill qui y figure doit :
# être une copie conforme de celui de skills/, exister à la racine, et ne
# contenir aucun fichier restreint (sinon une organisation Vérifiée est requise).
# L'inclusion est volontaire : un skill propre peut rester hors de directory/.
source "$(dirname "$0")/lib.sh"

DIR="$REPO_ROOT/directory"

if [ ! -d "$DIR/skills" ]; then
  _ko "directory/skills absent"
  finish
  exit
fi

for d in "$DIR"/skills/*/; do
  [ -d "$d" ] || continue
  s="$(basename "$d")"

  # 1. Le skill doit exister à la racine.
  if [ -d "$REPO_ROOT/skills/$s" ]; then _ok; else _ko "$s : dans directory/ mais absent de skills/"; continue; fi

  # 2. SKILL.md identique à la racine (anti-dérive).
  if diff -q "$REPO_ROOT/skills/$s/SKILL.md" "$d/SKILL.md" >/dev/null 2>&1; then _ok; else _ko "$s : directory/skills/$s/SKILL.md a dérivé de skills/$s/SKILL.md"; fi

  # 3. Aucun fichier non-Markdown dans la copie directory/.
  assert_empty "$(find "$d" -type f ! -name '*.md')" "$s : fichier non-Markdown dans directory/skills/$s"

  # 4. Le skill racine lui-même doit être 100 % Markdown : un skill à scripts
  #    n'a rien à faire dans directory/ sans organisation Vérifiée.
  assert_empty "$(find "$REPO_ROOT/skills/$s" -type f ! -name '*.md')" "$s : skill restreint, à retirer de directory/ (org Vérifiée requise)"
done

# 5. L'icône du plugin directory doit être identique à celle de la racine.
if diff -q "$REPO_ROOT/.claude-plugin/icon.png" "$DIR/.claude-plugin/icon.png" >/dev/null 2>&1; then
  _ok
else
  _ko "icône : directory/.claude-plugin/icon.png diffère de .claude-plugin/icon.png"
fi

finish
