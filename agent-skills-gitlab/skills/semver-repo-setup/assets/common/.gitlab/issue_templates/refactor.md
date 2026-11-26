<!-- Modèle : Refactoring (sans changement fonctionnel). Titre au format « refactor: <résumé> ». -->

## Dette constatée
<!-- Problème identifié (lien fichier/ligne, complexité, duplication…). Ex. `src/module.py:42` — logique dupliquée. -->

## Objectif du refactoring
<!-- Résultat attendu en qualité. Ex. réduire la complexité, extraire la logique métier. -->

## Stratégie
<!-- strangler (remplacement progressif) / big-bang (une MR) / incrémental (plusieurs MR) -->

## Parité de comportement
<!-- Comment garantir que le comportement reste identique ? (tests existants, golden files, snapshots…) -->

## Plan de non-régression
- [ ] Tests unitaires des modules impactés
- [ ] Tests d'intégration (même couverture)
- [ ] Comparaison des sorties sur un jeu de données connu

## Scindable en plusieurs branches/MR ?
<!-- Non, une seule MR suffit / Oui, plusieurs branches/MR -->

/label ~"type::refactor"
