# Phase 3 — Livraison lot par lot

But : livrer le projet lot par lot selon le skill `semver-batch-workflow` (branche de lot,
sous-branches par user story, une PR vers `main`, release automatique), sans jamais
fusionner un lot que William ne sait pas défendre.

## Boucle d'un lot

1. **Annoncer le lot** (`lot:` de `.oc/state.md`, milestone du board) : user stories,
   indicateurs de la fiche visés, parts 👤 de chacune.
2. **Parts 🤖** : l'agent code, teste et documente, sous-branche par sous-branche, en
   suivant `semver-batch-workflow` (et la TDD quand il y a du code).
3. **Parts 👤** : l'agent **ne les fait pas**. Il prépare le terrain, explique les notions,
   guide pas à pas et relit ce que William produit. Exemples : choisir les cas de test
   critiques, fixer un seuil d'alerte, lancer soi-même `docker build` puis `docker run`,
   interpréter un rapport, écrire une règle de validation. Une part 👤 non faite bloque
   le lot.
4. **PR du lot vers `main`** : CI au vert, corps de PR selon le modèle du dépôt. William
   relit le diff.
5. **Oral blanc** : invoquer le skill `oc-oral-blanc` sur la PR (identifiant de porte
   `v<X.Y.Z>`). Il écrit l'entrée du lot dans `.oc/carnet.md` et, si tout est maîtrisé,
   la ligne `oc-gate`.
6. **Fusion** à la demande de William uniquement.

## Règle de porte (avec ou sans hook)

**Ne jamais lancer `gh pr merge` sur une PR de lot sans une ligne
`oc-gate: v<X.Y.Z> validé <date> sha:<7 car.>` dans `.oc/carnet.md` dont le SHA est
celui de la tête actuelle de la PR** (`gh pr view <n> --json headRefOid`). Si un commit a
été poussé après l'oral, refaire un oral court sur ce qui a changé. Le hook
`oc-merge-gate.sh` l'impose sous Claude Code ; ailleurs, la règle reste la même.

## Après la fusion

- Vérifier que la release est sortie (`gh release list`, et l'artefact publié : image,
  Pages, paquet) ; signaler tout échec plutôt que le taire.
- `.oc/state.md` : `lot:` = lot suivant du board, ligne de journal.
- Reporter les « Notes pour la fiche » du carnet dans la fiche d'auto-évaluation si
  William la tient à jour au fil de l'eau.

## Fin de phase

Quand le dernier lot est fusionné et que tous les indicateurs de la matrice d'objectifs
sont couverts : `phase: repetition`, puis `references/repetition.md`.
