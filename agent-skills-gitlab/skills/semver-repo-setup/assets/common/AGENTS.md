# AGENTS.md — __TITLE__

__DESCRIPTION__

<!-- Contexte projet (cahier des charges, fournisseurs, contraintes) : à compléter. -->

## Workflow (obligatoire)

Skills `semver-batch-workflow` et `semver-repo-setup`
(https://gitlab.com/WillIsback/agent-skills-gitlab). Résumé :

- Une issue typée par changement (`.gitlab/issue_templates/`) ; epics = issues parentes
  `type::epic`, user stories = issues enfants.
- Lots de version (milestones datés) traités dans l'ordre **patch → minor → major**.
- Branche de lot `<type>/<version>` ; une sous-branche par issue `<type>/<version>-<tâche>`,
  fusionnée dans la branche de lot par `<type>: merge <type>/<version>-<tâche> (#N)`.
- **Jamais de commit ni de merge direct sur `main`** : une MR par lot, avec `Closes #N`
  pour chaque issue.
- Board : https://gitlab.com/__NAMESPACE__/__REPO__/-/boards — tenir à jour les labels à
  portée `status::*` (`status::planifié`, `status::en-cours`, `status::intégré`) avec
  `glab issue update`.
- Conventional Commits ; `feat` → minor, `fix`/`perf` → patch, `!` → major.
- Preflight uniquement si la CI de MR ne couvre pas un job de la release.
- Toujours minimiser le temps de CI/CD : ne rien construire deux fois, cacher, filtrer
  par chemins (`rules:changes`), garder le lourd hors MR.

## Commandes

```bash
__DEV_COMMANDS__
```

## Conventions

- Les tests unitaires n'appellent jamais de réseau : simuler. Les tests réels sont
  marqués `integration`.
- Explorer le code avec CodeGraph (`tools.codegraph.codegraph_explore`) avant grep/lecture.
  Le serveur MCP est déclaré dans `opencode.json` ; ses outils sont autorisés par la
  politique de permissions de base d'OpenCode.
- Textes, docs, commits et MR en français.
