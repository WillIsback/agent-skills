# agent-skills

Skills d'agent au format [Agent Skills](https://agentskills.io) (`SKILL.md` + frontmatter YAML),
utilisables avec Claude Code, opencode et tout agent compatible.

| Skill | Description |
|---|---|
| [`semver-batch-workflow`](skills/semver-batch-workflow/SKILL.md) | Workflow Git/GitHub par lots de version semver : epics et issues typées (sous-issues), board kanban GitHub Projects, ordre patch → minor → major, branche de lot et sous-branches par issue, PR unique vers `main`, preflight conditionnel, gates CI optimisées en temps, release automatique avec bump. |
| [`semver-repo-setup`](skills/semver-repo-setup/SKILL.md) | Mise en place de bout en bout d'un dépôt avec ce workflow : génération de l'outillage (profil `python-uv`, option Docker), dépôt et réglages GitHub, protection de `main`, Project kanban, backlog epics → user stories en lots datés. |
| [`agent-team`](skills/agent-team/SKILL.md) | Équipe de sessions d'agents sur un même projet (orchestrateur, builder, testeur) : rôles, format des messages et accusés de réception, rédacteur unique, frontières de permission, escalade vers l'humain, délégation des vérifications (🤖/👤). Le projet fournit un fichier de rôle par session. |
| [`oc-project`](skills/oc-project/SKILL.md) | Orchestration d'un projet OpenClassrooms (parcours AIE ou DIA) : cadrage depuis les PDF du projet (mission, livrables et soutenance, fiche d'auto-évaluation), matrice d'objectifs et répartition 👤/🤖, dépôt et kanban via `semver-repo-setup`, session de specs (ADR, schémas Mermaid), livraison lot par lot via `semver-batch-workflow` avec oral blanc obligatoire avant chaque fusion, répétition générale de la soutenance. |
| [`oc-oral-blanc`](skills/oc-oral-blanc/SKILL.md) | Oral blanc de soutenance : l'agent joue l'évaluateur, pose des questions ancrées dans le code et les décisions du projet, évalue sans complaisance, bascule en mode apprentissage (explications, exercices) et valide la porte de fusion (`oc-gate`) seulement quand tout est maîtrisé. |

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
/plugin install agent-team@willisback-skills
/plugin install oc-project@willisback-skills
/plugin install oc-oral-blanc@willisback-skills
```

### Manuel

Copier `skills/<nom>/` dans `~/.agents/skills/` (opencode, agents génériques)
ou `~/.claude/skills/` (Claude Code).

## Hooks de oc-project (Claude Code)

`oc-project` fournit deux hooks : un déclencheur (« OC » en majuscules et isolé, ou
« openclassroom(s) » → invoquer le skill) et une porte qui refuse `gh pr merge` sur une PR
de lot ou de specs tant que l'oral blanc n'est pas validé pour son SHA de tête. Après
installation des skills :

```bash
~/.agents/skills/oc-project/scripts/install-hooks.sh   # idempotent, sauvegarde settings.json
```

Les skills fonctionnent aussi sans hooks (autres agents) : la règle de porte est écrite
dans leurs instructions.

## Tests

```bash
bash tests/run.sh   # hooks, installation, structure de tous les skills
```

## Licence

MIT
