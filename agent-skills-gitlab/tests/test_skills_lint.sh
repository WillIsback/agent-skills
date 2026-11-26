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
  # Un préfixe « <autre-skill>/ » désigne un fichier d'un autre skill du dépôt.
  while IFS= read -r ref; do
    prefixe="${ref%%/*}"
    if [ -d "$REPO_ROOT/skills/$prefixe" ] && [[ "$ref" == "$prefixe"/references/* || "$ref" == "$prefixe"/assets/* ]]; then
      cible="$REPO_ROOT/skills/$ref"
    else
      cible="$dir/${ref#*/}"; [[ "$ref" == references/* || "$ref" == assets/* ]] && cible="$dir/$ref"
    fi
    [ -e "$cible" ] && _ok || _ko "$nom : $ref cité mais absent"
  done < <(grep -rhoE '([a-z0-9-]+/)?(references|assets)/[A-Za-z0-9_.-]+\.(md|sh|json)' "$dir" | sort -u)
  if grep -rqE '\b(TODO|TBD)\b' "$dir"; then _ko "$nom : contient TODO ou TBD"; else _ok; fi
done

finish
