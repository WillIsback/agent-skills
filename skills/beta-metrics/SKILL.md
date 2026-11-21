---
name: beta-metrics
description: Méthode de William (WillIsback) pour cadrer une bêta de test centrée sur la promesse de valeur d'un produit — reformuler la promesse en une phrase falsifiable, séparer ce qui est déjà éprouvé de ce qui n'a jamais été vérifié, trouver LA métrique (un comportement observable, mesuré avant l'intervention, rapporté à un volume) en écartant les fausses métriques, définir la mesure avant/après avec groupe de comparaison au même seuil, l'export anonyme sans aucun contenu (vie privée par conception, test de garde), la page de transparence pour décideur et testeur, et l'engagement à publier un résultat décevant. À utiliser pour définir les objectifs et la méthode d'une bêta qui doit prouver (ou non) la promesse d'un produit, pas seulement montrer qu'on l'utilise. Se combine avec semver-batch-workflow (livrer les lots) et agent-team (exécution répartie).
---

# Bêta centrée sur la promesse de valeur

Méthode de William Derue (GitHub : WillIsback) pour cadrer une **bêta de test** : non pas
« des gens essaient le produit », mais « la bêta vérifie si la promesse de valeur est tenue ».
Indépendante de l'outil et du domaine. Référence d'implémentation complète : la bêta de
**Grammaria** (`src/analysis/progression/`, `scripts/beta/agreger.ts`,
`docs/.../decouvrir/beta.mdx`) ; les exemples ci-dessous y renvoient.

La bêta produit des **livrables** (voir la fin) ; pour les livrer par lots, s'appuyer sur
`semver-batch-workflow`, et sur `agent-team` si l'exécution est répartie sur plusieurs sessions.

## 1. Clarifier la promesse

Une bêta sert à vérifier une promesse, pas à collecter de l'usage. D'abord l'énoncer
proprement :

- **Reformuler la promesse de valeur en une seule phrase falsifiable** — une phrase qu'une
  mesure pourrait démentir. « Le produit aide » n'est pas falsifiable ; « une faute signalée
  revient moins souvent ensuite » l'est.
- **Séparer noir sur blanc deux choses** : ce qui est **déjà éprouvé** par l'usage (le produit
  rend un service qui marche, l'auteur ou des utilisateurs s'en servent au quotidien) et ce qui
  n'a **jamais été vérifié** (la promesse propre du produit, celle qui le distingue). La bêta ne
  porte **que** sur la partie non prouvée.
- **Ne jamais confondre « les gens l'utilisent » et « la promesse est tenue ».** L'usage prouve
  l'usage. Un produit peut être utilisé tous les jours sans que sa promesse de valeur soit
  vérifiée une seule fois.

Exemple (Grammaria, `docs/.../decouvrir/beta.mdx`, tableau « En bref ») : la correction rapide
par un modèle de langage est **éprouvée par l'usage** ; l'effet des astuces (« une faute
signalée revient moins souvent ») est **jamais vérifié** — c'est le seul objet de la bêta.

## 2. Trouver LA métrique (le cœur)

Pas une liste toute faite : une **procédure de découverte**. Pour la promesse falsifiée du §1,
se poser dans l'ordre :

1. **Quel comportement observable change si la promesse est tenue ?** On cherche un comportement,
   pas une opinion ni un ressenti. (Grammaria : la faute signalée revient-elle moins souvent ?)
2. **Se mesure-t-il avant l'intervention du produit, sur ce que l'utilisateur produit vraiment ?**
   La mesure doit porter sur la matière brute de l'utilisateur, **pas sur le résultat déjà
   corrigé** par le produit. Sinon on mesure le produit, pas l'utilisateur. (Grammaria : on compte
   les fautes dans le texte **écrit** par l'utilisateur, pas dans le texte corrigé renvoyé.)
3. **Peut-on le rapporter à un volume et le lire par unité suivie et dans le temps ?** Un nombre
   brut ne se compare pas. Le ramener à un dénominateur stable (**par 1 000 unités** : mots,
   lignes, sessions…), et le lire **par unité suivie** (ici : par règle de grammaire) et **par
   période** (semaine). (Grammaria : taux de fautes pour 1 000 mots, par règle, avant / depuis.)

### Fausses métriques à écarter (et pourquoi)

| Fausse métrique | Pourquoi elle trompe |
|---|---|
| Score composite choisi par l'équipe | Sa formule se discute ; on peut toujours la régler pour qu'elle « monte ». Il mesure le choix de l'équipe, pas la valeur. |
| Badges, nombre d'usages, temps passé | Prouvent **l'usage**, pas la valeur. Un produit addictif ou simplement ouvert souvent les fait grimper sans rien tenir. |
| Baisse brute d'un indicateur sélectionné à son pic | **Retour à la moyenne** : ce qu'on choisit parce que c'est haut redescend tout seul. La baisse n'est pas due à l'intervention. |

**Indicateurs d'appui : un ou deux, pas plus.** Juste de quoi lire la métrique principale (ex.
le volume suivi, le taux de bonnes réponses à un exercice). Au-delà, on dilue le signal et on se
donne le choix de l'indicateur qui arrange — ce qui est exactement la première fausse métrique.

## 3. Méthode de mesure

- **Avant / après par unité suivie**, autour de la **première intervention** du produit sur
  cette unité (le pivot). « Avant » : le comportement jusqu'au pivot ; « depuis » : après. On
  mesure chaque unité contre elle-même. (Grammaria, `src/analysis/progression/mesure.ts` : pivot
  = date de la première astuce sur la règle.)
- **Groupe de comparaison au même seuil.** Pour neutraliser le retour à la moyenne (§2), prendre
  des unités **non traitées** et les choisir **au même seuil de déclenchement** que les unités
  traitées — le même « pic » qui aurait déclenché l'intervention, mais sans intervention. Si le
  groupe traité baisse plus que le groupe de comparaison, la baisse ne s'explique pas seulement
  par le retour à la moyenne. **Expliquer le choix du groupe**, et pourquoi il est comparable.
  (Grammaria : les fautes hors cycle servent de comparaison, déclenchées au même critère de
  signalement — même nombre de fautes dans la même fenêtre — que les règles suivies ; voir le
  commentaire en tête de `mesure.ts`, qui détaille pourquoi certaines unités sont exclues du
  groupe pour ne pas le choisir sur son résultat.)
- **Volume minimal avant d'afficher un chiffre.** Fixer un seuil de volume (mots, occurrences)
  en dessous duquel on **ne montre pas** de taux : trois occurrences ne font pas une tendance.
- **Limites dites sans détour**, à l'écran et dans l'export : ce n'est **pas une preuve** ; **peu
  de participants** ; **volontaires et pas de tirage au sort** (biais de sélection) ; et **ce que
  la mesure ne capte pas** (ce qui se passe hors du produit, les textes non soumis, etc.).

## 4. Données : vie privée par conception

La confiance de la bêta tient à ce qu'elle **ne collecte rien de sensible**. Règles :

- **Le produit ne stocke aucun contenu de l'utilisateur** — seulement des **identifiants**
  (de règle, de catégorie, de forme contrôlée) et des **compteurs**. Jamais une phrase, un mot,
  une correction. (Grammaria : la base n'a pas de colonne de texte ; `MIGRATION_SANS_TEXTE` dans
  `journal.driver.ts`.)
- **Un test de garde échoue si du contenu est réintroduit.** La règle « aucun contenu » est
  tenue par un test automatique, pas par la discipline. (Grammaria,
  `tests/unit/progression.export.test.ts` : « ni libellé, ni date, ni texte » — l'export ne doit
  contenir que des chaînes de forme contrôlée.)
- **Export anonyme déclenché par l'utilisateur** : des **nombres** et des **identifiants de forme
  contrôlée** ; un **temps relatif** (semaines écoulées depuis le début, **sans date ni fuseau**) ;
  un **participant aléatoire** pseudonyme, **effaçable** (aucune dérivation d'une donnée réelle) ;
  la **version** du produit. Le fichier est **montré en entier avant d'être enregistré**, et
  **rien n'est envoyé** par le produit : l'utilisateur transmet lui-même, ou non. (Grammaria,
  `src/analysis/progression/export.ts` : format `grammaria-beta`, participant = 128 bits
  aléatoires, temps en semaines relatives, formes validées par expressions régulières fermées.)
- **Validation stricte des deux côtés.** Le même validateur sert à l'écriture (on vérifie ce
  qu'on exporte) et à la collecte. Tout champ inconnu, type inattendu, chaîne hors forme, nombre
  démesuré est refusé, et **le message d'erreur ne cite jamais le contenu refusé**.
- **Outil de collecte / agrégation** qui **refuse strictement tout fichier hors format sans
  l'afficher** (en le nommant seulement) et produit une **synthèse lisible par un non-technicien**
  (un tableau, une médiane, les mêmes mises en garde que l'écran). (Grammaria,
  `scripts/beta/agreger.ts` : écrit `synthese.md` et `synthese.csv`, garde un seul export par
  participant.)

## 5. Page de transparence

**Une seule page**, écrite pour **deux publics**, chaque partie se lisant seule :

- **Un décideur / une DSI** : ce qui est **prouvé ou non** (le tableau du §1), **où vont les
  données** (en particulier ce qui sort du poste, p. ex. vers un modèle de langage, et ce qui
  reste local), **ce qui est enregistré** exactement, les **licences**, et **ce que le projet
  n'est pas** (pas une preuve scientifique, pas un produit fini garanti).
- **Un testeur** : la **méthode pas à pas**, la **durée** attendue, **ce qu'on lui demande**
  (utiliser normalement, puis exporter), **comment exporter et transmettre** le fichier, et
  **comment arrêter et tout effacer**.

(Grammaria : `docs/.../decouvrir/beta.mdx`, sections « Pour une DSI », « Pour un testeur », « Ce
que l'on mesure et ce que cela ne prouve pas », « Ce qui est partagé, exactement », « Arrêter,
effacer ».)

## 6. Honnêteté

- **Énoncer d'avance ce que serait un résultat décevant** : les unités traitées **ne font pas
  mieux** que le groupe de comparaison. Le dire avant de mesurer, pour ne pas réinterpréter après
  coup.
- **S'engager à le publier aussi.** Une bêta qui ne publierait que les bons résultats ne vérifie
  rien. Le résultat négatif est un résultat.

## Livrables d'une bêta ainsi définie

1. La **promesse falsifiable** (§1) + **LA métrique** et ses **indicateurs d'appui justifiés**
   (§2), fausses métriques écartées par écrit.
2. La **spec de mesure** (§3) : pivot avant/après, groupe de comparaison et son choix, volume
   minimal, limites.
3. Le **format d'export** + sa **validation stricte** + l'**outil d'agrégation** (§4), avec le
   test de garde « aucun contenu ».
4. La **page de transparence** à deux publics (§5) et l'**engagement de publication** du résultat,
   décevant compris (§6).

Pour livrer ces éléments par lots de version, suivre `semver-batch-workflow` ; si plusieurs
sessions d'agents se répartissent le travail (produit, mesure, docs), suivre `agent-team`.
