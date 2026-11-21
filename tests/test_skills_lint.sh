#!/usr/bin/env bash
# Structure de tous les skills du dépôt.
source "$(dirname "$0")/lib.sh"

for d in "$REPO_ROOT"/skills/*/; do
  [ -f "$d/SKILL.md" ] && _ok || _ko "$(basename "$d") : SKILL.md absent"
done

for skill_md in "$REPO_ROOT"/skills/*/SKILL.md; do
  dir="$(dirname "$skill_md")"; nom="$(basename "$dir")"
  if [ "$(head -n1 "$skill_md")" = "---" ]; then _ok; else _ko "$nom : frontmatter absent"; continue; fi
  fm="$(awk 'NR==1{next} /^---$/{exit} {print}' "$skill_md")"
  name="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -n1)"
  desc="$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p' | head -n1)"
  assert_eq "$nom" "$name" "$nom : name = nom du dossier"
  [ -n "$desc" ] && _ok || _ko "$nom : description vide"
  len="$(printf '%s' "$desc" | wc -m)"
  [ "$len" -le 1024 ] && _ok || _ko "$nom : description trop longue ($len > 1024)"
  # Chemins references/… et assets/… cités dans le skill : ils doivent exister.
  while IFS= read -r chemin; do
    [ -e "$dir/$chemin" ] && _ok || _ko "$nom : $chemin cité mais absent"
  done < <(grep -rhoE '(references|assets)/[A-Za-z0-9_.-]+\.(md|sh|json)' "$dir" | sort -u)
  if grep -rqE '\b(TODO|TBD)\b' "$dir"; then _ko "$nom : contient TODO ou TBD"; else _ok; fi
done

finish
