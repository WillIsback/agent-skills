# Phase 2 — Session de specs

But : prendre, avec William, toutes les décisions structurantes du système, en lui
faisant comprendre pour chacune le contexte et les conséquences. Chaque décision devient
une ADR et une question probable de soutenance.

## Déroulé

1. **Lister les décisions** à prendre, d'après le brief, l'existant et le backlog
   (contrat d'API, stockage, outils, déploiement, monitoring, optimisation…). Les
   **ordonner par dépendances** : ce qui contraint les autres d'abord (le contrat
   d'entrée avant la validation, le stockage avant l'analyse de drift). Montrer la liste.
2. **Une décision à la fois**, au format ADR (`assets/spec.md`) :
   - **Contexte** : ce que l'énoncé, l'existant et les contraintes imposent ;
   - **Options** (2 ou 3), décrites concrètement, avec leurs compromis ;
   - **Recommandation** de l'agent, avec sa raison ;
   - **Choix** de William — attendre sa réponse avant d'aller plus loin ;
   - **Conséquences** sur le code, les tests, le monitoring et la soutenance ;
   - **Indicateurs de la fiche** concernés ;
   - **Question d'oral probable** (« Pourquoi X plutôt que Y ? »).
   Si William hésite ou ne voit pas une conséquence, l'expliquer avant qu'il tranche :
   une décision qu'il ne sait pas justifier ne doit pas être prise à sa place.
3. **Backlog** : si une décision ajoute, scinde ou re-date des user stories, mettre à jour
   les issues et le board, et le dire.

## Livrables

- `docs/spec.md` : vue d'ensemble puis une ADR par décision.
- `docs/architecture.md` (`assets/architecture.md`) : schémas **Mermaid**, au minimum
  **composants**, **séquence** du flux principal et **déploiement** (du push à
  l'environnement cible). Un diagramme de classes seulement si le code a un vrai modèle
  de domaine.

## Commit et porte

- Branche `docs/<X.Y.Z>-specs` (X.Y.Z = version du premier lot), commit `docs:`, PR vers
  `main` selon `semver-batch-workflow` (aucune release).
- Avant la fusion : skill `oc-oral-blanc` sur cette PR, porte d'identifiant **`specs`**.
  Pas de `gh pr merge` sans la ligne `oc-gate: specs validé …` pour le SHA de tête.

## Fin de phase

William approuve `docs/spec.md` et `docs/architecture.md`, la PR est fusionnée. Journal
de `.oc/state.md`, puis `phase: livraison` et `lot:` = premier lot du board. Enchaîner sur
`references/livraison.md`.
