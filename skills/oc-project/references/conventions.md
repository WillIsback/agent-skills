# Conventions des projets OC

## Nommage et arborescence

- Dépôt GitHub : `OC-{AIE|DIA}-P{n}-{Nom}`, propriétaire `WillIsback`, public.
  `{Nom}` = titre officiel du projet dans le parcours (`catalogue-parcours.md`), mots
  séparés par des tirets, sans accents ni ponctuation. Exemple :
  `OC-AIE-P8-Confirmez-vos-competences-en-MLOps-Partie-2`.
  Projet en plusieurs dépôts : suffixe (`-Livrable`, `-Backend`, `-Phase1`, `-Training`).
- Dossier local : `/home/will/formation_OC/ai_engineer/P{n}_<titre>/` (AIE) ou
  `/home/will/formation_OC/dev_fullstack_ai/P{n}_<titre>/` (DIA).

## Dossiers propres à OC (jamais versionnés)

À ajouter au `.gitignore` du projet :

```
.oc/
exercices/
```

| Chemin | Contenu |
|---|---|
| `.oc/sources/` | PDF fournis par OC : `mission.pdf`, `livrables-soutenance.pdf`, `fiche-auto-evaluation.pdf` |
| `.oc/state.md` | état du projet (modèle `assets/state.md`) |
| `.oc/carnet.md` | carnet de soutenance (modèle `assets/carnet.md`) |
| `.oc/handoff-cadrage.md` | note de passation d'un cadrage fait hors du skill (facultatif) |
| `exercices/` | brouillons d'exercices du mode apprentissage |

**PDF uniquement.** Les exports HTML des pages OC sont des coquilles vides (contenu rendu
en JavaScript) et contiennent des données personnelles (e-mail, téléphone) : les refuser
en expliquant pourquoi. Le contenu OC n'est jamais recopié tel quel dans le dépôt :
`docs/brief.md` en est une reformulation.

## Répartition 👤 / 🤖

- **👤 Ta part** : ce que William fait lui-même — décider, interpréter, justifier, et faire
  au moins une fois à la main (lancer un `docker build`, choisir des cas de test, fixer un
  seuil, lire un rapport).
- **🤖 Délégué** : ce que l'agent produit — code, boilerplate, scripts, configuration,
  premières versions de doc.
- Règle : tout indicateur de la fiche formulé « je peux justifier », « je peux
  interpréter », « j'ai défini » ou « j'ai documenté la stratégie » a une part 👤 non vide.

## Ligne de porte

Écrite par `oc-oral-blanc` dans `.oc/carnet.md`, lue par le hook `oc-merge-gate.sh` :

```
<!-- oc-gate: <id> validé <AAAA-MM-JJ> sha:<7 premiers caractères du SHA de tête> -->
```

`<id>` = `v<X.Y.Z>` pour une PR de lot (`feat|fix|perf|major/X.Y.Z` vers `main`), `specs`
pour la PR de specs (`docs/X.Y.Z-specs`). La dernière ligne d'un `<id>` fait foi ; un
commit poussé après la validation l'invalide.

## Qualité et sécurité

Pas de SonarCloud : l'analyse statique et la sécurité passent par Aikido et CodeQL, déjà
fournis par `semver-repo-setup`.

## Livrables du zip

Nommage OC : dossier `Titre_du_projet_nom_prenom`, fichiers
`Nom_Prenom_<n°>_<nom_du_livrable>_<mmaaaa>` (mmaaaa = mois et année de **démarrage** du
projet). Exemple : `Derue_William_1_historique_122026`.
