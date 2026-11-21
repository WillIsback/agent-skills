# Design — skills `oc-project` et `oc-oral-blanc`

Date : 2026-11-21 · Auteur : William Derue (WillIsback) · Statut : relu (builder check), en attente de validation finale

## 1. Intention

William suit deux parcours OpenClassrooms : **AI Engineer (AIE, 15 projets)**, actuellement au
projet 8, et **Développeur IA (DIA, 14 projets, terminé)**. Chaque projet se valide par une
soutenance où un évaluateur, dans un rôle du scénario, juge les livrables avec une grille,
la fiche d'auto-évaluation.

Il veut une **orchestration réutilisable pour tous ses projets OC**, qui :

1. fasse le cadrage du projet, crée le dépôt et le kanban, puis mène une session de specs
   jusqu'à une documentation technique (**partie 1**) ;
2. produise le code lot par lot, avec l'humain dans la boucle à chaque PR vers `main`
   (**partie 2**) ;
3. surtout, **verrouille les connaissances** : à chaque PR de lot, l'agent joue l'évaluateur
   et pose des questions de soutenance. Si William cale, on bascule en mode apprentissage
   (explications, exercices) et **rien n'est fusionné tant que ce qui est commité n'est pas
   compris**.

Le pourquoi : ce sont des projets d'apprentissage. Le livrable compte, mais ce qui est évalué
le jour J, c'est la capacité à **justifier et interpréter** (« je peux justifier », « je peux
interpréter » reviennent dans toutes les fiches). L'IA peut produire le code ; elle ne doit
pas produire un candidat qui ne sait pas expliquer son dépôt.

## 2. Objectifs, non-objectifs, anti-objectifs

**Objectifs**
- Un déclencheur unique (« OC » / « openclassroom ») qui reprend le projet là où il en est,
  même dans une nouvelle session.
- Une traçabilité de bout en bout : indicateur de la fiche ↔ livrable ↔ user story ↔
  décision de spec ↔ question d'oral blanc.
- Une répartition explicite, par user story, de ce que William fait lui-même (👤) et de ce
  qui est délégué à l'IA (🤖).
- Un carnet de soutenance **local** (`.oc/carnet.md`, non publié), qui alimente la colonne « Notes » de la fiche et la
  préparation de la soutenance.
- La réutilisation des skills existants : `semver-repo-setup` pour le dépôt et le kanban,
  `semver-batch-workflow` pour les lots, PR et releases.

**Non-objectifs**
- Rédiger le support de présentation final (le skill fournit un plan et la répétition, pas
  les slides).
- Gérer le dépôt du zip sur la plateforme OC (on donne seulement la liste nommée des
  livrables).
- Remplacer le mentor.

**Anti-objectifs** (échec même si tout « marche »)
- Un projet livré que William ne sait pas défendre : chaque merge sans compréhension
  vérifiée est un échec du skill.
- Un oral blanc complaisant : des questions génériques, ou un « maîtrisé » accordé à une
  réponse floue.
- Du contenu OpenClassrooms ou des données personnelles publiés dans un dépôt public.
- Un skill qui redéfinit ce que font déjà `semver-*` (dérive et double maintenance).

## 3. Contraintes

- Format [Agent Skills](https://agentskills.io) (`SKILL.md` + frontmatter), en **français**,
  portable vers Claude Code, opencode et autres agents. Les hooks sont un bonus propre à
  Claude Code : sans eux, le skill doit fonctionner (déclenchement par la description, porte
  rappelée par les instructions).
- Vit dans le dépôt `WillIsback/agent-skills`, cloné en `/home/will/work/agent-skills`. Les
  skills sont installés par **liens symboliques** `~/.agents/skills/<nom>` →
  `~/work/agent-skills/skills/<nom>` (et `~/.claude/skills/<nom>` → `~/.agents/...`). Il est
  aussi publié dans la marketplace `.claude-plugin/marketplace.json`.
- Dépôts nommés `OC-{AIE|DIA}-P{n}-{Nom}`. Arborescence locale :
  `/home/will/formation_OC/{ai_engineer|dev_fullstack_ai}/P{n}_<titre>/`.
- **Seul l'humain décide de fusionner sur `main`.** L'agent peut lancer `gh pr merge` à sa
  demande, et seulement si la porte de l'oral blanc est validée.
- Les exports HTML des pages OC sont inutilisables (le contenu est rendu en JavaScript) et
  contiennent des données personnelles : **on ne les accepte pas**, seulement les PDF
  imprimés.

## 4. Entrées : le format commun d'un projet OC

Chaque projet OC fournit trois documents (en PDF, imprimés depuis la plateforme) :

| Document | Contenu exploité |
|---|---|
| **Page mission** | Scénario et personnage commanditaire, liste des livrables, étapes (description, prérequis, résultats attendus, recommandations, points de vigilance, outils, ressources), sources : docs, code, données, projets précédents. |
| **Page « Livrables et soutenance »** | Liste officielle des livrables et règle de nommage du zip ; déroulé de la soutenance (durées, présentation, **démos imposées**), **rôle joué par l'évaluateur**, **axes de discussion**. |
| **Fiche d'auto-évaluation** | La grille : compétence → livrable → indicateurs de réussite (cases), colonne « Notes ». |

S'y ajoute un **catalogue des parcours** (dans le skill, `references/catalogue-parcours.md`)
issu des fiches de début de formation : liste des projets de chaque parcours avec leurs
titres et dates prévues. Pour AIE : P3 → P15, avec charge en heures et dates de début et de
fin (P8 : 45 h, du 14/12/2026 au 11/01/2027). Pour DIA : P1 → P14 et leurs titres. Les titres
AIE encore inconnus sont marqués « à compléter » ; le skill les complète à partir de la page
mission lors du cadrage de chaque projet.

Les PDF sont rangés dans `.oc/sources/` (**ignoré par git**). Seul `docs/brief.md`, une
reformulation structurée et sans copie intégrale, est versionné.

## 5. Approches envisagées

| | Approche | Pour | Contre |
|---|---|---|---|
| **A ✅** | **Un skill `oc-project` à phases** : `SKILL.md` court qui aiguille selon un fichier d'état ; une référence par phase, chargée au besoin. L'oral blanc est sorti dans son propre skill `oc-oral-blanc`. | Un seul point d'entrée, cohérent, simple à installer ; l'oral blanc reste utilisable seul (réviser un ancien projet). | Un `SKILL.md` aiguilleur à bien écrire pour ne pas tout charger. |
| B | Une famille de skills enchaînés à la superpowers (`oc-cadrage` → `oc-specs` → `oc-lot` → `oc-oral-blanc` → `oc-repetition`). | Chaque étape se lance seule. | Cinq descriptions proches, donc des faux déclenchements ; règles communes dispersées ; plus de maintenance. |
| C | A ou B, plus une **porte CI** obligatoire sur `main` (`oc-gate` lit le carnet). | Règle visible et impossible à oublier. | Ne protège que de l'oubli (c'est l'agent qui écrit le carnet) ; check « oral blanc » exposé dans un dépôt public évalué. |

**Retenu : A** (choix de William). La porte est assurée par un **hook local** qui bloque
`gh pr merge` (voir §8.4), pas par la CI.

## 6. Arborescence livrée

```
skills/
  oc-project/
    SKILL.md                         # aiguilleur : lit .oc/state.md, charge la phase
    references/
      cadrage.md                     # partie 1, étapes 1 à 5
      specs.md                       # partie 1, étape 6 (session de specs, format ADR)
      livraison.md                   # partie 2 : boucle de lot et porte
      repetition.md                  # répétition générale finale
      catalogue-parcours.md          # parcours AIE et DIA : projets, titres, dates
      conventions.md                 # nommage, arborescence, .oc/, 👤/🤖, carnet
    assets/
      brief.md                       # modèle de docs/brief.md
      objectifs.md                   # modèle de la matrice de traçabilité
      spec.md                        # modèle de docs/spec.md (ADR)
      architecture.md                # modèle de docs/architecture.md (Mermaid)
      carnet.md                      # modèle de .oc/carnet.md
      state.md                       # modèle de .oc/state.md
    hooks/
      oc-trigger.sh                  # UserPromptSubmit : détecte OC/openclassroom
      oc-merge-gate.sh               # PreToolUse Bash : bloque gh pr merge sans porte validée
    scripts/
      install-hooks.sh               # enregistre les hooks dans ~/.claude/settings.json (idempotent)
  oc-oral-blanc/
    SKILL.md                         # protocole d'oral, d'évaluation et d'apprentissage
    references/
      grille.md                      # barème maîtrisé / partiel / à revoir, exemples
      exercices.md                   # types d'exercices pratiques par domaine
```

Plus : les deux skills rejoignent le plugin unique `willisback-skills` (`.claude-plugin/marketplace.json` et `plugin.json`, depuis #17), et une ligne par skill
dans le `README.md` du dépôt.

## 7. Partie 1 — du brief à la documentation technique

### 7.1 Aiguillage et état

`.oc/state.md` (ignoré par git) contient : parcours, n° de projet, nom du dépôt, phase
courante (`cadrage` | `specs` | `livraison` | `repetition` | `termine`), lot en cours, date
de soutenance visée, chemins des sources. Au déclenchement, `SKILL.md` :
- détecte le projet depuis le dossier courant (`formation_OC/<parcours>/P<n>_…`) ;
- sans `.oc/state.md`, démarre le cadrage ; sinon, annonce la phase en une ligne et la
  reprend.

**Mode reprise** : le cadrage vérifie d'abord ce qui existe déjà (sources, `docs/brief.md`,
dépôt GitHub, issues, un cadrage fait à la main et fourni en note de passation). Il
pré-remplit les étapes correspondantes, les présente pour validation au lieu de les refaire,
et n'exécute que ce qui manque. *[décision de l'agent]*

**Nom du dépôt** : `<Nom>` est le titre officiel du projet dans le parcours (celui du
catalogue et du dossier local), pas le titre de la mission. Exemple :
`OC-AIE-P8-Confirmez-vos-competences-en-MLOps-Partie-2`. C'est cohérent avec P5 et P6.
*[décision de l'agent]*

### 7.2 Cadrage (`references/cadrage.md`)

1. **Collecte des sources** : demander les 3 PDF s'ils ne sont pas fournis, les copier dans
   `.oc/sources/`, refuser les HTML (expliquer pourquoi).
2. **Brief** : produire `docs/brief.md` (scénario, commanditaire, livrables officiels, étapes
   résumées, démos imposées, axes de discussion, règle de nommage du zip, date de
   soutenance).
3. **Étude de l'existant** : identifier dans le catalogue et dans `formation_OC/` les projets
   dont celui-ci dépend (ex. P8 AIE reprend le modèle de P6 et les standards de P5) ; lire
   leurs README, docs et artefacts ; résumer ce qui est réutilisable, ce qui manque, et les
   **pièges qui changent le projet** (ex. contrat d'entrée de l'API, absence de cible dans
   les données de test). Présenter et faire corriger.
4. **Objectifs et répartition** : produire la matrice de traçabilité
   (`assets/objectifs.md` → section de `docs/brief.md`), indicateur de la fiche → livrable →
   user story(s), avec pour chaque user story la part 👤 (décider, interpréter, justifier,
   faire au moins une fois à la main) et la part 🤖 (code, boilerplate, scripts, premières
   versions de doc). Règle : tout indicateur formulé « je peux justifier / interpréter /
   j'ai défini » a une part 👤 non vide. Faire valider par William.
5. **Dépôt et kanban** : invoquer `semver-repo-setup` avec, comme brief : nom
   `OC-{AIE|DIA}-P{n}-{Nom}`, description, stack déduite de l'existant, date cible = date de
   soutenance. Chaque user story reprend dans ses critères d'acceptation les indicateurs de
   la fiche qu'elle couvre (« Fiche : … ») et une section `👤 Ta part` / `🤖 Délégué`. Les
   lots sont datés jusqu'à la date de soutenance. Ajouts propres à OC : `.oc/` et
   `exercices/` dans `.gitignore`, `.oc/carnet.md` initialisé.

Fin du cadrage : `state.md` → `specs`.

### 7.3 Session de specs (`references/specs.md`)

Session interactive, **une décision à la fois**, dans l'esprit de `superpowers:brainstorming`
mais orientée système. Pour chaque décision structurante (contrat d'API, stockage, outils,
déploiement, monitoring, optimisation…) :

- **Contexte** : ce que l'énoncé, l'existant et les contraintes imposent.
- **Options** (2 à 3) : description concrète, compromis.
- **Recommandation** de l'agent, avec sa raison.
- **Choix** de William.
- **Conséquences** : sur le code, les tests, le monitoring, la soutenance.
- **Indicateurs de la fiche concernés** et **question d'oral probable** (« Pourquoi X plutôt
  que Y ? »).

L'agent ne passe à la décision suivante qu'une fois la précédente tranchée. L'ordre suit les
dépendances (le contrat d'entrée avant la validation, le stockage avant l'analyse de drift).

**Livrables** (commités sur une branche `docs/<version>-specs` via une PR `docs:` du
workflow semver ; la porte d'oral blanc s'applique aussi à cette PR) :
- `docs/spec.md` : une ADR par décision (format ci-dessus), précédée d'une vue d'ensemble ;
- `docs/architecture.md` : schémas **Mermaid**, au minimum un diagramme de composants, un
  diagramme de séquence du flux principal et un diagramme de déploiement (CI/CD →
  environnement cible). Un diagramme de classes seulement si le code a un modèle de domaine.

Les décisions de spec peuvent modifier le backlog (user stories ajoutées, scindées,
re-datées) : l'agent met à jour les issues et le dit.

Fin de la partie 1 : William approuve `spec.md` et `architecture.md` ; `state.md` →
`livraison`.

## 8. Partie 2 — livraison lot par lot

### 8.1 Boucle de lot (`references/livraison.md`)

Pour chaque lot, dans l'ordre du board, en suivant `semver-batch-workflow` (branche de lot,
sous-branches par user story, PR unique vers `main`) :

1. Annoncer le lot : user stories, indicateurs de la fiche visés, parts 👤.
2. **Parts 🤖** : l'agent code, teste, documente, sous-branche par sous-branche.
3. **Parts 👤** : l'agent **ne les fait pas**. Il prépare le terrain, explique, guide, relit.
   Exemples : choisir les cas de test critiques, fixer un seuil d'alerte de drift, lancer
   `docker build` à la main, interpréter un rapport.
4. PR du lot vers `main`, CI au vert, William relit le diff.
5. **Oral blanc** (`oc-oral-blanc`) sur la PR.
6. Porte validée → William fusionne (ou demande à l'agent de le faire) → release
   automatique → carnet et `state.md` mis à jour.

### 8.2 Skill `oc-oral-blanc`

Utilisable seul (« fais-moi un oral blanc sur P6 ») ou appelé par `oc-project`.

**Utilisé seul sur un ancien projet** (sans `.oc/`) : amorçage minimal. L'agent demande les
PDF (au minimum la fiche et la page soutenance) et les range dans `.oc/sources/`. Il en tire
le rôle, les indicateurs et les axes. Faute de PDF, il travaille en mode dégradé à partir du
README, du code et des docs, et le dit. Le périmètre des questions est alors le projet
entier, ou la partie que William désigne, au lieu du diff d'une PR. Le résultat va dans le
carnet du projet ; il n'y a pas de porte de merge dans ce mode. *[décision de l'agent]*

- **Rôle** : celui de l'évaluateur décrit dans la page soutenance (P8 : Chloé, Lead Data
  Scientist). Le rôle est tenu tant qu'on est en mode oral.
- **Questions** : 3 à 6 par lot, tirées de trois sources et **ancrées dans le concret** :
  les indicateurs de la fiche couverts par le lot, les axes de discussion de la page
  soutenance, le diff réel de la PR et les ADR concernées. Chaque question cite un fichier,
  une décision ou un résultat précis. Les questions génériques sont interdites.
- **Une question à la fois.** Évaluation franche après chaque réponse : **maîtrisé**,
  **partiel** ou **à revoir**, en citant ce qui manque. Barème dans `references/grille.md` :
  « maîtrisé » exige le *quoi*, le *pourquoi* et au moins une *conséquence* ou une
  *alternative*.
- **Mode apprentissage** dès que la réponse est « partiel » ou « à revoir » : on sort du rôle
  et on échange (explication, questions socratiques, lecture du code ensemble). Si utile, un
  **exercice pratique** court (`references/exercices.md`) : casser un test et expliquer
  l'échec, écrire une règle de validation, interpréter un graphique de drift, profiler une
  fonction… Les exercices vivent dans `exercices/` (ignoré par git). Puis la question est
  **reposée sous un autre angle**.
- **Sortie** : la porte est validée seulement quand toutes les questions sont « maîtrisé ».
  L'agent écrit alors l'entrée du lot dans le carnet avec la ligne de validation (§8.3).

### 8.3 Carnet de soutenance (`.oc/carnet.md`, local, non versionné)

Choix de William : le carnet reste **local**. Il n'est pas exposé dans le dépôt public que
l'évaluateur parcourt, et la colonne « Notes » de la fiche suffit à montrer la préparation.
Sa sauvegarde relève de celle du home-server (hors périmètre du skill).

Par lot : version, PR, date ; questions posées ; niveau final ; points travaillés en mode
apprentissage (sans recopier les réponses, juste le sujet et ce qui a débloqué) ; notes pour
la colonne « Notes » de la fiche, par indicateur. Ligne de validation lisible par machine :

```
<!-- oc-gate: v0.3.0 validé 2026-12-18 sha:3f2a9c1 -->
```

Il sert aussi de base au plan de soutenance.

### 8.4 Hooks (Claude Code)

- **`oc-trigger.sh`** (UserPromptSubmit) : si le prompt contient `OC` en majuscules et
  isolé (regex `(^|[^[:alnum:]_])OC([^[:alnum:]_]|$)`, sensible à la casse) ou
  `openclassroom` / `openclassrooms` (insensible à la casse), il renvoie un
  `additionalContext` : « Projet OpenClassrooms détecté : invoque le skill oc-project. » Sinon
  il ne renvoie rien. Il ne bloque jamais.
- **`oc-merge-gate.sh`** (PreToolUse, outil Bash) : si la commande contient `gh pr merge` et
  que le dossier courant est un projet OC (présence de `.oc/state.md`), il identifie la PR
  (numéro dans la commande, sinon la PR de la branche courante) et lit sa branche de tête et
  son SHA (`gh pr view --json headRefName,headRefOid`).
  - *Révisé après la revue finale* : tout lot `<type>/<X.Y.Z>` vers `main` est soumis à la
    porte (un lot `docs:` ou `refactor:` porte aussi du travail à défendre) ; le hook
    remonte jusqu'à la racine du projet (sous-dossier, worktree), identifie la PR même
    après des options, par URL ou par branche, et refuse `gh api` (fusion), `--auto` et
    plusieurs fusions par commande. *[décision de l'agent]*
  - **PR soumises à la porte** (version initiale) : branches de lot `feat|fix|perf|major/<X.Y.Z>` (identifiant
    de porte = `v<X.Y.Z>`) et branche de specs `docs/<X.Y.Z>-specs` (identifiant =
    `specs`). *[décision de l'agent]*
  - **PR exemptées** : `chore/outillage` (fusionnée par `semver-repo-setup` pendant le
    cadrage), Dependabot, et toute autre branche. Elles ne contiennent pas de travail à
    défendre. *[décision de l'agent]*
  - La porte cherche, dans `.oc/carnet.md` (local), la ligne
    `oc-gate: <id> validé <date> sha:<7 premiers caractères>`, dont le SHA doit être
    **égal au SHA de tête actuel de la PR**. Un commit poussé après l'oral invalide donc la
    porte : il faut un oral court sur ce delta. *[décision de l'agent]*
  - Si la ligne manque ou est périmée, refus avec le message « Porte d'oral blanc non validée
    pour <id> : lancer oc-oral-blanc. » Hors projet OC, laisser passer.
- **Installation** : uniquement `scripts/install-hooks.sh`, qui ajoute les deux hooks dans
  `~/.claude/settings.json` de façon idempotente, sans toucher aux hooks existants (il en
  existe déjà un : `codegraph prompt-hook`). William installe ses skills par liens
  symboliques, pas par la marketplace. De plus, avec `"source": "./"`, un `hooks.json` de
  plugin s'appliquerait à tous les plugins du dépôt, et les deux voies cumulées doubleraient
  les hooks. On ne livre donc pas de `hooks.json` ; le README du dépôt indique de lancer le
  script après installation. *[décision de l'agent]*

### 8.5 Répétition générale (`references/repetition.md`)

Après le dernier lot : simulation complète au format de la page soutenance (P8 : 15 min de
présentation, 10 min de discussion, 5 min de débrief), chronométrée. Avant : une checklist
des démos imposées et de la fiche entièrement cochée, notes comprises. Pendant : l'agent
interrompt comme l'évaluateur. Après : un plan de présentation proposé à partir du carnet,
les points faibles restants, et la liste nommée des livrables pour le zip
(`Nom_Prenom_n°_livrable_mmaaaa`). `state.md` → `termine`.

## 9. Pilote

Le premier usage réel est **P8 AIE** (« Déployez et monitorez votre modèle de scoring »,
dépôt à créer `OC-AIE-P8-Confirmez-vos-competences-en-MLOps-Partie-2`, soutenance visée au
11/01/2027). Son cadrage a été fait à la main dans la conversation d'origine. Le skill le
reprend en **mode reprise** (§7.1) à partir d'une note de passation
(`.oc/handoff-cadrage.md`), rédigée depuis cette conversation lors de la mise en œuvre :
existant P5/P6, objectifs, répartition 👤/🤖, pièges identifiés. Points déjà
établis : réutiliser les standards de P5 sur la base de P6 ; décision ouverte sur le contrat
d'entrée de l'API (option recommandée : les 122 features validées par Pydantic, bornes issues
de `preprocessing_bundle.joblib`, plus une route de démo par `SK_ID_CURR`), à trancher en
session de specs.

## 10. Laissé au builder

- La formulation exacte des `SKILL.md` (descriptions de déclenchement comprises), dans le
  style des skills existants du dépôt.
- La structure détaillée des modèles dans `assets/`.
- L'implémentation des hooks (bash + `jq`), et leurs tests sur quelques prompts et commandes
  représentatifs (faux positifs « OCR », « doc », « Oc » ; vrais positifs « OC P8 », « projet
  OpenClassrooms »).
- La description du plugin unique `willisback-skills` (les skills y sont embarqués via `skills/`).
- Le contenu de `catalogue-parcours.md` à partir des données du §4 ; titres AIE manquants
  marqués « à compléter ».
