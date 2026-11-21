#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
HOOK="$REPO_ROOT/skills/oc-project/hooks/oc-trigger.sh"

run_trigger() { jq -n --arg p "$1" '{prompt:$p}' | bash "$HOOK" 2>/dev/null; }

for p in "OC P8" "on avance sur le projet OC" "(OC) cadrage" "OC: reprends" \
         "projet OpenClassrooms" "openclassroom" "OPENCLASSROOMS"; do
  assert_contains "oc-project" "$(run_trigger "$p")" "positif : $p"
done

for p in "OCR du PDF" "mets à jour la doc" "Oc" "un bloc de code" \
         "https://example.com/oc/page" "https://example.com/OC/page" "OCaml" ""; do
  assert_empty "$(run_trigger "$p")" "négatif : $p"
done

out="$(run_trigger "OC P8")"
if printf '%s' "$out" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then _ok; else _ko "JSON valide" "$out"; fi
assert_eq "UserPromptSubmit" "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.hookEventName' 2>/dev/null)" "hookEventName"

bash "$HOOK" </dev/null >/dev/null 2>&1; assert_eq 0 $? "code de sortie 0 sur entrée vide"

finish
