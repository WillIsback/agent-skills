# Skills oc-project et oc-oral-blanc — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** livrer dans `WillIsback/agent-skills` deux skills, `oc-project` (orchestration d'un projet OpenClassrooms, du cadrage à la soutenance) et `oc-oral-blanc` (oral blanc avec porte de compréhension), plus deux hooks Claude Code et leur script d'installation.

**Architecture :** un `SKILL.md` aiguilleur court lit `.oc/state.md` et charge une référence par phase (cadrage, specs, livraison, répétition). L'oral blanc est un skill séparé. Les hooks sont des scripts bash + `jq` testés par des scripts bash autonomes, avec un `gh` simulé. L'installation se fait par liens symboliques (déjà en place pour le dépôt) et par `install-hooks.sh`.

**Tech Stack :** Markdown (format Agent Skills), bash 5, `jq`, `gh` CLI. Tests : scripts bash sous `tests/`, sans dépendance externe.

**Spec :** `docs/superpowers/specs/2026-11-21-oc-project-design.md` (à lire en entier avant toute tâche).

## Global Constraints

- Tout le contenu (skills, messages des hooks, commits, PR) est en **français**, accents compris.
- Format Agent Skills : `SKILL.md` avec un frontmatter `name` (égal au nom du dossier) et `description` (≤ 1024 caractères, en français, qui dit *quand* déclencher le skill).
- Le skill doit fonctionner **sans hooks** (autres agents) : la porte est aussi rappelée dans les instructions de `livraison.md` et d'`oc-oral-blanc`.
- Nommage des dépôts : `OC-{AIE|DIA}-P{n}-{Nom}`, où `{Nom}` est le titre officiel du projet dans le parcours.
- `.oc/` (sources PDF, `state.md`, `carnet.md`, `handoff-cadrage.md`) et `exercices/` sont **ignorés par git** dans les projets OC.
- Les PDF OC sont acceptés, **les exports HTML sont refusés** : vides (rendu JavaScript) et porteurs de données personnelles.
- Ligne de porte dans le carnet, exactement : `<!-- oc-gate: <id> validé <AAAA-MM-JJ> sha:<7 caractères> -->`, avec `<id>` = `v<X.Y.Z>` ou `specs`.
- Pas de SonarCloud dans les dépôts OC : l'analyse est faite par Aikido et CodeQL (déjà fournis par `semver-repo-setup`).
- Le dépôt agent-skills suit `semver-batch-workflow` : travail sur une branche (ici `feat/oc-project`, créée depuis `docs/oc-project-design`), PR unique vers `main`, commits Conventional Commits terminés par :
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_018APxuHrQBRfL47z4Eus6gS
  ```

## Review Focus

1. **Faux positifs du déclencheur** : `OCR`, `doc`, `Oc`, `bloc`, une URL contenant `oc` ne doivent rien injecter ; `OC P8`, `(OC)`, `OC:` et `projet OpenClassrooms` doivent l'injecter. → tests de la tâche 1.
2. **Porte trompée par un commit tardif** : un commit poussé après l'oral change le SHA de tête, et la porte doit alors refuser. → test `sha_perime` de la tâche 2.
3. **Porte qui bloque ce qu'elle ne doit pas** : `chore/outillage`, une PR Dependabot, une sous-branche `feat/0.3.0-xxx` et un dossier hors projet OC doivent passer. → tests de la tâche 2.
4. **`gh` en échec** (réseau, PR introuvable) : la porte doit refuser avec un message explicite, pas laisser passer en silence (il vaut mieux bloquer que fusionner sans oral). → test `gh_echec` de la tâche 2.
5. **Installation qui écrase la config** : `install-hooks.sh` lancé deux fois ne doit pas dupliquer les hooks, et doit conserver `codegraph prompt-hook` et toutes les autres clés de `settings.json`. → tests de la tâche 3.

---

## Structure des fichiers

```
skills/oc-project/
  SKILL.md
  references/{cadrage,specs,livraison,repetition,catalogue-parcours,conventions}.md
  assets/{brief,objectifs,spec,architecture,carnet,state}.md
  hooks/oc-trigger.sh
  hooks/oc-merge-gate.sh
  scripts/install-hooks.sh
skills/oc-oral-blanc/
  SKILL.md
  references/{grille,exercices}.md
tests/
  lib.sh                    # assert_eq, assert_contains, assert_empty, résumé
  test_oc_trigger.sh
  test_oc_merge_gate.sh
  test_install_hooks.sh
  test_skills_lint.sh       # structure de tous les skills du dépôt
  fixtures/gh-stub          # faux gh piloté par variables d'environnement
  run.sh                    # lance tous les test_*.sh, code de sortie ≠ 0 si un échec
```

---

### Tâche 1 : banc de test et hook déclencheur `oc-trigger.sh`

**Files :**
- Create : `tests/lib.sh`, `tests/run.sh`, `tests/test_oc_trigger.sh`, `skills/oc-project/hooks/oc-trigger.sh`

**Interfaces :**
- Produces : `tests/lib.sh` exporte `assert_eq <attendu> <obtenu> <nom>`, `assert_contains <aiguille> <texte> <nom>`, `assert_empty <texte> <nom>`, `finish` (affiche `N réussis, M échecs`, sort en 1 s'il y a un échec). `tests/run.sh` lance chaque `tests/test_*.sh` et sort en 1 si l'un échoue.
- Produces : `oc-trigger.sh` lit sur stdin le JSON du hook UserPromptSubmit (`{"prompt": "...", ...}`). En cas de détection, il écrit sur stdout
  `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Projet OpenClassrooms détecté : invoque le skill oc-project (il reprend le projet là où il en est)."}}` ; sinon il n'écrit rien. Il sort toujours en 0.

- [ ] **Étape 1 : écrire les tests qui échouent** (`tests/test_oc_trigger.sh`). Une fonction `run_trigger <prompt>` qui construit le JSON avec `jq -n --arg p "$1" '{prompt:$p}'` et le passe au script.
  - Positifs (`assert_contains "oc-project"`) : `"OC P8"`, `"on avance sur le projet OC"`, `"(OC) cadrage"`, `"OC: reprends"`, `"projet OpenClassrooms"`, `"openclassroom"`, `"OPENCLASSROOMS"`.
  - Négatifs (`assert_empty`) : `"OCR du PDF"`, `"mets à jour la doc"`, `"Oc"`, `"un bloc de code"`, `"https://example.com/oc/page"`, `"OCaml"`, `""`.
  - JSON valide : la sortie d'un positif passe `jq -e '.hookSpecificOutput.additionalContext'`.
- [ ] **Étape 2 : lancer et constater l'échec** — `bash tests/test_oc_trigger.sh` → échec (script absent).
- [ ] **Étape 3 : implémenter `oc-trigger.sh`.** Lecture du prompt avec `jq -r '.prompt // ""'`. Détection de `OC` sensible à la casse par la regex `(^|[^[:alnum:]_/])OC([^[:alnum:]_]|$)`. Le `/` est exclu à gauche pour qu'une URL ne déclenche pas ; `OCaml` est déjà exclu par `[^[:alnum:]_]` à droite. Détection de `openclassrooms?` insensible à la casse (`grep -qiE`). Sortie JSON construite avec `jq -n`. `set -u`, sans `set -e`, pour toujours sortir en 0.
- [ ] **Étape 4 : lancer et constater la réussite** — `bash tests/run.sh` → `0 échecs`.
- [ ] **Étape 5 : commit** — `git add tests skills/oc-project/hooks/oc-trigger.sh && git commit -m "feat(oc-project): hook déclencheur OC / openclassroom"` (avec les lignes d'attribution).

### Tâche 2 : hook de porte `oc-merge-gate.sh`

**Files :**
- Create : `skills/oc-project/hooks/oc-merge-gate.sh`, `tests/fixtures/gh-stub`, `tests/test_oc_merge_gate.sh`

**Interfaces :**
- Consumes : `tests/lib.sh` (tâche 1).
- Produces : `oc-merge-gate.sh` lit sur stdin le JSON PreToolUse (`{"tool_name":"Bash","tool_input":{"command":"..."},"cwd":"..."}`). Pour refuser, il écrit
  `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"<message>"}}` et sort en 0. Pour laisser passer, il n'écrit rien et sort en 0.
- Produces : `tests/fixtures/gh-stub` est un exécutable nommé `gh` placé en tête du `PATH` des tests. Pour `gh pr view …`, il renvoie `$GH_STUB_JSON` (ex. `{"headRefName":"feat/0.3.0","headRefOid":"3f2a9c1e…","baseRefName":"main"}`), ou sort en `$GH_STUB_EXIT` s'il est défini et non nul. Il ajoute ses arguments à `$GH_STUB_LOG`.

Règles (spec §8.4) :
1. Si `tool_name` ≠ `Bash`, ou si la commande ne contient pas `gh pr merge` → laisser passer.
2. Si `<cwd>/.oc/state.md` n'existe pas → laisser passer (hors projet OC).
3. PR : numéro tiré de `gh pr merge\s+([0-9]+)` s'il existe, et option `-R|--repo <x>` reprise si elle est présente. Appel : `gh pr view [<n>] [-R <x>] --json headRefName,headRefOid,baseRefName`. Si `gh` échoue → refuser : « Porte d'oral blanc : impossible de lire la PR (gh a échoué). Vérifier gh puis relancer. »
4. Identifiant de porte : `headRefName` qui correspond à `^(feat|fix|perf|major)/([0-9]+\.[0-9]+\.[0-9]+)$` **et** `baseRefName` = `main` → `v\2` ; `^docs/[0-9]+\.[0-9]+\.[0-9]+-specs$` → `specs` ; sinon → laisser passer.
5. Chercher dans `<cwd>/.oc/carnet.md` une ligne qui correspond à `oc-gate: <id> validé [0-9-]+ sha:([0-9a-f]{7})`. Si elle est absente, ou si le SHA ne correspond pas aux 7 premiers caractères de `headRefOid` (dernière occurrence de l'id) → refuser : « Porte d'oral blanc non validée pour <id> (SHA de tête <7car>) : lancer oc-oral-blanc sur cette PR avant de fusionner. »

- [ ] **Étape 1 : écrire les tests qui échouent.** Chaque test crée un projet temporaire (`mktemp -d`) avec `.oc/state.md`, et un carnet si nécessaire. Cas et attendus :
  - `hors_bash` : `tool_name` = `Read` → sortie vide.
  - `autre_commande` : `git push` → sortie vide.
  - `hors_projet` : `gh pr merge 5` sans `.oc/state.md` → sortie vide, et `gh` jamais appelé (`$GH_STUB_LOG` vide).
  - `outillage_exempte` : branche `chore/outillage` → sortie vide.
  - `dependabot_exempte` : branche `dependabot/pip/x-1.2` → sortie vide.
  - `sous_branche_exemptee` : branche `feat/0.3.0-durcir`, base `feat/0.3.0` → sortie vide.
  - `lot_sans_carnet` : branche `feat/0.3.0`, pas de carnet → `permissionDecision` = `deny`, et la raison contient `v0.3.0`.
  - `lot_valide` : carnet avec `<!-- oc-gate: v0.3.0 validé 2026-12-18 sha:3f2a9c1 -->`, `headRefOid` qui commence par `3f2a9c1` → sortie vide.
  - `sha_perime` : même carnet, `headRefOid` qui commence par `9999999` → `deny`.
  - `specs_valide` : branche `docs/0.2.0-specs`, carnet `oc-gate: specs validé … sha:<ok>` → sortie vide.
  - `autre_lot_ne_compte_pas` : carnet validé pour `v0.2.0` seulement, PR `feat/0.3.0` → `deny`.
  - `gh_echec` : `GH_STUB_EXIT=1` → `deny`, et la raison contient `gh a échoué`.
  - `numero_et_repo_transmis` : commande `gh pr merge 81 -R o/r --squash` → `$GH_STUB_LOG` contient `pr view 81 -R o/r`.
- [ ] **Étape 2 : lancer et constater l'échec** — `bash tests/test_oc_merge_gate.sh` → échecs.
- [ ] **Étape 3 : implémenter `oc-merge-gate.sh`** selon les règles 1 à 5 (bash + `jq`, regex avec `[[ =~ ]]`, sortie JSON avec `jq -n --arg`).
- [ ] **Étape 4 : lancer et constater la réussite** — `bash tests/run.sh` → `0 échecs`.
- [ ] **Étape 5 : commit** — `feat(oc-project): hook de porte d'oral blanc sur gh pr merge`.

### Tâche 3 : `install-hooks.sh`

**Files :**
- Create : `skills/oc-project/scripts/install-hooks.sh`, `tests/test_install_hooks.sh`

**Interfaces :**
- Consumes : chemins des hooks des tâches 1 et 2.
- Produces : `install-hooks.sh [--settings <chemin>]` (défaut `~/.claude/settings.json`). Il résout le dossier du skill avec `readlink -f`, puis ajoute :
  - `hooks.UserPromptSubmit[]` ← `{"hooks":[{"type":"command","command":"<abs>/hooks/oc-trigger.sh"}]}`
  - `hooks.PreToolUse[]` ← `{"matcher":"Bash","hooks":[{"type":"command","command":"<abs>/hooks/oc-merge-gate.sh"}]}`
  
  Chaque ajout n'est fait que si aucune entrée existante ne contient déjà cette commande. Le script fait une sauvegarde `settings.json.bak-oc` avant d'écrire, et une écriture atomique (fichier temporaire puis `mv`). Il crée le fichier `{}` s'il est absent. Il affiche ce qu'il a ajouté, ou « déjà installé ».

- [ ] **Étape 1 : écrire les tests qui échouent**, sur un `settings.json` temporaire qui contient déjà `env`, `permissions` et `hooks.UserPromptSubmit[0].hooks[0].command = "codegraph prompt-hook"` :
  - après une installation : 2 entrées `UserPromptSubmit` (codegraph + oc-trigger), 1 entrée `PreToolUse` avec `matcher` = `Bash` ; `env` et `permissions` identiques à l'original (comparaison `jq -S`) ;
  - après une deuxième installation : mêmes compteurs (idempotence), sortie qui contient `déjà installé` ;
  - fichier absent → créé, avec les 2 hooks ;
  - `settings.json.bak-oc` existe après la première écriture.
- [ ] **Étape 2 : lancer et constater l'échec.**
- [ ] **Étape 3 : implémenter `install-hooks.sh`.**
- [ ] **Étape 4 : lancer et constater la réussite** — `bash tests/run.sh`.
- [ ] **Étape 5 : commit** — `feat(oc-project): script d'installation idempotent des hooks`.

### Tâche 4 : lint des skills, aiguilleur `oc-project`, conventions, catalogue et modèles

**Files :**
- Create : `tests/test_skills_lint.sh`, `skills/oc-project/SKILL.md`, `skills/oc-project/references/conventions.md`, `skills/oc-project/references/catalogue-parcours.md`, `skills/oc-project/assets/{state,brief,objectifs,spec,architecture,carnet}.md`

**Interfaces :**
- Produces : `test_skills_lint.sh` vérifie, pour **chaque** `skills/*/SKILL.md` (les skills existants compris) : le frontmatter existe ; `name` = nom du dossier ; `description` non vide et ≤ 1024 caractères ; chaque chemin `references/…` ou `assets/…` cité dans un fichier du skill existe dans ce skill ; aucun fichier du skill ne contient `TODO` ni `TBD`.
- Produces : format de `assets/state.md`, utilisé par toutes les références :
  ```
  ---
  parcours: AIE            # AIE | DIA
  projet: 8
  depot: WillIsback/OC-AIE-P8-Confirmez-vos-competences-en-MLOps-Partie-2
  phase: cadrage           # cadrage | specs | livraison | repetition | termine
  lot: ""                  # ex. v0.3.0 pendant la livraison
  soutenance: 2027-01-11
  evaluateur: ""           # rôle joué, ex. « Chloé, Lead Data Scientist »
  ---
  ## Journal
  - AAAA-MM-JJ : <événement>
  ```

Contenu attendu :
- `SKILL.md` : la description déclenche sur « OC », « OpenClassrooms », un projet de `formation_OC/` et la reprise d'un projet OC. Corps d'au plus ~80 lignes :
  - détection du projet depuis le dossier (`formation_OC/<ai_engineer|dev_fullstack_ai>/P<n>_…` → AIE ou DIA, n) ;
  - lecture de `.oc/state.md` (absent → cadrage, ou mode reprise si des artefacts existent, spec §7.1) ;
  - annonce de la phase en une ligne, puis table phase → référence à charger ;
  - règles transverses : français, une question à la fois, jamais de merge sans porte, 👤 jamais fait à la place de William, mise à jour de `state.md` à chaque transition ;
  - délégation explicite à `semver-repo-setup` (cadrage, étape 5) et à `semver-batch-workflow` (livraison).
- `conventions.md` : nommage des dépôts, arborescence locale, contenu de `.oc/` et `.gitignore`, sémantique 👤/🤖 (avec la règle « indicateur *justifier / interpréter / définir* ⇒ part 👤 non vide »), format de la ligne `oc-gate`, pas de SonarCloud, format de nommage des livrables du zip (`Nom_Prenom_n°_livrable_mmaaaa`).
- `catalogue-parcours.md` : deux tableaux (n°, titre, charge, début, fin).
  - **DIA**, du P1 au P14, avec les titres et dates de la fiche de début de formation 2025 : P1 Démarrez votre formation de Développeur IA (11/07/2025) … P14 Développez une feature de revue de presse automatique (10/01/2026).
  - **AIE**, du P3 au P15, avec les charges et dates de la fiche 09/2026 (P3 40 h 04/09→17/09/2026 … P8 45 h 14/12/2026→11/01/2027 … P15 60 h 10/06→01/07/2027). Titres connus : P3 Anticipez les besoins en consommation de bâtiments de Seattle, P5 Déployez un modèle de Machine Learning, P6 Initiez-vous au MLOps (Partie 1/2), P7 Concevez et déployez un système RAG, P8 Confirmez vos compétences en MLOps (Partie 2/2), P11 Entraînez votre agent RL, P12 Extrayez des données multimodales de sites web, P14 Finetunez votre propre LLM. Les autres sont marqués « à compléter au cadrage ». P1 et P2 sont absents de la fiche : « à compléter ».
  - Une ligne d'instruction : quand le cadrage découvre un titre manquant, l'agent met à jour ce fichier dans le dépôt agent-skills par une PR `docs:`.
- Modèles `assets/` : squelettes avec en-têtes de sections et une ligne d'aide par section, conformes à la spec. `brief.md` (§7.2 étape 2) ; `objectifs.md` (tableau indicateur → livrable → user story → 👤 → 🤖) ; `spec.md` (vue d'ensemble + bloc ADR : Contexte / Options / Recommandation / Choix / Conséquences / Indicateurs / Question d'oral probable) ; `architecture.md` (trois blocs Mermaid vides : composants, séquence, déploiement) ; `carnet.md` (entrée de lot : version, PR, date, questions, niveaux, points travaillés, notes par indicateur, ligne `oc-gate`).

- [ ] **Étape 1 : écrire `tests/test_skills_lint.sh`**, puis le lancer : il échoue (`skills/oc-project/SKILL.md` absent). Les skills existants doivent passer ; s'ils ne passent pas, corriger le test plutôt que ces skills, sauf violation réelle.
- [ ] **Étape 2 : écrire `SKILL.md`, `conventions.md`, `catalogue-parcours.md` et les six modèles.**
- [ ] **Étape 3 : lancer** — `bash tests/run.sh` → `0 échecs`. Les références `cadrage.md`, `specs.md`, `livraison.md` et `repetition.md` citées dans `SKILL.md` n'existent pas encore : créer pour chacune un fichier d'une ligne « Rempli à la tâche 5 ou 6. » pour que le lint passe, puis le remplacer aux tâches 5 et 6. Ce texte ne contient ni `TODO` ni `TBD`.
- [ ] **Étape 4 : commit** — `feat(oc-project): aiguilleur, conventions, catalogue des parcours et modèles`.

### Tâche 5 : références de la partie 1, `cadrage.md` et `specs.md`

**Files :**
- Modify : `skills/oc-project/references/cadrage.md`, `skills/oc-project/references/specs.md`

**Interfaces :**
- Consumes : `assets/state.md`, `brief.md`, `objectifs.md`, `spec.md`, `architecture.md` (tâche 4) ; skill `semver-repo-setup`.
- Produces : la transition `phase: cadrage → specs` à la fin de `cadrage.md`, et `specs → livraison` à la fin de `specs.md` (après approbation de William).

Contenu (spec §7.2 et §7.3, à suivre point par point) :
- `cadrage.md` : mode reprise d'abord (inventaire de ce qui existe, pré-remplissage, validation), puis les étapes 1 à 5. Points à inclure explicitement :
  - refus des HTML avec la raison ;
  - l'étude de l'existant cherche les projets dépendants dans le catalogue et dans `formation_OC/`, et doit faire ressortir les « pièges qui changent le projet » ;
  - la matrice d'objectifs est validée par William avant la création du dépôt ;
  - le brief passé à `semver-repo-setup` contient : nom, description, stack, date cible, et dans chaque user story une section `Fiche : …` et `👤 Ta part` / `🤖 Délégué` ;
  - les ajouts au `.gitignore` (`.oc/`, `exercices/`) ;
  - l'initialisation de `.oc/carnet.md` depuis le modèle ;
  - `evaluateur:` est rempli dans `state.md` à partir de la page soutenance.
- `specs.md` :
  - une décision à la fois, au format ADR complet ;
  - ordre des décisions par dépendances ;
  - mise à jour du backlog si une décision le modifie ;
  - livrables `docs/spec.md` et `docs/architecture.md` (minimum composants, séquence, déploiement ; classes seulement s'il y a un modèle de domaine) ;
  - commit sur `docs/<X.Y.Z>-specs`, PR `docs:`, **porte `specs` via oc-oral-blanc** avant le merge.

- [ ] **Étape 1 : rédiger `cadrage.md`.**
- [ ] **Étape 2 : rédiger `specs.md`.**
- [ ] **Étape 3 : relecture croisée avec la spec** : chaque point listé ci-dessus est présent (le vérifier avec `grep` sur les mots-clés `HTML`, `reprise`, `Ta part`, `Délégué`, `exercices/`, `evaluateur`, `ADR`, `Mermaid`, `specs`). Puis `bash tests/run.sh` → `0 échecs`.
- [ ] **Étape 4 : commit** — `feat(oc-project): phases cadrage et session de specs`.

### Tâche 6 : références de la partie 2, `livraison.md` et `repetition.md`

**Files :**
- Modify : `skills/oc-project/references/livraison.md`, `skills/oc-project/references/repetition.md`

**Interfaces :**
- Consumes : skill `semver-batch-workflow`, skill `oc-oral-blanc` (tâche 7, référencé par son nom), `assets/carnet.md`.
- Produces : les transitions `livraison → repetition` (après le dernier lot) et `repetition → termine`.

Contenu (spec §8.1 et §8.5) :
- `livraison.md` : la boucle en 6 étapes. Règle 👤 : l'agent prépare, explique, guide et relit, mais ne fait pas. La porte est rappelée en clair même sans hook : « ne jamais lancer `gh pr merge` sans ligne `oc-gate` valide pour le SHA de tête ». Après le merge : vérification de la release, mise à jour de `state.md` (`lot:`) et du carnet.
- `repetition.md` : checklist préalable (démos imposées tirées du brief, fiche entièrement cochée, notes comprises), simulation chronométrée au format de la page soutenance (l'agent annonce les repères de temps), interruptions dans le rôle, débrief, plan de présentation tiré du carnet, liste nommée des livrables du zip.

- [ ] **Étape 1 : rédiger `livraison.md`.**
- [ ] **Étape 2 : rédiger `repetition.md`.**
- [ ] **Étape 3 : vérification** — `grep -n "gh pr merge" livraison.md` trouve la règle de porte ; `bash tests/run.sh` → `0 échecs`.
- [ ] **Étape 4 : commit** — `feat(oc-project): phases livraison et répétition générale`.

### Tâche 7 : skill `oc-oral-blanc`

**Files :**
- Create : `skills/oc-oral-blanc/SKILL.md`, `skills/oc-oral-blanc/references/grille.md`, `skills/oc-oral-blanc/references/exercices.md`

**Interfaces :**
- Consumes : `.oc/state.md` (`evaluateur:`, `lot:`), `.oc/carnet.md`, `docs/brief.md`, `docs/spec.md`, le diff de la PR (`gh pr diff <n>`).
- Produces : l'entrée de lot dans `.oc/carnet.md` (format de `assets/carnet.md`), terminée par la ligne `oc-gate` avec le SHA de tête **lu au moment de la validation** (`gh pr view <n> --json headRefOid`).

Contenu (spec §8.2) :
- `SKILL.md` :
  - description qui déclenche sur « oral blanc », « révise-moi », « prépare ma soutenance », et sur l'appel par oc-project ;
  - les deux modes : PR de lot (avec porte) et autonome sur un ancien projet (amorçage minimal, mode dégradé annoncé, pas de porte) ;
  - le rôle tenu ;
  - 3 à 6 questions ancrées, une à la fois, chacune citant un fichier, une décision ou un résultat ;
  - l'évaluation après chaque réponse ;
  - la bascule en mode apprentissage (sortie du rôle, échange socratique, exercice éventuel dans `exercices/`, question reposée sous un autre angle) ;
  - la sortie (porte uniquement si tout est « maîtrisé ») ;
  - **interdits** : questions génériques, plusieurs questions à la fois, « maîtrisé » accordé sans le quoi, le pourquoi et une conséquence ou une alternative, écrire la ligne `oc-gate` avant la fin.
- `grille.md` : définitions de maîtrisé, partiel et à revoir, avec un exemple de réponse pour chaque niveau sur une question MLOps (ex. « pourquoi charger le modèle au démarrage ? »).
- `exercices.md` : types d'exercices par domaine (tests, API et validation, Docker, CI/CD, données et drift, performance et profiling, ML), chacun avec sa consigne et son critère de réussite. Un exercice dure au plus 15 minutes.

- [ ] **Étape 1 : rédiger les trois fichiers.**
- [ ] **Étape 2 : vérification** — `bash tests/run.sh` (le lint couvre le nouveau skill) → `0 échecs` ; `grep -n "oc-gate" skills/oc-oral-blanc/SKILL.md` montre le format exact de la Global Constraint.
- [ ] **Étape 3 : commit** — `feat(oc-oral-blanc): oral blanc avec porte de compréhension`.

### Tâche 8 : publication, installation et essai réel

**Files :**
- Modify : `.claude-plugin/marketplace.json`, `README.md`

**Interfaces :**
- Consumes : tout ce qui précède.

- [ ] **Étape 1 : marketplace.** Ajouter deux plugins sur le modèle des entrées existantes (`"source": "./"`, `"strict": false`, `"skills": ["./skills/oc-project"]` et `["./skills/oc-oral-blanc"]`), avec des descriptions en français. Vérifier avec `jq -e . .claude-plugin/marketplace.json`.
- [ ] **Étape 2 : README.** Deux lignes dans le tableau des skills, plus une section « Hooks de oc-project » qui indique de lancer `~/.agents/skills/oc-project/scripts/install-hooks.sh` après l'installation, et de lancer les tests avec `bash tests/run.sh`.
- [ ] **Étape 3 : liens symboliques locaux.** `ln -sfn ~/work/agent-skills/skills/oc-project ~/.agents/skills/oc-project`, puis `ln -sfn ../../.agents/skills/oc-project ~/.claude/skills/oc-project`. Même chose pour `oc-oral-blanc`. Vérifier avec `readlink -f`.
- [ ] **Étape 4 : installer les hooks pour de vrai** — `~/.agents/skills/oc-project/scripts/install-hooks.sh` ; vérifier que `jq '.hooks' ~/.claude/settings.json` contient codegraph, oc-trigger et oc-merge-gate, et que `settings.json.bak-oc` existe.
- [ ] **Étape 5 : essai réel des hooks** :
  - `echo '{"prompt":"OC P8"}' | ~/.claude/skills/oc-project/hooks/oc-trigger.sh` → JSON avec `oc-project` ;
  - `echo '{"tool_name":"Bash","tool_input":{"command":"gh pr merge 1"},"cwd":"/tmp"}' | …/oc-merge-gate.sh` → sortie vide (hors projet OC).
- [ ] **Étape 6 : commit, PR et merge selon `semver-batch-workflow`** : commit `docs: publication des skills oc-project et oc-oral-blanc` ; PR `feat: skills oc-project et oc-oral-blanc` vers `main` (bump minor), qui inclut la spec et ce plan ; `gh pr checks --watch` ; **William fusionne**.

### Tâche 9 : préparation du pilote P8

**Files :**
- Create (non versionnés, dans `/home/will/formation_OC/ai_engineer/P8_Confirmez_vos_compétences_en_MLOps_Partie_2/`) : `.oc/sources/` (les 3 PDF), `.oc/handoff-cadrage.md`

**Interfaces :**
- Consumes : le mode reprise de `cadrage.md` (tâche 5).

- [ ] **Étape 1 : copier les PDF** depuis `/home/will/.claude/uploads/252db0b6-3d9b-4a70-9515-802ca3f168a5/` vers `.oc/sources/` sous des noms lisibles : `mission.pdf` (fichier `*Confirmez_vos_comp_tences*OpenClassrooms.pdf`, le plus récent), `livrables-soutenance.pdf` (fichier `c9b566ea-livrable`) et `fiche-auto-evaluation.pdf` (fichier `*Fichedauto*.pdf`, le plus récent). Vérifier avec `file` que ce sont bien des PDF.
- [ ] **Étape 2 : rédiger `.oc/handoff-cadrage.md`** à partir de la conversation d'origine, en reprenant les points établis :
  - **existant P6** : wrapper pyfunc `home-credit-serving` v2 (encodeur ordinal + LightGBM sur 122 features + seuil 0,5348), `clients.db` SQLite de 48 744 clients du jeu de test, app Gradio, latence ~22 ms en régime établi et 113 ms au premier appel, artefacts non versionnés (`mlflow-artifacts/` 50 Mo, `data/inference` 49 Mo), build Docker jamais lancé ;
  - **standards P5** : FastAPI + JWT, PostgreSQL et Alembic, Grafana, GHCR, Space HF, une dizaine de workflows, release semver ;
  - **objectifs** : les 8 livrables et indicateurs de la fiche ;
  - **répartition 👤/🤖** : le tableau de la conversation ;
  - **pièges** : contrat d'entrée de l'API (features OpenFE sans plage naturelle), drift naturel `bureau_balance` (couverture de 30 % sur le train contre 87 % sur le test), pas de `TARGET` dans le jeu de test, faible marge d'optimisation (LightGBM < 10 ms : le coût est dans le serveur et pandas) ;
  - **décision ouverte pour la session de specs** : contrat de l'API, option B recommandée ;
  - **soutenance** : 11/01/2027, évaluateur « Chloé Dubois, Lead Data Scientist », démos imposées et 3 axes de discussion.
- [ ] **Étape 3 : vérification** — `ls .oc/sources` montre 3 PDF ; le handoff couvre les 7 rubriques ci-dessus. Pas de commit : ce dossier n'est pas encore un dépôt et `.oc/` sera ignoré par git.
