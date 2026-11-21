#!/usr/bin/env bash
# Lance tous les tests du dépôt ; code de sortie non nul si l'un échoue.
cd "$(dirname "$0")" || exit 1
status=0
for t in test_*.sh; do
  bash "$t" || status=1
done
exit "$status"
