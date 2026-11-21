#!/usr/bin/env bash
# Petites assertions pour les tests bash du dépôt.
PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

_ok() { PASS=$((PASS + 1)); }
_ko() { FAIL=$((FAIL + 1)); printf '  ÉCHEC %s\n' "$1" >&2; [ -n "${2:-}" ] && printf '    %s\n' "$2" >&2; }

assert_eq() { # attendu obtenu nom
  if [ "$1" = "$2" ]; then _ok; else _ko "$3" "attendu « $1 », obtenu « $2 »"; fi
}
assert_contains() { # aiguille texte nom
  case "$2" in *"$1"*) _ok ;; *) _ko "$3" "« $1 » absent de « $2 »" ;; esac
}
assert_empty() { # texte nom
  if [ -z "$1" ]; then _ok; else _ko "$2" "sortie non vide : « $1 »"; fi
}
finish() {
  printf '%s : %d réussis, %d échecs\n' "$(basename "$0")" "$PASS" "$FAIL"
  [ "$FAIL" -eq 0 ]
}
