# Contribuer

## Flux de travail

Le dépôt suit le workflow « lots de version semver »
([skill `semver-batch-workflow`](https://gitlab.com/WillIsback/agent-skills-gitlab)) :

1. Une **issue** par changement (modèles : bug, feature, refactor, docs, chore) ; les
   epics regroupent les user stories comme issues enfants.
2. Les issues sont regroupées en **lots** (milestones), un lot = la prochaine version,
   traités dans l'ordre **patch → minor → major**.
3. Branche de lot `<type>/<version>` (ex. `feat/0.2.0`) créée depuis `main`.
4. Chaque issue sur une sous-branche `<type>/<version>-<tâche>`, fusionnée dans la
   branche de lot par `<type>: merge <type>/<version>-<tâche> (#N)`.
5. Lot complet (et preflight si nécessaire) → **une MR vers `main`** suivant le
   [modèle de MR](.gitlab/merge_request_templates/Default.md). Jamais de merge direct
   sur `main`.
6. Gates vertes → merge → release automatique avec le bump approprié.

Titre de MR et commits au format **Conventional Commits**. Seuls `feat` (minor),
`fix`/`perf` (patch) et `!` (major) déclenchent une release.

## Board

https://gitlab.com/__NAMESPACE__/__REPO__/-/boards — listes à portée `status::*`
(Open → `status::planifié` → `status::en-cours` → `status::intégré` → Closed).
`Closes #N` ne ferme l'issue qu'au merge du lot sur `main`.

## Gates de CI (MR vers `main`)

Chaque gate ne s'exécute que si les fichiers qui la concernent changent (`rules:changes` ;
une gate non déclenchée ne bloque pas la MR).

| Job | Vérifie |
|---|---|
__GATES_ROWS__
| `traceability` | titre de MR, issue référencée, cohérence semver |
| `exceptions-registry`, `trivy-fs` | registre d'exceptions, Trivy (vulnérabilités du dépôt) |
| SAST, Secret Detection, Dependency Scanning | templates GitLab (widgets de sécurité de la MR) |
| Aikido | intégration Aikido (SAST, secrets, dépendances) |

## Release (push sur `main`)

| Étape | Rôle |
|---|---|
| `detect` | bump semver depuis les commits depuis le dernier tag |
| `gate-version-consistency` | tag inexistant et supérieur au précédent |
<!-- >>> docker -->
| `image` | image Docker construite **une fois**, scannée (Trivy), publiée sur le Container Registry |
<!-- <<< docker -->
| `publish` | tag `vX.Y.Z` + GitLab Release (changelog) |

Lint, tests, SAST et SCA ne sont pas rejoués : ils ont tourné sur la MR de lot.

### Preflight

Nécessaire seulement si un job de la release n'est pas couvert par la CI de MR.

## Vérifications locales

```bash
__LOCAL_CHECKS__
```

## Secrets

- Local : `.env` (jamais commité, modèle `.env.example`).
- CI : variables CI/CD du projet ; `RELEASE_TOKEN` optionnel (jeton projet/groupe avec
  `write_repository`) si `CI_JOB_TOKEN` ne suffit pas à créer le tag.

## Exceptions de sécurité

Une alerte acceptée temporairement est inscrite dans `.gitlab/security-exceptions.yml`
(justification, auteur, date d'expiration) et reportée dans `.trivyignore`. Une exception
expirée fait échouer la CI.
