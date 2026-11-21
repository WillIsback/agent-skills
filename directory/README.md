# WillIsback Skills

Plugin de skills d'agent au format [Agent Skills](https://agentskills.io), publié sur le
**Claude plugin directory**. Il regroupe les skills de WillIsback qui ne contiennent que du
Markdown, donc publiables sans statut d'organisation vérifiée :

- **`semver-batch-workflow`** — workflow Git/GitHub par lots de version semver : issues typées,
  board kanban GitHub Projects, ordre patch → minor → major, branche de lot et sous-branches,
  PR unique vers `main`, gates CI optimisées, release automatique.
- **`agent-team`** — protocole d'une équipe de sessions d'agents (orchestrateur, builder,
  testeur) : messages, accusés de réception, rédacteur unique, frontières de permission.
- **`secops-swarm`** — audit de sécurité offensif d'une application **autorisée** mené par un
  swarm d'agents piloté par un Chef SecOps, puis rapport circonstancié rédigé par un agent
  Juriste.
- **`oc-oral-blanc`** — oral blanc de soutenance : l'agent joue l'évaluateur, interroge sur le
  code et les décisions du projet, et valide la porte de fusion.

## Pourquoi ce sous-dossier ?

Le dépôt complet (`WillIsback/agent-skills`) contient aussi `semver-repo-setup` et `oc-project`,
qui embarquent des scripts et des gabarits. Le Directory n'accepte ces fichiers que d'une
organisation **Vérifiée**. Ce sous-dossier `directory/` isole donc les skills 100 % Markdown
pour une publication immédiate ; les deux autres rejoindront le listing une fois la
vérification d'organisation obtenue. Les quatre `SKILL.md` ici sont des copies conformes de
ceux de `skills/`, tenues synchrones par `tests/test_directory_sync.sh`.

## Installation

Via le Claude plugin directory (une fois publié), ou depuis le dépôt :

```text
/plugin install willisback-skills --marketplace WillIsback/agent-skills
```

## Licence

MIT
