# Contribuer

## Flux de travail

Le dépôt suit le workflow « lots de version semver »
([skill `semver-batch-workflow`](https://github.com/WillIsback/agent-skills)) :

1. Une **issue** par changement (modèles : bug, feature, refactor, docs, chore) ; les
   epics regroupent les user stories en sous-issues.
2. Les issues sont regroupées en **lots** (milestones), un lot = la prochaine version,
   traités dans l'ordre **patch → minor → major**.
3. Branche de lot `<type>/<version>` (ex. `feat/0.2.0`) créée depuis `main`.
4. Chaque issue sur une sous-branche `<type>/<version>-<tâche>`, fusionnée dans la
   branche de lot par `<type>: merge <type>/<version>-<tâche> (#N)`.
5. Lot complet (et preflight si nécessaire) → **une PR vers `main`** suivant le
   [modèle de PR](.github/PULL_REQUEST_TEMPLATE.md). Jamais de merge direct sur `main`.
6. Gates vertes → merge → release automatique avec le bump approprié.

Titre de PR et commits au format **Conventional Commits**. Seuls `feat` (minor),
`fix`/`perf` (patch) et `!` (major) déclenchent une release.

## Board

https://github.com/users/__OWNER__/projects/__PROJECT_NUMBER__ — colonnes Backlog → Planifié →
En cours → Intégré au lot → Fait. `Closes #N` ne ferme l'issue qu'au merge du lot sur `main`.

## Gates de CI (PR vers `main`)

Chaque gate ne s'exécute que si les fichiers qui la concernent changent (un job ignoré
compte comme réussi pour la protection de branche).

| Workflow | Vérifie |
|---|---|
__GATES_ROWS__
| `ci-security` | Dependency Review (licences), registre d'exceptions, Trivy, Gitleaks |
| `ci-traceability` | issue référencée, type de PR, cohérence semver |
| Aikido | app GitHub Aikido (SAST, secrets, dépendances) |

## Release (push sur `main`)

| Étape | Rôle |
|---|---|
| `detect` | bump semver depuis les commits depuis le dernier tag |
| `gate-version-consistency` | tag inexistant et supérieur au précédent |
<!-- >>> docker -->
| `image` | image Docker construite **une fois**, scannée (Trivy), publiée sur GHCR, attestée |
<!-- <<< docker -->
| `publish` | tag `vX.Y.Z` + GitHub Release (changelog) |

Lint, tests, CodeQL et SCA ne sont pas rejoués : ils ont tourné sur la PR de lot.

### Preflight

Nécessaire seulement si un job de la release n'est pas couvert par la CI de PR.

## Vérifications locales

```bash
__LOCAL_CHECKS__
```

## Secrets

- Local : `.env` (jamais commité, modèle `.env.example`).
- CI : secrets de dépôt ; `RELEASE_TOKEN` optionnel (jeton à grain fin Contents +
  Workflows en écriture, voir `release.yml`).

## Exceptions de sécurité

Une alerte acceptée temporairement est inscrite dans `.github/security-exceptions.yml`
(justification, auteur, date d'expiration) et reportée dans `.trivyignore`. Une exception
expirée fait échouer la CI.
