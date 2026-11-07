---
name: semver-batch-workflow
description: Workflow Git/GitHub de William (WillIsback) — epics et issues typées, board kanban GitHub Projects, lots de version semver (patch → minor → major), branche de lot + sous-branches par issue, PR unique vers main, gates CI optimisées en temps, release automatique avec bump. À utiliser pour planifier, exécuter et livrer un lot de travail (issues, branches, board, PR, release) dans un de ses projets ; pour la mise en place initiale d'un dépôt, utiliser semver-repo-setup.
---

# Workflow « lots de version semver »

Méthode de travail de William Derue (GitHub : WillIsback). Indépendante de l'outil
(Claude Code, opencode, autre agent). Référence d'implémentation complète :
`syntheo-desktop` (`.github/workflows/`, `.github/ISSUE_TEMPLATE/`, `CONTRIBUTING.md`).

## 1. Issues

- Une issue par changement, créée depuis un template typé : bug, feature, refactor,
  docs, chore/other.
- Chaque issue porte son impact semver : `fix`/`perf` → patch, `feat` → minor,
  breaking change (`!`) → major ; `docs`/`chore`/`test`/`ci`/`refactor` → pas de release
  seule.
- Hiérarchie **epic → user story → tâche** via les sous-issues GitHub :
  - epic = issue parente fonctionnelle (label `type:epic`, sans milestone), peut
    couvrir plusieurs lots ;
  - user story = sous-issue de l'epic, c'est elle qu'on range dans un lot et qu'on
    traite sur une sous-branche ;
  - tâche = sous-issue de la user story, ou checklist dans son corps si elle est petite.
- Les issues sont suivies dans le Project GitHub du dépôt (voir §9).

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
- Une PR vers `main` embarque **tout le lot** (toutes les issues de la branche de lot).
- Titre de PR et commits au format Conventional Commits
  (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`, `build`, `revert`,
  `!` pour breaking).
- Le corps de PR référence chaque issue (`Closes #N`) et coche le bump déclaré
  (Patch / Minor / Major / Aucune release).

## 4. Preflight

- Le preflight n'est nécessaire **que si** la CI de PR ne couvre pas un job de la release
  (impossible en CI de PR, ou trop coûteux en temps : build complet, CodeQL lourd,
  tests sur matériel réel…).
- Il rejoue alors localement ces jobs manquants sur la branche de lot avant d'ouvrir
  la PR vers `main`. Si la CI de PR couvre tout, pas de preflight.

## 5. CI de PR sur main (gates bloquantes)

Catégories habituelles (adapter au langage) :

| Gate | Contenu |
|---|---|
| code-quality | formatage, lint, typage, actionlint, zizmor (sécurité des workflows), lockfiles |
| test | tests unitaires, couverture |
| security | Dependency Review, Gitleaks, Trivy, scan de dépendances, registre d'exceptions de sécurité avec expiration |
| codeql | CodeQL `security-extended` sur les langages modifiés |
| traceability | issue référencée, type de PR valide, cohérence du bump semver déclaré avec le titre |
| Aikido | analyse via l'app GitHub Aikido |

Toutes vertes → merge → release.

## 6. Release

- Déclenchée par le push sur `main` (merge de la PR de lot), ou manuellement
  (`workflow_dispatch` avec bump forcé et dry-run).
- Bump calculé depuis les commits depuis le dernier tag `vX.Y.Z` : `!` → major,
  `feat` → minor, `fix`/`perf` → patch, sinon pas de release.
- Gate de cohérence de version (le tag n'existe pas et il est supérieur au dernier),
  puis tag, GitHub Release et artefacts (paquets, image Docker…).
- Concurrence sérialisée (`cancel-in-progress: false`).

## 7. Optimisation du temps CI/CD (principe permanent)

Le temps d'exécution des workflows conditionne l'efficacité. Toujours :

- **Ne jamais construire deux fois le même artefact** : construire une fois, passer
  l'artefact entre jobs (`upload-artifact`/`download-artifact`, image poussée une seule
  fois puis promue par tag plutôt que reconstruite).
- **Cacher systématiquement** : dépendances (cache uv/pip/pnpm/cargo), couches Docker
  (`cache-from/cache-to: type=gha`), modèles et données lourdes, index précalculés.
- **Filtrer par chemins** : ne lancer une gate que si les fichiers concernés changent
  (`paths`/`dorny/paths-filter`), avec un job « required » toujours présent pour la
  protection de branche.
- **Paralléliser** les gates indépendantes ; `concurrency` + `cancel-in-progress: true`
  sur les PR.
- **Reléguer le lourd hors PR** (CodeQL complet, build multi-plateforme, tests longs) :
  release, planification hebdomadaire, ou preflight local.
- `timeout-minutes` sur chaque job ; épingler les actions par SHA.
- Mesurer : surveiller la durée des runs et traiter toute dérive comme une issue `ci`.

## 8. Outillage standard d'un dépôt

Mise en place automatisée : skill `semver-repo-setup` (scaffold + réglages GitHub + board + backlog).

- **CodeGraph** : index `.codegraph/` (`codegraph init`), serveur MCP déclaré dans
  `.mcp.json`, permissions des outils codegraph dans la config de l'agent.
- **Aikido** : app GitHub connectée au dépôt, dossier `.aikido`, scans via MCP.
- **CodeQL** : workflow `ci-codeql` (PR : langages modifiés ; lourd : hebdo/release).
- **GitHub** : templates d'issue et de PR, Project, protection de `main` (PR obligatoire,
  gates requises), Dependabot groupé avec auto-merge si les gates sont vertes.
- Docs : `CONTRIBUTING.md` (flux, gates, vérifications locales) et `AGENTS.md`
  qui pointe vers ce workflow.

## 9. Board kanban (GitHub Projects)

Un Project par dépôt, lié au dépôt. Colonnes = champ **Status** :

| Status | Signification | Déplacée par |
|---|---|---|
| Backlog | issue créée, sans milestone | workflow « Auto-add » |
| Planifié | rattachée à un milestone (= lot) | l'agent/l'humain en posant le milestone |
| En cours | sous-branche `<type>/<version>-<tâche>` ouverte | l'agent au démarrage de la tâche |
| Intégré au lot | sous-branche fusionnée dans la branche de lot | l'agent après la fusion |
| Fait | PR de lot fusionnée sur main, issue fermée | workflow « Item closed » |

- **`Closes #N` ne ferme l'issue qu'au merge sur la branche par défaut** : une
  sous-branche fusionnée dans le lot laisse l'issue ouverte (c'est voulu). La colonne
  « Intégré au lot » n'est pas automatisable par les workflows intégrés : l'agent la
  met à jour avec `gh project item-edit`.
- Milestones = lots, **avec date d'échéance** (vue Roadmap). Trier par milestone
  respecte l'ordre semver, donc la règle patch → minor → major (`v0.1.1` < `v0.2.0`).
- Epics sans Status (hors kanban) ; leur avancement se lit via « Sub-issues progress ».
- Vues (à créer dans l'interface, l'API ne gère pas les vues) :
  1. **Kanban** : Board, colonnes Status, Group by Milestone, filtre `-label:type:epic`.
  2. **Lot en cours** : Board filtré `milestone:<lot> -label:type:epic`, limite 2 sur « En cours ».
  3. **Roadmap** : Roadmap sur les dates de Milestone, Group by Parent issue.
  4. **Epics** : Table `label:type:epic` avec la colonne Sub-issues progress.
- Workflows intégrés : Auto-add (→ Backlog), Item closed (→ Fait), Item reopened (→ En cours).

Commandes utiles pour l'agent :

```bash
# identifiants
gh project view <N> --owner <owner> --format json --jq .id
gh project field-list <N> --owner <owner> --format json \
  --jq '.fields[]|select(.name=="Status")'
gh project item-list <N> --owner <owner> --format json --limit 200
# déplacer une carte
gh project item-edit --project-id <PID> --id <ITEM_ID> \
  --field-id <STATUS_FIELD_ID> --single-select-option-id <OPTION_ID>
# rattacher une user story à une epic (id REST de l'issue enfant, pas son numéro)
gh api -X POST repos/<owner>/<repo>/issues/<epic>/sub_issues \
  -F sub_issue_id=$(gh api repos/<owner>/<repo>/issues/<n> --jq .id)
```

Le scope `project` est requis : `gh auth refresh -h github.com -s project`.
