#!/usr/bin/env bash
# Syntaxe des scripts fournis par les skills (bash -n, python compile).
source "$(dirname "$0")/lib.sh"

while IFS= read -r sh; do
  if bash -n "$sh" 2>/tmp/err; then _ok; else _ko "bash -n $sh" "$(cat /tmp/err)"; fi
done < <(find "$REPO_ROOT/skills" "$REPO_ROOT/tests" -name '*.sh')

while IFS= read -r py; do
  # ast.parse : vérifie la syntaxe sans écrire de bytecode (__pycache__).
  if python3 -c "import ast,sys; ast.parse(open(sys.argv[1],encoding='utf-8').read())" "$py" 2>/tmp/err; then
    _ok; else _ko "syntaxe $py" "$(cat /tmp/err)"; fi
done < <(find "$REPO_ROOT/skills" -name '*.py')

finish
