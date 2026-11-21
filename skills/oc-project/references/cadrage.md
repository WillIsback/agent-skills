# Phase 1 — Cadrage

But : comprendre le projet, ce qui existe déjà et ce que l'évaluateur notera, puis créer
un dépôt dont chaque user story est reliée à la fiche d'auto-évaluation, avec la part de
William (👤) et la part déléguée (🤖).

Présenter le résultat de chaque étape à William et le faire corriger avant de passer à la
suivante. Une question à la fois.

## 0. Mode reprise (toujours en premier)

Inventorier ce qui existe déjà :

- `.oc/sources/` (PDF), `.oc/handoff-cadrage.md` (cadrage fait hors du skill) ;
- `docs/brief.md`, matrice d'objectifs ;
- dépôt GitHub `OC-{AIE|DIA}-P{n}-…` (`gh repo view`), Project, issues, milestones.

Pour chaque étape ci-dessous déjà couverte : la **pré-remplir** depuis ces artefacts, la
présenter pour validation au lieu de la refaire, et n'exécuter que ce qui manque. Créer
`.oc/state.md` (modèle `assets/state.md`) dès le début, avec `phase: cadrage`.

## 1. Sources

- Demander les trois PDF s'ils manquent : **page mission**, **page « Livrables et
  soutenance »**, **fiche d'auto-évaluation** (imprimés en PDF depuis la plateforme).
- Les copier dans `.oc/sources/` sous les noms `mission.pdf`, `livrables-soutenance.pdf`,
  `fiche-auto-evaluation.pdf`.
- **Refuser les exports HTML** et dire pourquoi : le contenu y est rendu en JavaScript
  (fichier vide de texte utile) et ils contiennent des données personnelles.
- Lire les PDF (outil de lecture de PDF, sinon `pdftotext -layout`).

## 2. Brief

Produire `docs/brief.md` depuis `assets/brief.md` : scénario, livrables officiels, étapes,
soutenance (date visée tirée de `catalogue-parcours.md`, rôle de l'évaluateur, déroulé,
**démos imposées**, **axes de discussion**), nommage du zip. Reformuler, ne pas recopier.

Renseigner dans `.oc/state.md` : `parcours`, `projet`, `soutenance`, et `evaluateur`
(rôle joué par l'évaluateur d'après la page soutenance, ex. « Chloé Dubois, Lead Data
Scientist »).

## 3. Étude de l'existant

- Repérer dans `catalogue-parcours.md` et dans `formation_OC/` les projets dont celui-ci
  dépend (énoncé : « reprenez le modèle du projet … ») et ceux dont les standards sont
  réutilisables.
- Lire leurs README, `docs/`, artefacts (modèles, bases, workflows CI).
- Restituer : ce qui est réutilisable, ce qui manque, et surtout les **pièges qui changent
  le projet** — une contrainte, une incohérence ou un raccourci que William n'a peut-être
  pas vu (ex. un modèle qui attend des features calculées alors que l'énoncé parle de
  données client brutes ; un jeu de test sans cible, qui empêche de suivre la performance
  réelle). Compléter la section « Existant réutilisé » du brief.

## 4. Objectifs et répartition

- Remplir la matrice `assets/objectifs.md` : une ligne par indicateur de la fiche,
  reliée à un livrable et à une user story à créer.
- Pour chaque user story : `👤 Ta part` et `🤖 Délégué` selon
  `conventions.md` (tout indicateur « justifier / interpréter / défini » ⇒ 👤 non vide).
- Faire **valider la matrice par William avant de créer le dépôt** ; l'insérer dans le
  brief.

## 5. Dépôt et kanban

**Avant tout `git init` ou commit**, écrire dans le `.gitignore` du dossier les lignes
`.oc/` et `exercices/`, puis vérifier avec `git check-ignore .oc/x exercices/x` une fois le
dépôt initialisé : le dossier contient déjà les PDF OC et la note de passation, et le
commit d'amorçage de `semver-repo-setup` ne doit jamais les embarquer. Préciser à
`semver-repo-setup` que ce `.gitignore` existe et doit être conservé.

Invoquer le skill `semver-repo-setup` en lui donnant ce brief :

- nom `OC-{AIE|DIA}-P{n}-{Nom}` (`conventions.md`), public, description en une phrase ;
- stack déduite de l'existant (profil et option `--docker` si un service est livré) ;
- date cible = date de soutenance, pour dater les lots ;
- backlog : epics par domaine, une user story par livrable vérifiable ; dans chaque user
  story, une section **`Fiche :`** listant les indicateurs couverts (repris dans les
  critères d'acceptation) et une section **`👤 Ta part` / `🤖 Délégué`**.

Ajouts propres à OC, dans la branche d'outillage :

- vérifier que `.oc/` et `exercices/` sont toujours dans le `.gitignore` final (le profil de
  stack peut l'avoir réécrit) ;
- initialiser `.oc/carnet.md` depuis `assets/carnet.md` (local, non versionné).

## Fin de phase

Récapituler (URL du dépôt et du board, lots datés, pièges retenus), ajouter une ligne au
journal de `.oc/state.md` et passer `phase: specs`. Enchaîner sur `references/specs.md`.
