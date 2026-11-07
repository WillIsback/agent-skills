# agent-skills

Skills d'agent au format [Agent Skills](https://agentskills.io) (`SKILL.md` + frontmatter YAML),
utilisables avec Claude Code, opencode et tout agent compatible.

| Skill | Description |
|---|---|
| [`semver-batch-workflow`](skills/semver-batch-workflow/SKILL.md) | Workflow Git/GitHub par lots de version semver : epics et issues typées (sous-issues), board kanban GitHub Projects, ordre patch → minor → major, branche de lot et sous-branches par issue, PR unique vers `main`, preflight conditionnel, gates CI optimisées en temps, release automatique avec bump. |
| [`semver-repo-setup`](skills/semver-repo-setup/SKILL.md) | Mise en place de bout en bout d'un dépôt avec ce workflow : génération de l'outillage (profil `python-uv`, option Docker), dépôt et réglages GitHub, protection de `main`, Project kanban, backlog epics → user stories en lots datés. |

## Démarrer un nouveau projet

```bash
npx skills add WillIsback/agent-skills -g --all     # une fois par machine (tous les skills, tous les agents)
```

Puis, dans le dossier du projet, demander à l'agent (Claude Code, opencode…) :

> Prépare ce dépôt avec mon workflow semver. Brief : …

## Installation

### Tous agents (CLI `skills`)

```bash
npx skills add WillIsback/agent-skills
```

### Claude Code (marketplace de plugins)

```text
/plugin marketplace add WillIsback/agent-skills
/plugin install semver-batch-workflow@willisback-skills
/plugin install semver-repo-setup@willisback-skills
```

### Manuel

Copier `skills/<nom>/` dans `~/.agents/skills/` (opencode, agents génériques)
ou `~/.claude/skills/` (Claude Code).

## Licence

MIT
