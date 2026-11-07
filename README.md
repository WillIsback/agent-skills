# agent-skills

Skills d'agent au format [Agent Skills](https://agentskills.io) (`SKILL.md` + frontmatter YAML),
utilisables avec Claude Code, opencode et tout agent compatible.

| Skill | Description |
|---|---|
| [`semver-batch-workflow`](skills/semver-batch-workflow/SKILL.md) | Workflow Git/GitHub par lots de version semver : epics et issues typées (sous-issues), board kanban GitHub Projects, ordre patch → minor → major, branche de lot et sous-branches par issue, PR unique vers `main`, preflight conditionnel, gates CI optimisées en temps, release automatique avec bump. |

## Installation

### Tous agents (CLI `skills`)

```bash
npx skills add WillIsback/agent-skills
```

### Claude Code (marketplace de plugins)

```text
/plugin marketplace add WillIsback/agent-skills
/plugin install semver-batch-workflow@willisback-skills
```

### Manuel

Copier `skills/<nom>/` dans `~/.agents/skills/` (opencode, agents génériques)
ou `~/.claude/skills/` (Claude Code).

## Licence

MIT
