---
name: oc-project
description: Orchestration d'un projet OpenClassrooms de William (WillIsback), parcours AI Engineer (AIE) ou Développeur IA (DIA) — cadrage à partir des PDF du projet (mission, livrables et soutenance, fiche d'auto-évaluation), dépôt et kanban, session de specs avec ADR et schémas Mermaid, livraison lot par lot avec oral blanc obligatoire avant chaque fusion, répétition générale de la soutenance. À utiliser dès qu'il est question d'un projet « OC » ou « OpenClassrooms », d'un dossier de formation_OC/, ou pour reprendre un projet OC en cours.
---

# Projet OpenClassrooms

Un projet OC se valide par une soutenance où l'évaluateur, dans un rôle du scénario,
juge les livrables avec la fiche d'auto-évaluation. Ce skill amène William jusqu'à ce
jour-là avec un dépôt propre **et** la capacité de défendre chaque ligne commitée.
L'IA produit le code ; William décide, interprète et justifie.

## 1. Situer le projet

1. Déduire parcours et numéro du dossier courant :
   `formation_OC/ai_engineer/P<n>_…` → AIE, `formation_OC/dev_fullstack_ai/P<n>_…` → DIA.
   Sinon, demander.
2. Lire `.oc/state.md` (format : `assets/state.md`).
   - Absent et dossier vide → phase `cadrage`.
   - Absent mais artefacts présents (sources, `docs/brief.md`, dépôt GitHub, note
     `.oc/handoff-cadrage.md`) → phase `cadrage` en **mode reprise** (voir
     `references/cadrage.md`).
   - Présent → reprendre la phase indiquée.
3. Annoncer en une ligne : projet, phase, prochaine action.

## 2. Phases

| Phase | Référence à charger | Sortie |
|---|---|---|
| `cadrage` | `references/cadrage.md` | brief, matrice d'objectifs, dépôt + kanban |
| `specs` | `references/specs.md` | `docs/spec.md` (ADR), `docs/architecture.md` (Mermaid) |
| `livraison` | `references/livraison.md` | un lot par PR, chacun validé par oral blanc |
| `repetition` | `references/repetition.md` | soutenance simulée, liste des livrables du zip |
| `termine` | — | rien à faire ; proposer un oral blanc de révision |

Ne charger que la référence de la phase en cours. Conventions communes (nommage,
`.oc/`, 👤/🤖, ligne de porte) : `references/conventions.md`. Projets et dates des deux
parcours : `references/catalogue-parcours.md`.

## 3. Règles transverses

- Tout en **français**. Une question à la fois ; une recommandation plutôt qu'un menu.
- **👤 n'est jamais fait à la place de William** : l'agent prépare, explique, guide,
  relit. 🤖 est fait par l'agent.
- **Jamais de `gh pr merge` sur une PR de lot ou de specs sans ligne `oc-gate` valide
  pour le SHA de tête** dans `.oc/carnet.md` (skill `oc-oral-blanc`). Le hook
  `oc-merge-gate.sh` l'impose sous Claude Code ; sans hook, la règle vaut quand même.
  La fusion se fait seulement à la demande de William.
- Mettre à jour `.oc/state.md` (phase, lot, journal) à chaque transition.
- Ne jamais versionner `.oc/` ni `exercices/`, ni publier le contenu des PDF OC.

## 4. Skills délégués

- `semver-repo-setup` : création du dépôt, outillage CI/CD, board et backlog (fin du
  cadrage).
- `semver-batch-workflow` : lots, branches, PR, releases (livraison).
- `oc-oral-blanc` : oral blanc et porte de compréhension (fin de chaque lot et des specs).
