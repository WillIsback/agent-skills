---
name: semver-batch-workflow
description: Workflow Git/GitLab de William (WillIsback) — epics et issues typées, board kanban GitLab (labels à portée status::*), lots de version semver (patch → minor → major), branche de lot + sous-branches par issue, MR unique vers main, gates CI optimisées en temps, release automatique avec bump. À utiliser pour planifier, exécuter et livrer un lot de travail (issues, branches, board, MR, release) dans un de ses projets ; pour la mise en place initiale d'un dépôt, utiliser semver-repo-setup.
---

# Workflow « lots de version semver » (GitLab)

Méthode de travail de William Derue (GitLab : WillIsback). Indépendante de l'outil
(OpenCode, autre agent). Variante GitLab/OpenCode du workflow ; la mécanique semver est
identique à la variante GitHub, seule l'implémentation de la forge change.

## 1. Issues

- Une issue par changement, créée depuis un **template typé** (`.gitlab/issue_templates/`) :
  bug, feature, refactor, docs, chore/other.
- Chaque issue porte son impact semver : `fix`/`perf` → patch, `feat` → minor,
  breaking change (`!`) → major ; `docs`/`chore`/`test`/`ci`/`refactor` → pas de release
  seule.
- Hiérarchie **epic → user story → tâche** :
  - epic = issue parente fonctionnelle (label `type::epic`, sans milestone), peut
    couvrir plusieurs lots. Les **epics de groupe** GitLab sont une fonction Premium ;
    sur un plan gratuit, l'epic est une issue `type::epic` et ses user stories y sont
    rattachées comme **éléments enfants** (work items / tâches) ou, à défaut, par un
    lien d'issue `relates_to` ;
  - user story = issue enfant de l'epic, c'est elle qu'on range dans un lot et qu'on
    traite sur une sous-branche ;
  - tâche = élément enfant (checklist/work item) de la user story, ou case dans son corps
    si elle est petite.
- Les issues sont suivies dans le **board** du projet (voir §9).

## 2. Lots de version et ordre de traitement

- Le travail est regroupé en **lots**, un lot = la prochaine version.
- Ordre strict : d'abord les lots **patch** (fix), ensuite **minor** (feat), enfin
  **major**.
- Branche de lot : `<type>/<version>` (ex. `fix/0.5.3`, `feat/0.6.0`, `major/1.0.0`).
- Chaque issue du lot est traitée séparément sur une sous-branche
  `<type>/<version>-<tâche>` (ex. `fix/0.5.3-durcir-chemins`), créée depuis la branche
  de lot.
- La sous-branche est fusionnée dans la branche de lot par un commit
  `<type>: merge <type>/<version>-<tâche> (#N)`.

## 3. Règles sur main

- **Jamais de merge direct sur `main`.**
- Une MR vers `main` embarque **tout le lot** (toutes les issues de la branche de lot).
- Titre de MR et commits au format Conventional Commits
  (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`, `build`, `revert`,
  `!` pour breaking).
- Le corps de MR référence chaque issue (`Closes #N`) et coche le bump déclaré
  (Patch / Minor / Major / Aucune release).
- Pour une application livrée aux utilisateurs, **pas de merge sans réserves levées** sur
  une alpha du lot (voir §4 bis).

## 4. Preflight

- Le preflight n'est nécessaire **que si** la CI de MR ne couvre pas un job de la release
  (impossible en CI de MR, ou trop coûteux en temps : build complet, SAST lourd,
  tests sur matériel réel…).
- Il rejoue alors localement ces jobs manquants sur la branche de lot avant d'ouvrir
  la MR vers `main`. Si la CI de MR couvre tout, pas de preflight.

## 4 bis. Alpha du lot et réserves à lever (applications)

Pour un projet qui livre une application (desktop, mobile…), les tests automatiques ne
suffisent pas : certaines vérifications demandent le vrai matériel, le vrai OS ou un usage
réel. Avant de fusionner la MR de lot sur `main` :

1. **Construire une alpha du lot** une fois toutes les sous-branches intégrées, en variante
   de diagnostic quand elle existe (ex. `devtools` : inspecteur, logs détaillés, barre de
   mesures) : pipeline manuel sur la branche de lot
   (`glab ci run -b <branche-de-lot> --variables version:X.Y.Z-N`, job `build-devtools`).
   Suffixe de pré-version **numérique** (`0.6.2-1`, pas `0.6.2-alpha.1`) : l'installeur
   MSI de Windows refuse les autres. Artefacts du pipeline, rien n'est publié.
   Alphas **jamais signées** (signature réservée à la release : le job de build la
   refuse dès qu'une feature est passée), construites **en local de préférence**
   quand le projet fournit des scripts d'alpha (ex. `scripts/build-alpha.sh` sous Linux,
   `scripts/build-alpha.ps1` sous Windows), le job `build-devtools` restant en secours.
2. **Rédiger dans le corps de la MR une section « Réserves à lever »** cochable :
   - une case par vérification, avec la plateforme (🐧 Linux, 🪟 Windows, 🍎 macOS) et le
     **signal attendu** (ligne de log, mesure de la barre de diagnostic, comportement
     visible) ;
   - chaque issue du lot qui ne se prouve pas par un test automatique ;
   - les réserves encore ouvertes des versions précédentes, testables sur les machines
     disponibles ;
   - où trouver les traces (chemins des logs par OS) et comment récupérer l'alpha.
3. **L'humain teste et coche** (ou dicte ses impressions à l'agent, qui coche et ouvre une
   issue par problème trouvé). Une réserve non testable peut être **reportée
   explicitement** (texte de la case + raison), jamais passée sous silence.
4. Merge seulement quand toutes les cases sont cochées ou reportées. Un problème bloquant
   repart en sous-branche du lot, puis nouvelle alpha (`X.Y.Z-N+1`).

L'alpha et le preflight se font en parallèle : le preflight vérifie le code, l'alpha
vérifie l'expérience réelle.

## 4 ter. Rétrospective et ménage avant chaque minor ou major

Les lots patch ajoutent du code sans jamais en retirer. Avant d'ouvrir un lot **minor** ou
**major**, on prévoit dans ce lot une tâche de ménage :

1. **Mesurer** : lignes de code par catégorie (code, tests, générés exclus), comparées au
   lot précédent et au point le plus bas connu ; zones qui ont le plus grossi ; fichiers
   au-delà de la limite du projet (ex. 500 lignes).
2. **Rétrospective et revue de code** de ces zones, en s'appuyant aussi sur les journaux
   et les décisions des pages de suivi des releases du cycle (§6 bis) : code mort, doublons,
   abstractions inutiles, restes d'un code d'origine (fork) jamais utilisés, tests
   redondants. Outils :
   analyse de dépendances et d'exports inutilisés (`knip`, `cargo machete`, `cargo udeps`),
   index de code (CodeGraph) pour les symboles sans appelant.
3. **Réduire** : une user story par zone, dans le lot, avec un objectif chiffré de lignes
   retirées et la règle « comportement inchangé » (les tests existants restent verts).
4. **Valider** par l'alpha du lot (§4 bis), avec des tests **exhaustifs** quand le ménage
   touche des parcours utilisateur.
5. Noter le nouveau total dans la MR du lot, pour suivre la tendance d'une version à
   l'autre.
6. **Publier la carte du code** quand le dépôt a un index CodeGraph : régénérer, en dernier
   dans la MR du lot et sur un arbre propre, la carte interactive de la codebase (zones,
   lignes, liens entre zones) que la documentation affiche, avec le numéro de la version à
   venir. Le générateur est déterministe (même index = même fichier) et vérifiable
   (`--check`), pour que la carte de chaque minor ou major reste comparable à la précédente.

## 5. CI de MR sur main (gates bloquantes)

Catégories habituelles (adapter au langage) :

| Gate | Contenu |
|---|---|
| code-quality | formatage, lint, typage, lint du pipeline (`glab ci lint`), lockfiles |
| test | tests unitaires, couverture |
| security | Dependency Scanning, Secret Detection (Gitleaks), Trivy, registre d'exceptions de sécurité avec expiration |
| sast | GitLab SAST (Semgrep) sur les langages modifiés |
| traceability | issue référencée, type de MR valide, cohérence du bump semver déclaré avec le titre |
| Aikido | analyse via l'intégration Aikido |

Toutes vertes → merge → release.

## 6. Release

- Déclenchée par le push sur `main` (merge de la MR de lot), ou manuellement
  (pipeline `workflow` / variable `BUMP` forcée et `DRY_RUN`).
- Bump calculé depuis les commits depuis le dernier tag `vX.Y.Z` : `!` → major,
  `feat` → minor, `fix`/`perf` → patch, sinon pas de release.
- Gate de cohérence de version (le tag n'existe pas et il est supérieur au dernier),
  puis tag, **GitLab Release** (via `release:` / `release-cli`) et artefacts (paquets,
  image Docker…).
- Concurrence sérialisée (`resource_group: release`).

## 6 bis. Page de suivi après chaque release (applications)

Les réserves de l'alpha (§4 bis) ne couvrent pas tout : la mise à jour réelle depuis la
version précédente, l'usage sur plusieurs jours, les décisions laissées en suspens. Après
chaque release d'une application livrée aux utilisateurs, l'agent ouvre une **page de suivi
interactive** pour la période qui suit (jusqu'au lot suivant ou à la prochaine échéance) :

- **Support** : une page partagée et persistante, que l'humain remplit depuis n'importe quel
  appareil et que l'agent relit (par exemple une page Artifact avec base de données ; à défaut
  une issue épinglée à cases, ou un board filtré). Le contenu vit dans les données, pas dans
  le code de la page : la même page sert de modèle d'une release à l'autre.
- **Trois blocs** :
  1. **À vérifier** — une ligne par point, états *À faire / OK / Problème / Reporté* et une
     note libre. On y met : la mise à jour réelle depuis la version précédente ; l'usage réel
     de la version publiée ; les réserves levées sans test sur l'alpha, à confirmer dès que
     l'occasion se présente ; les bugs connus du backlog à reproduire, candidats du prochain
     patch ; la préparation de l'échéance suivante.
  2. **Décisions** — chaque décision qui attend l'humain, avec ses options cliquables, la
     recommandation de l'agent signalée, et une note libre.
  3. **Journal** — constats datés : jour, poste ou plateforme, importance (bloquant, gênant,
     détail, idée), une ligne de texte.
- **Taille proportionnelle à la release** : une minor importante en remonte beaucoup, un patch
  quelques-uns. Ne pas gonfler la liste.
- **Relecture** à la demande de l'humain : l'agent lit les données, ouvre une issue par
  problème ou constat bloquant ou gênant, range les candidats dans le prochain lot et applique
  les décisions. Une décision cochée sur la page vaut instruction de l'humain ; une action
  irréversible (fusion, publication) se confirme quand même dans la conversation.
- **Clôture** : la case de mise à jour réelle cochée clôt le lot publié. Les constats
  alimentent la composition du lot suivant et la rétrospective avant une minor (§4 ter).
- **Confidentialité** : aucune donnée réelle d'utilisateur (contenus, documents, captures
  privées) dans la page ni dans les issues qui en sortent.

## 7. Optimisation du temps CI/CD (principe permanent)

Le temps d'exécution des pipelines conditionne l'efficacité. Toujours :

- **Ne jamais construire deux fois le même artefact** : construire une fois, passer
  l'artefact entre jobs (`artifacts:`/`dependencies:`, image poussée une seule
  fois puis promue par tag plutôt que reconstruite).
- **Cacher systématiquement** : dépendances (`cache:` keyed sur le lockfile pour
  uv/pip/pnpm/cargo), couches Docker (`--cache-from`/`--cache-to` avec le registre),
  modèles et données lourdes, index précalculés.
- **Filtrer par chemins** : ne lancer une gate que si les fichiers concernés changent
  (`rules:changes`), avec un job « required » toujours présent pour la protection de
  branche (règle « pipelines must succeed »).
- **Paralléliser** les gates indépendantes ; `interruptible: true` + annulation
  automatique des pipelines redondants sur les MR.
- **Reléguer le lourd hors MR** (SAST complet, build multi-plateforme, tests longs) :
  release, pipeline planifié hebdomadaire, ou preflight local.
- `timeout:` sur chaque job ; épingler les images d'exécution par digest.
- Mesurer : surveiller la durée des pipelines et traiter toute dérive comme une issue `ci`.

## 8. Outillage standard d'un dépôt

Mise en place automatisée : skill `semver-repo-setup` (scaffold + réglages GitLab + board + backlog).

- **CodeGraph** : index `.codegraph/` (`codegraph init`), serveur MCP déclaré dans
  `opencode.json`, permissions des outils codegraph dans la config de l'agent.
- **Aikido** : intégration connectée au projet, dossier `.aikido`, scans via MCP.
- **GitLab SAST** : template `Security/SAST.gitlab-ci.yml` (MR : langages modifiés ;
  complet : hebdo/release via pipeline planifié).
- **Alpha de diagnostic** (applications) : job `build-devtools` déclenché à la demande
  (`when: manual` / `workflow`, version en variable, artefacts courts), et section « Réserves à
  lever » dans le template de MR (§4 bis).
- **GitLab** : templates d'issue et de MR, board, protection de `main` (MR obligatoire,
  « pipelines must succeed », « all threads resolved »), **Renovate** pour les mises à jour
  de dépendances (GitLab n'a pas de Dependabot natif). Auto-merge réservé aux MR Renovate
  minor/patch, une fois **tous** les checks terminés et verts ; une MR isolée (majeure, ou
  0.x → 0.y) se relit à la main. Les familles qui doivent monter ensemble (SDK,
  `windows`/`windows-core`…) sont groupées dans `renovate.json` ; les dépendances épinglées
  ou non compilées en CI sont ignorées.
- **Agents en parallèle sur une même machine** : `AGENTS.md` impose des tests ciblés
  pendant le développement (`vitest related --run <fichiers>`, `cargo test -p <crate>`),
  la suite complète une seule fois avant le commit final. Le dépôt plafonne les workers
  de test (vitest `maxWorkers`), et le profil dev Rust se passe du cache incrémental
  quand plusieurs worktrees partagent un `target/`. Le brief de chaque sous-agent le rappelle.
- Docs : `CONTRIBUTING.md` (flux, gates, vérifications locales) et `AGENTS.md`
  qui pointe vers ce workflow.

## 9. Board kanban (GitLab issue board)

Un board par projet. Les colonnes sont des **labels à portée** (scoped labels) de la
famille `status::` — un seul `status::*` par issue à la fois, GitLab remplace l'ancien quand
on déplace la carte :

| Liste (label) | Signification | Déplacée par |
|---|---|---|
| Open (sans `status::`) | issue créée, sans milestone | défaut à la création |
| `status::planifié` | rattachée à un milestone (= lot) | l'agent/l'humain en posant le milestone |
| `status::en-cours` | sous-branche `<type>/<version>-<tâche>` ouverte | l'agent au démarrage de la tâche |
| `status::intégré` | sous-branche fusionnée dans la branche de lot | l'agent après la fusion |
| Closed | MR de lot fusionnée sur main, issue fermée | GitLab à la fermeture |

- **`Closes #N` ne ferme l'issue qu'au merge sur la branche par défaut** : une
  sous-branche fusionnée dans le lot laisse l'issue ouverte (c'est voulu). Le label
  `status::intégré` est posé par l'agent après la fusion (`glab issue update`).
- **Board piloté par labels** : contrairement à GitHub Projects, aucune automatisation
  n'est nécessaire pour la plupart des transitions — déplacer une carte entre deux listes
  échange les labels à portée. La fermeture d'une issue l'envoie dans la liste Closed.
- Milestones = lots, **avec date d'échéance**. Trier/grouper par milestone respecte l'ordre
  semver, donc la règle patch → minor → major (`v0.1.1` < `v0.2.0`).
- Epics **ouvertes** sans `status::` (hors kanban via le filtre `-type::epic`) ; leur
  avancement se lit via les éléments enfants. Une epic **fermée** part en liste Closed.
- Board et vues (créés par `gitlab-setup.sh board`, ajustables dans l'interface) :
  1. **Kanban** : board scoped-label `status::*`, groupé par Milestone, filtre
     `-label:type::epic`.
  2. **Lot en cours** : board filtré `milestone:<lot>` et `-label:type::epic`, limite 2
     sur `status::en-cours` (WIP limit).
  3. **Roadmap** : vue Roadmap sur les dates de Milestone (Premium) ; à défaut, liste des
     milestones triée par date.
  4. **Epics** : filtre `label:type::epic` avec la progression des éléments enfants.

Commandes utiles pour l'agent :

```bash
# identifiants du projet
glab api "projects/:id" --jq '.id'
# labels à portée (créés par gitlab-setup.sh)
glab api "projects/:id/labels?per_page=100" --jq '.[].name'
# déplacer une carte = échanger le label à portée (un seul status:: à la fois)
glab issue update <N> --label "status::en-cours" --unlabel "status::planifié"
# rattacher une user story à une epic (élément enfant / work item)
glab api -X POST "projects/:id/issues/<epic>/links" -F "target_project_id=:id" -F "target_issue_iid=<n>"
# board et ses listes
glab api "projects/:id/boards" --jq '.[].id'
glab api -X POST "projects/:id/boards/<board_id>/lists" -F "label_id=<id_status::planifié>"
```

`glab auth login` (ou `GITLAB_TOKEN`) avec les scopes `api` et `write_repository`.
