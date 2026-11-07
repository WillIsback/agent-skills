---
name: semver-repo-setup
description: Met en place de bout en bout un nouveau dépôt selon le workflow « lots de version semver » de William (WillIsback) — fichiers d'outillage (CI/CD optimisée, templates, sécurité, CodeGraph, Aikido, CodeQL), dépôt et réglages GitHub, protection de main, Project kanban, puis backlog epics → user stories rangé en lots datés à partir d'un brief. À utiliser quand on demande de préparer, initialiser ou « setup » un projet ou un dépôt avec ce workflow.
---

# Mise en place d'un dépôt « lots de version semver »

Ce skill **installe** le workflow décrit par le skill `semver-batch-workflow` (lire celui-ci
pour les règles de travail). Référence de résultat : le projet P7
(github.com/WillIsback/P7-assistant-evenements-culturels).

Outils fournis (chemins relatifs à ce dossier) :

- `scripts/scaffold.py` : génère les fichiers depuis `assets/` (couches `common` →
  `<profil>` → `<profil>-docker`), remplace les variables, retire les blocs inutiles. Ne
  remplace jamais un fichier existant sans `--force`. `--help` pour les options.
- `scripts/github-setup.sh` : réglages GitHub idempotents (`repo`, `labels`, `secrets`,
  `milestones`, `project`, `protect`, `checks`).

Profils disponibles : `python-uv` (ruff, mypy strict, pytest + couverture, hatch-vcs,
option `--docker` : API FastAPI `/health` + image GHCR). Pour une autre stack : générer
`python-uv`, puis réécrire `ci-code-quality`, `ci-test`, `ci-codeql`, `dependabot.yml`,
`.gitignore` et le Dockerfile pour la stack, en gardant les noms de jobs `ci-*`, les
filtres par chemins et les caches (voir §7 de `semver-batch-workflow`).

## 0. Cadrer (une seule série de questions)

Lire le brief s'il est fourni, inspecter le dossier courant (fichiers existants, git,
`.env`), puis demander **seulement ce qui manque**, en une fois :

- nom du dépôt GitHub (owner par défaut : celui de `gh`), public ou privé ;
- titre et description en une phrase ;
- stack / profil ; service conteneurisé publié en release (`--docker`) ou non ;
- secrets nécessaires en CI (clés présentes dans `.env`) ;
- date cible (soutenance, livraison) pour dater les lots ;
- miroir Forgejo ou autre remote éventuel.

Valeurs par défaut si l'utilisateur ne précise pas : public, `python-uv`, Python 3.12,
auteur « William Derue », langue française pour tout le contenu.

Prérequis à vérifier : `gh auth status` avec les scopes `repo`, `workflow`, `project`
(sinon faire lancer `gh auth refresh -h github.com -s project` par l'utilisateur, avec le
préfixe `!` dans Claude Code) ; `uv` récent (`uv self update` si < 0.13) ; `jq`.

## 1. Amorçage et dépôt GitHub

1. `git init -b main` si besoin ; commit d'amorçage minimal **sur main** (`.gitignore`,
   `LICENSE`, `.python-version`) — seul commit direct autorisé, avant la protection.
2. `github-setup.sh -R <owner>/<repo> repo [--private] --description "<desc>"`
3. `github-setup.sh -R … labels`
4. `github-setup.sh -R … secrets <CLÉS…>` (si des secrets CI sont nécessaires).
5. `github-setup.sh -R … project "<Titre du projet>"` → noter le numéro (dernière ligne).

Dépôt privé sur un plan gratuit : pas de protection de branche, ni CodeQL, ni Dependency
Review. Le signaler, retirer `ci-codeql` et l'étape Dependency Review, et ne pas lancer
`protect`.

## 2. Issue et branche d'outillage

1. Issue `chore: outillage du dépôt (CI/CD, templates, CodeGraph, Aikido, CodeQL)`
   (label `type:chore`).
2. Branche `chore/outillage` depuis main.
3. `scaffold.py --dest . --owner … --repo … --title "…" --description "…" --author "…"
   --profile python-uv [--docker] [--python 3.12] --project-number <N>`
4. Lancer les « étapes suivantes » affichées (lock, sync, format, lint, types, tests) et
   corriger jusqu'au vert. Si `--docker` : `docker build` puis `curl /health` sur le
   conteneur.
5. Valider localement les workflows quand c'est possible : `actionlint` (avec
   `shellcheck` installé, sinon les avertissements shell n'apparaissent qu'en CI) et
   `uvx zizmor --min-severity high .github/workflows`.
6. Compléter `AGENTS.md` (contexte du brief, fournisseurs, contraintes) et `.env.example`
   (noms des variables, jamais de valeurs).
7. `codegraph init` (l'index `.codegraph/` est ignoré par git).
8. Commit `chore: outillage du dépôt (…)` avec `Closes #<issue>`, push, PR vers main en
   remplissant le modèle de PR (cases « Maintenance », « Aucune release », « Sans objet »).

## 3. Gates, protection, fusion

1. Attendre les checks : `gh pr checks <PR> --watch`. En cas d'échec, lire
   `gh run view <id> --log-failed`, corriger sur la branche, pousser.
   Échec connu : « Dependency review is not supported » → le dependency graph n'est pas
   encore actif ; relancer `github-setup.sh repo` puis le job.
2. Tout vert → `github-setup.sh -R … protect` (checks requis déduits des jobs `ci-*`).
3. `gh pr merge <PR> --squash`. Vérifier que `release` a tourné et conclu « pas de
   release » (chore), et que l'issue est fermée.

## 4. Backlog et board

À partir du brief :

1. **Epics** : issues `epic: <domaine fonctionnel>` (label `type:epic`, sans milestone,
   corps : objectif). 4 à 7 epics, fonctionnelles et durables.
2. **User stories** : une issue par livrable vérifiable, suivant les champs du template
   correspondant (feature : problème, solution, périmètre, critères d'acceptation
   cochables, branche `<type>/<version>-<tâche>` ; docs ; chore). Exigences du brief
   reprises explicitement dans les critères.
3. **Lots** : `github-setup.sh -R … milestones v0.1.0=AAAA-MM-JJ=<résumé> …`, dates
   réparties jusqu'à la date cible ; ordre patch → minor → major ; dépendances respectées
   (le socle d'abord). Rattacher chaque user story à son milestone.
4. **Sous-issues** : rattacher chaque user story à son epic
   (`gh api -X POST repos/<repo>/issues/<epic>/sub_issues -F sub_issue_id=<id REST>`).
5. **Board** : ajouter toutes les issues au Project (`gh project item-add`), Status
   « Planifié » pour les user stories rangées dans un lot, « Backlog » sinon, aucun
   Status pour les epics.
6. Noter dans les issues les **points ouverts** qui bloquent (choix à faire, clés
   manquantes) plutôt que de les inventer.

## 5. Restitution à l'utilisateur

Donner : URL du dépôt, URL du board, résultat des gates, liste des lots et epics, puis
les actions **manuelles** restantes (l'API ne les permet pas) :

- vues du board (Kanban groupé par Milestone, Lot en cours, Roadmap, Epics) et
  workflows intégrés (Auto-add → Backlog, Item closed → Fait, Item reopened → En cours) —
  détail au §9 de `semver-batch-workflow` ;
- connexion du dépôt à l'app GitHub Aikido ;
- secret `RELEASE_TOKEN` (jeton à grain fin Contents + Workflows en écriture) : sans
  lui, la création du tag échoue (403) si des workflows ont changé depuis la dernière
  release — c'est le cas dès la première PR Dependabot d'actions ;
- miroir Forgejo si demandé et non réalisable faute d'accès.

Ne jamais afficher la valeur d'un secret. Rapporter honnêtement ce qui a échoué ou n'a pas
été vérifié.
