---
name: semver-repo-setup
description: Met en place de bout en bout un nouveau dépôt GitLab selon le workflow « lots de version semver » de William (WillIsback) — fichiers d'outillage (CI/CD GitLab optimisée, templates, sécurité, CodeGraph, Aikido, SAST), projet et réglages GitLab, protection de main, board, puis backlog epics → user stories rangé en lots datés à partir d'un brief. Harness OpenCode (opencode.json, AGENTS.md). À utiliser quand on demande de préparer, initialiser ou « setup » un projet ou un dépôt GitLab avec ce workflow.
---

# Mise en place d'un dépôt GitLab « lots de version semver »

Ce skill **installe** le workflow décrit par le skill `semver-batch-workflow` (lire celui-ci
pour les règles de travail). Variante GitLab/OpenCode.

Outils fournis (chemins relatifs à ce dossier) :

- `scripts/scaffold.py` : génère les fichiers depuis `assets/` (couches `common` →
  `<profil>` → `<profil>-docker`), remplace les variables, retire les blocs inutiles. Ne
  remplace jamais un fichier existant sans `--force`. `--help` pour les options.
- `scripts/gitlab-setup.sh` : réglages GitLab idempotents (`project`, `labels`, `variables`,
  `milestones`, `board`, `protect`, `checks`).

Profils disponibles : `python-uv` (ruff, mypy strict, pytest + couverture, hatch-vcs,
option `--docker` : API FastAPI `/health` + image sur le Container Registry GitLab). Pour une
autre stack : générer `python-uv`, puis réécrire `.gitlab/ci/code-quality.yml`,
`.gitlab/ci/test.yml`, `renovate.json` et le Dockerfile pour la stack, en gardant les noms de
jobs, les `rules:changes` et les caches (voir §7 de `semver-batch-workflow`).

## 0. Cadrer (une seule série de questions)

Lire le brief s'il est fourni, inspecter le dossier courant (fichiers existants, git,
`.env`), puis demander **seulement ce qui manque**, en une fois :

- chemin du projet GitLab (`<namespace>/<repo>`, namespace par défaut : celui de `glab`),
  public, interne ou privé ;
- titre et description en une phrase ;
- stack / profil ; service conteneurisé publié en release (`--docker`) ou non ;
- secrets nécessaires en CI (clés présentes dans `.env` → variables CI/CD GitLab) ;
- date cible (soutenance, livraison) pour dater les lots ;
- miroir GitHub, Forgejo ou autre remote éventuel.

Valeurs par défaut si l'utilisateur ne précise pas : public, `python-uv`, Python 3.12,
auteur « William Derue », langue française pour tout le contenu.

Prérequis à vérifier : `glab auth status` (ou `GITLAB_TOKEN`) avec les scopes `api` et
`write_repository` ; `uv` récent (`uv self update` si < 0.13) ; `jq`.

## 1. Amorçage et projet GitLab

1. `git init -b main` si besoin ; commit d'amorçage minimal **sur main** (`.gitignore`,
   `LICENSE`, `.python-version`) — seul commit direct autorisé, avant la protection.
2. `gitlab-setup.sh -R <namespace>/<repo> project [--visibility private] --description "<desc>"`
3. `gitlab-setup.sh -R … labels`
4. `gitlab-setup.sh -R … variables <CLÉS…>` (si des secrets CI sont nécessaires).
5. `gitlab-setup.sh -R … board` → crée le board et ses listes à portée `status::*`.

Projet privé : la protection de branche et le board fonctionnent sur tous les plans. Les
fonctions **Premium/Ultimate** (epics de groupe, vue Roadmap, règles d'approbation,
SAST/Dependency Scanning avancés) sont signalées quand elles manquent ; le reste reste
disponible sur le plan gratuit (SAST et Secret Detection de base inclus).

## 2. Issue et branche d'outillage

1. Issue `chore: outillage du dépôt (CI/CD, templates, CodeGraph, Aikido, SAST)`
   (label `type::chore`).
2. Branche `chore/outillage` depuis main.
3. `scaffold.py --dest . --namespace … --repo … --title "…" --description "…" --author "…"
   --profile python-uv [--docker] [--python 3.12]`
4. Lancer les « étapes suivantes » affichées (lock, sync, format, lint, types, tests) et
   corriger jusqu'au vert. Si `--docker` : `docker build` puis `curl /health` sur le
   conteneur.
5. Valider localement le pipeline quand c'est possible : `glab ci lint` sur `.gitlab-ci.yml`.
6. Compléter `AGENTS.md` (contexte du brief, fournisseurs, contraintes) et `.env.example`
   (noms des variables, jamais de valeurs).
7. `codegraph init` (l'index `.codegraph/` est ignoré par git).
8. Commit `chore: outillage du dépôt (…)` avec `Closes #<issue>`, push, MR vers main en
   remplissant le modèle de MR (cases « Maintenance », « Aucune release », « Sans objet »).

## 3. Gates, protection, fusion

1. Attendre le pipeline : `glab ci status --branch chore/outillage` (ou `glab mr view <IID>`).
   En cas d'échec, lire les logs du job (`glab ci trace <job>`), corriger sur la branche,
   pousser.
2. Tout vert → `gitlab-setup.sh -R … protect` (protection de `main` : MR obligatoire,
   « pipelines must succeed », « all threads resolved », pas de push direct).
3. `glab mr merge <IID> --squash --remove-source-branch`. Vérifier que le pipeline de
   release sur `main` a tourné et conclu « pas de release » (chore), et que l'issue est fermée.

## 4. Backlog et board

À partir du brief :

1. **Epics** : issues `epic: <domaine fonctionnel>` (label `type::epic`, sans milestone,
   corps : objectif). 4 à 7 epics, fonctionnelles et durables. (Les epics de **groupe**
   GitLab — Premium — peuvent remplacer ces issues parentes si le plan les offre.)
2. **User stories** : une issue par livrable vérifiable, suivant le template correspondant
   (feature : problème, solution, périmètre, critères d'acceptation cochables, branche
   `<type>/<version>-<tâche>` ; docs ; chore). Exigences du brief reprises explicitement
   dans les critères.
3. **Lots** : `gitlab-setup.sh -R … milestones v0.1.0=AAAA-MM-JJ=<résumé> …`, dates
   réparties jusqu'à la date cible ; ordre patch → minor → major ; dépendances respectées
   (le socle d'abord). Rattacher chaque user story à son milestone (`glab issue update`).
4. **Éléments enfants** : rattacher chaque user story à son epic (lien d'issue, ou work
   item enfant) : `glab api -X POST "projects/:id/issues/<epic>/links"
   -F target_project_id=:id -F target_issue_iid=<n>`.
5. **Board** : les issues apparaissent automatiquement ; poser `status::planifié` sur les
   user stories rangées dans un lot (`glab issue update <n> --label "status::planifié"`),
   rien pour les epics (filtrées `-label:type::epic`).
6. Noter dans les issues les **points ouverts** qui bloquent (choix à faire, clés
   manquantes) plutôt que de les inventer.

## 5. Restitution à l'utilisateur

Donner : URL du projet, URL du board, résultat des gates, liste des lots et epics, puis
les actions **manuelles** restantes (l'API ne les permet pas toujours) :

- vues du board (limite WIP sur `status::en-cours`, Roadmap si Premium) — détail au §9 de
  `semver-batch-workflow` ;
- connexion du projet à l'intégration Aikido ;
- installation du bot **Renovate** (GitLab n'a pas de Dependabot natif) : soit l'app
  Renovate hébergée connectée au projet, soit un pipeline planifié `renovate-bot` ; sans
  lui, pas de mises à jour de dépendances automatiques ;
- variable CI/CD `RELEASE_TOKEN` (jeton projet/groupe avec `write_repository`, ou simple
  usage de `CI_JOB_TOKEN` quand les protections le permettent) pour la création du tag et
  de la Release ;
- miroir GitHub/Forgejo si demandé et non réalisable faute d'accès.

Ne jamais afficher la valeur d'un secret. Rapporter honnêtement ce qui a échoué ou n'a pas
été vérifié.
