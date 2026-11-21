# Phase 4 — Répétition générale

But : une soutenance simulée dans les conditions réelles, puis tout ce qu'il faut pour
déposer les livrables.

## 1. Checklist préalable

- Chaque **démo imposée** du brief fonctionne de bout en bout, lancée par William
  (ex. requête à l'API déployée ; commit qui déclenche tests, build et déploiement).
- La **fiche d'auto-évaluation** est entièrement cochée, colonne « Notes » remplie à
  partir du carnet.
- README et docs à jour ; dépôt public ; aucune donnée sensible commitée.

Ce qui manque est corrigé avant la simulation (via un lot `fix` si du code change).

## 2. Simulation

Au format de la page soutenance (`docs/brief.md`), par exemple 15 min de présentation,
10 min de discussion, 5 min de débrief.

- L'agent tient le **rôle de l'évaluateur** (`evaluateur:` de `.oc/state.md`) du début à
  la fin de la présentation et de la discussion.
- Il annonce les **repères de temps** (« 5 minutes », « 10 minutes », « il reste
  2 minutes ») et signale un dépassement : hors de 10 à 20 minutes, une présentation peut
  être refusée.
- Pendant la discussion, il **interrompt et challenge** sur les axes de la page
  soutenance, en s'appuyant sur les ADR et les points faibles du carnet.
- Pas d'aide pendant la simulation ; le mode apprentissage attend le débrief.

## 3. Débrief

- Sortie du rôle : points forts, points faibles, questions mal défendues.
- Les points faibles passent en mode apprentissage (skill `oc-oral-blanc`, mode
  autonome) avant la vraie soutenance.
- Proposer un **plan de présentation** tiré du carnet et des ADR (contexte, résultats,
  démos, choix techniques, limites), sans rédiger les slides.

## 4. Livrables du zip

Lister les livrables officiels du brief avec leur nom final
(`Nom_Prenom_<n°>_<livrable>_<mmaaaa>`, voir `conventions.md`) et le fichier ou lien qui
correspond à chacun dans le dépôt.

## Fin

`phase: termine`, ligne de journal. Le skill propose ensuite seulement des oraux blancs
de révision.
