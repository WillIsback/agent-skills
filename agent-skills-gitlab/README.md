# agent-skills-gitlab

Variante **GitLab + OpenCode** des [agent-skills](https://github.com/WillIsback/agent-skills)
de William Derue. Mêmes méthodes de travail, portées sur **GitLab** (au lieu de GitHub) et le
harness **OpenCode V2** (au lieu de Claude Code). Format [Agent Skills](https://agentskills.io)
(`SKILL.md` + frontmatter YAML), utilisable avec OpenCode, `opencode`/`~/.agents/skills` et tout
agent compatible.

| Skill | Description |
|---|---|
| [`semver-batch-workflow`](skills/semver-batch-workflow/SKILL.md) | Workflow Git/GitLab par lots de version semver : epics et issues typées, board kanban GitLab (labels à portée `status::*`), ordre patch → minor → major, branche de lot et sous-branches par issue, MR unique vers `main`, preflight conditionnel, gates CI optimisées en temps, release automatique avec bump. |
| [`semver-repo-setup`](skills/semver-repo-setup/SKILL.md) | Mise en place de bout en bout d'un dépôt GitLab avec ce workflow : génération de l'outillage (profil `python-uv`, option Docker), projet et réglages GitLab via `glab`, protection de `main`, board, backlog epics → user stories en lots datés. |
| [`agent-team`](skills/agent-team/SKILL.md) | Équipe de sessions d'agents sur un même projet (orchestrateur, builder, testeur) : rôles, format des messages et accusés de réception, rédacteur unique, frontières de permission, escalade vers l'humain, délégation des vérifications (🤖/👤). Le projet fournit un fichier de rôle par session. |
| [`secops-swarm`](skills/secops-swarm/SKILL.md) | Audit de sécurité offensif d'une application **autorisée**, mené par un swarm d'agents piloté par un Chef SecOps : porte d'autorisation, reconnaissance puis attaque répartie par axes (OWASP), consolidation et compte rendu à l'humain, puis transmission des findings à un agent Juriste qui rédige le rapport circonstancié. S'appuie sur `agent-team`. |
| [`beta-metrics`](skills/beta-metrics/SKILL.md) | Cadrage d'une bêta de test centrée sur la promesse de valeur : promesse falsifiable, LA métrique (comportement observable mesuré avant l'intervention, rapporté à un volume), mesure avant/après avec groupe de comparaison, export anonyme sans contenu (vie privée par conception, test de garde), page de transparence, engagement à publier un résultat décevant. S'appuie sur `semver-batch-workflow` et `agent-team`. |

> **Périmètre de cette variante** : les 5 skills d'infrastructure. La paire OpenClassrooms
> (`oc-project`, `oc-oral-blanc`) du dépôt d'origine, très liée aux hooks Claude Code et à la
> porte de merge GitHub, n'est pas incluse.

## Ce qui change par rapport à la variante GitHub/Claude Code

| GitHub / Claude Code | GitLab / OpenCode (ici) |
|---|---|
| `gh` | `glab` |
| Pull Request (PR) | Merge Request (MR) |
| GitHub Projects (board + champ Status) | Board GitLab piloté par labels à portée `status::*` |
| GitHub Actions (`.github/workflows/`) | GitLab CI/CD (`.gitlab-ci.yml` + `.gitlab/ci/*.yml`) |
| GHCR (`ghcr.io`) | Container Registry GitLab (`$CI_REGISTRY_IMAGE`) |
| CodeQL | GitLab SAST (template) |
| Dependency Review | GitLab Dependency Scanning (template) |
| Dependabot | Renovate (`renovate.json`) |
| sous-issues GitHub | issues enfants / éléments liés (epics de groupe = Premium) |
| templates d'issue YAML | templates Markdown `.gitlab/issue_templates/` |
| `CLAUDE.md` | `AGENTS.md` (lu nativement par OpenCode) |
| `.claude/settings.json` + `.mcp.json` | `opencode.json` (`mcp.servers`, permissions) |
| `.claude-plugin/` + `marketplace.json` | distribution npm / dossiers / catalogue (pas de manifeste) |

## Démarrer un nouveau projet

Installer les skills une fois (voir ci-dessous), puis dans le dossier du projet demander à
l'agent (OpenCode…) :

> Prépare ce dépôt GitLab avec mon workflow semver. Brief : …

## Installation (OpenCode)

OpenCode découvre les skills dans plusieurs dossiers. Trois options :

### a) CLI `skills` (tous agents, dont OpenCode via `~/.agents/skills`)

```bash
npx skills add WillIsback/agent-skills-gitlab --all
```

### b) Pointer `opencode.json` vers le dépôt cloné

```jsonc
// opencode.json (projet ou ~/.config/opencode/)
{
  "$schema": "https://opencode.ai/config.json",
  "skills": ["~/code/agent-skills-gitlab/skills"]
}
```

### c) Manuel

Copier `skills/<nom>/` dans `~/.config/opencode/skills/` (global) ou `.opencode/skills/`
(projet). OpenCode lit aussi `~/.claude/skills` et `.claude/skills` par compatibilité.

Un exemple de configuration (skills + serveur MCP CodeGraph) est fourni dans
[`opencode.example.jsonc`](opencode.example.jsonc).

## Outillage généré (semver-repo-setup)

Le skill `semver-repo-setup` génère pour un nouveau dépôt : `.gitlab-ci.yml` + `.gitlab/ci/*`
(qualité, test, sécurité, traçabilité, release), templates d'issue et de MR, `renovate.json`,
`opencode.json`, `AGENTS.md`, `CONTRIBUTING.md`, registre d'exceptions de sécurité, et pour le
profil `python-uv` l'outillage ruff/mypy/pytest (option `--docker` : API FastAPI + image sur le
Container Registry). Les réglages GitLab (projet, labels, variables CI/CD, milestones, board,
protection de `main`) sont posés par `scripts/gitlab-setup.sh` (via `glab`).

Prérequis : `glab` authentifié (scopes `api`, `write_repository`), `uv`, `jq`, `python3`.

## Tests

```bash
bash tests/run.sh   # lint des skills, syntaxe des scripts, scaffold (2 variantes)
```

## Licence

MIT — William Derue.
