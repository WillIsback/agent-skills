# AGENTS.md — __TITLE__

__DESCRIPTION__

<!-- Contexte projet (cahier des charges, fournisseurs, contraintes) : à compléter. -->

## Workflow (obligatoire)

Skills `semver-batch-workflow` et `semver-repo-setup`
(https://github.com/WillIsback/agent-skills). Résumé :

- Une issue typée par changement (`.github/ISSUE_TEMPLATE`) ; epics = issues parentes
  `type:epic`, user stories = sous-issues.
- Lots de version (milestones datés) traités dans l'ordre **patch → minor → major**.
- Branche de lot `<type>/<version>` ; une sous-branche par issue `<type>/<version>-<tâche>`,
  fusionnée dans la branche de lot par `<type>: merge <type>/<version>-<tâche> (#N)`.
- **Jamais de commit ni de merge direct sur `main`** : une PR par lot, avec `Closes #N`
  pour chaque issue.
- Board : https://github.com/users/__OWNER__/projects/__PROJECT_NUMBER__ — tenir à jour la
  colonne Status (En cours, Intégré au lot) avec `gh project item-edit`.
- Conventional Commits ; `feat` → minor, `fix`/`perf` → patch, `!` → major.
- Preflight uniquement si la CI de PR ne couvre pas un job de la release.
- Toujours minimiser le temps de CI/CD : ne rien construire deux fois, cacher, filtrer
  par chemins, garder le lourd hors PR.

## Commandes

```bash
__DEV_COMMANDS__
```

## Conventions

- Les tests unitaires n'appellent jamais de réseau : simuler. Les tests réels sont
  marqués `integration`.
- Explorer le code avec CodeGraph (`codegraph_explore`) avant grep/lecture.
- Textes, docs, commits et PR en français.
