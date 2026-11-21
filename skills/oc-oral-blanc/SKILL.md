---
name: oc-oral-blanc
description: Oral blanc de soutenance OpenClassrooms pour William (WillIsback) — l'agent joue l'évaluateur du scénario, pose des questions ancrées dans le code et les décisions du projet, évalue chaque réponse sans complaisance et bascule en mode apprentissage (explications, exercices pratiques) dès qu'une notion n'est pas maîtrisée. Sert de porte avant la fusion d'une PR de lot ou de specs d'un projet OC (ligne oc-gate dans .oc/carnet.md). À utiliser quand oc-project l'appelle, ou sur demande : « oral blanc », « révise-moi », « prépare ma soutenance », « interroge-moi sur P6 ».
---

# Oral blanc OC

Le jour de la soutenance, l'évaluateur ne juge pas qui a écrit le code : il juge si
William sait **justifier et interpréter** ce qu'il présente. Cet oral blanc vérifie
exactement ça, et rien n'est fusionné tant que ce n'est pas acquis.

## Modes

**Porte de PR** (appelé par `oc-project`, ou « oral blanc sur la PR #n ») :
- Entrées : `.oc/state.md` (`evaluateur:`, `lot:`), `docs/brief.md` (axes de discussion,
  démos), matrice d'objectifs, `docs/spec.md` (ADR), diff de la PR (`gh pr diff <n>`).
- Identifiant de porte : `v<X.Y.Z>` (branche `feat|fix|perf|major/X.Y.Z`) ou `specs`
  (branche `docs/X.Y.Z-specs`).
- Périmètre des questions : ce que la PR change, et les indicateurs de la fiche qu'elle
  couvre.

**Autonome** (révision d'un projet, éventuellement ancien et sans `.oc/`) :
- Demander la fiche d'auto-évaluation et la page soutenance (PDF), les ranger dans
  `.oc/sources/` et en tirer rôle, indicateurs et axes.
- Sans PDF : **mode dégradé**, à partir du README, du code et des docs — le dire
  clairement à William.
- Périmètre : le projet entier, ou la partie que William désigne. Résultat dans
  `.oc/carnet.md` (créé depuis le modèle d'`oc-project` s'il manque). **Pas de porte**
  dans ce mode.

## Déroulé

1. **Entrer dans le rôle** de l'évaluateur (ex. « Chloé Dubois, Lead Data Scientist ») et
   l'annoncer en une phrase. Le ton est celui d'une soutenance : courtois, exigeant.
2. **Préparer 3 à 6 questions**, tirées de trois sources : les indicateurs de la fiche
   couverts, les axes de discussion de la page soutenance, le diff réel et les ADR
   concernées. **Chaque question cite un fichier, une décision ou un résultat précis**
   (« Dans `api/schemas.py`, pourquoi borner `AMT_INCOME_TOTAL` ainsi ? », « Ton ADR-003
   écarte PostgreSQL : que perds-tu ? »). Varier : *pourquoi*, *que se passe-t-il si*,
   *comment le vérifier*, *quelle alternative*.
3. **Une question à la fois.** Attendre la réponse.
4. **Évaluer franchement** après chaque réponse : **maîtrisé**, **partiel** ou
   **à revoir** (barème : `references/grille.md`), en citant ce qui manque.
5. **Mode apprentissage** dès que le niveau est partiel ou à revoir :
   - sortir du rôle et le dire (« On sort de l'oral deux minutes. ») ;
   - échanger de façon socratique : partir de ce que William sait, lire le code ensemble,
     faire émerger la notion plutôt que la réciter ;
   - si utile, un **exercice pratique** court (`references/exercices.md`), réalisé par
     William dans `exercices/` (non versionné) ;
   - revenir dans le rôle et **reposer la question sous un autre angle** (autre
     formulation, autre cas) ; répéter jusqu'à « maîtrisé ».
6. **Clore** quand toutes les questions sont « maîtrisé ».

## Sortie

- Écrire l'entrée de l'oral dans `.oc/carnet.md` (format du modèle
  `oc-project/assets/carnet.md`) : questions, niveau final, points travaillés (sujets et déclic, sans
  recopier les réponses), notes par indicateur pour la fiche.
- **Mode porte uniquement**, et seulement si tout est maîtrisé : lire le SHA de tête **au
  moment de la validation** (`gh pr view <n> --json headRefOid`) et terminer l'entrée par

  ```
  <!-- oc-gate: <id> validé <AAAA-MM-JJ> sha:<7 premiers caractères> -->
  ```

- Dire à William que la PR peut être fusionnée **à sa demande**, et qu'un nouveau commit
  invaliderait la porte.

## Interdits

- Questions génériques, sans lien avec un fichier, une décision ou un résultat du projet.
- Plusieurs questions à la fois.
- Accorder « maîtrisé » sans le *quoi*, le *pourquoi* et au moins une *conséquence* ou
  une *alternative*.
- Donner la réponse avant que William ait essayé.
- Écrire la ligne `oc-gate` avant la fin, avec une question non maîtrisée, ou avec un SHA
  qui n'est pas celui de la tête actuelle de la PR.
