# agent-skills

Skills d'agent au format [Agent Skills](https://agentskills.io) (`SKILL.md` + frontmatter YAML),
utilisables avec Claude Code, opencode et tout agent compatible.

| Skill | Description |
|---|---|
| [`semver-batch-workflow`](skills/semver-batch-workflow/SKILL.md) | Workflow Git/GitHub par lots de version semver : epics et issues typées (sous-issues), board kanban GitHub Projects, ordre patch → minor → major, branche de lot et sous-branches par issue, PR unique vers `main`, preflight conditionnel, gates CI optimisées en temps, release automatique avec bump. |
| [`semver-repo-setup`](skills/semver-repo-setup/SKILL.md) | Mise en place de bout en bout d'un dépôt avec ce workflow : génération de l'outillage (profil `python-uv`, option Docker), dépôt et réglages GitHub, protection de `main`, Project kanban, backlog epics → user stories en lots datés. |
| [`agent-team`](skills/agent-team/SKILL.md) | Équipe de sessions d'agents sur un même projet (orchestrateur, builder, testeur) : rôles, format des messages et accusés de réception, rédacteur unique, frontières de permission, escalade vers l'humain, délégation des vérifications (🤖/👤). Le projet fournit un fichier de rôle par session. |
| [`secops-swarm`](skills/secops-swarm/SKILL.md) | Audit de sécurité offensif d'une application **autorisée**, mené par un swarm d'agents piloté par un Chef SecOps : porte d'autorisation, reconnaissance puis attaque répartie par axes (OWASP : authn/authz, injection, secrets, config, dépendances, logique métier), consolidation et compte rendu à l'humain, puis transmission des findings à un agent Juriste qui rédige le rapport circonstancié. S'appuie sur `agent-team`. |
| [`oc-project`](skills/oc-project/SKILL.md) | Orchestration d'un projet OpenClassrooms (parcours AIE ou DIA) : cadrage depuis les PDF du projet (mission, livrables et soutenance, fiche d'auto-évaluation), matrice d'objectifs et répartition 👤/🤖, dépôt et kanban via `semver-repo-setup`, session de specs (ADR, schémas Mermaid), livraison lot par lot via `semver-batch-workflow` avec oral blanc obligatoire avant chaque fusion, répétition générale de la soutenance. |
| [`oc-oral-blanc`](skills/oc-oral-blanc/SKILL.md) | Oral blanc de soutenance : l'agent joue l'évaluateur, pose des questions ancrées dans le code et les décisions du projet, évalue sans complaisance, bascule en mode apprentissage (explications, exercices) et valide la porte de fusion (`oc-gate`) seulement quand tout est maîtrisé. |
| [`beta-metrics`](skills/beta-metrics/SKILL.md) | Cadrage d'une bêta de test centrée sur la promesse de valeur : reformuler la promesse en une phrase falsifiable, séparer l'éprouvé du jamais vérifié, trouver LA métrique (comportement observable mesuré avant l'intervention, rapporté à un volume) en écartant les fausses métriques, mesure avant/après avec groupe de comparaison au même seuil, export anonyme sans aucun contenu (vie privée par conception, test de garde) et outil d'agrégation, page de transparence pour décideur et testeur, engagement à publier un résultat décevant. S'appuie sur `semver-batch-workflow` et `agent-team`. |

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

Les sept skills sont regroupés dans un plugin unique `willisback-skills` : une seule
installation les embarque tous (ils restent chargés à la demande, selon leur description).

```text
/plugin install willisback-skills --marketplace WillIsback/agent-skills
```

En deux étapes (Claude Code < 2.1.275) :

```text
/plugin marketplace add WillIsback/agent-skills
/plugin install willisback-skills@willisback-skills
```

### Claude plugin directory

Le dossier [`directory/`](directory/) est un plugin à part, limité aux **3 skills autonomes
100 % Markdown** (`semver-batch-workflow`, `agent-team`, `secops-swarm`), publiable au
[Claude plugin directory](https://claude.ai/directory) sans statut d'organisation vérifiée.
`semver-repo-setup` (scripts/gabarits) et la paire `oc-project` + `oc-oral-blanc` ne sont
acceptés que d'une organisation **Vérifiée** ; ils rejoindront le listing après vérification.

Pour soumettre : `claude.ai/directory/manage` → **Submit new** → **Plugin bundle** → dépôt
`WillIsback/agent-skills`, *Plugin path* = `directory`. Le test `tests/test_directory_sync.sh`
garantit que les `SKILL.md` de `directory/` restent des copies conformes de ceux de `skills/`.

### Manuel

Copier `skills/<nom>/` dans `~/.agents/skills/` (opencode, agents génériques)
ou `~/.claude/skills/` (Claude Code).

## Hooks de oc-project (Claude Code)

`oc-project` fournit deux hooks : un déclencheur (« OC » en majuscules et isolé, ou
« openclassroom(s) » → invoquer le skill) et une porte qui refuse `gh pr merge` sur une PR
de lot ou de specs tant que l'oral blanc n'est pas validé pour son SHA de tête. Après
installation des skills, lancer le script depuis le dossier où `oc-project` est installé :

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
