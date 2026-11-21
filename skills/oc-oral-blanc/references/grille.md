# Grille d'évaluation

| Niveau | Définition | Suite |
|---|---|---|
| **maîtrisé** | Le **quoi** (ce qui est fait), le **pourquoi** (la raison, le problème évité) et au moins une **conséquence** ou une **alternative** (ce qui se passerait sinon, ce qu'on a écarté et pourquoi). Vocabulaire juste, lien avec le projet réel. | Question suivante. |
| **partiel** | Le quoi est juste, mais le pourquoi est vague, récité, ou sans lien avec le projet ; ou une imprécision technique notable. | Mode apprentissage, puis question reposée sous un autre angle. |
| **à revoir** | Réponse fausse, hors sujet, ou « je ne sais pas ». | Mode apprentissage (avec exercice si utile), puis question reposée. |

Une réponse ne devient pas « maîtrisé » parce qu'elle est longue ; un « maîtrisé » peut
tenir en trois phrases.

## Exemple : « Pourquoi charges-tu le modèle au démarrage de l'API et pas à chaque requête ? »

- **à revoir** : « Parce que c'est la bonne pratique. » (aucun quoi ni pourquoi)
- **partiel** : « Pour que ce soit plus rapide. » (le pourquoi est juste mais vague :
  rapide comment, par rapport à quoi ?)
- **maîtrisé** : « Le modèle est désérialisé une fois dans le `lifespan` de FastAPI et
  gardé en mémoire. Le charger à chaque requête coûterait la lecture et la
  désérialisation du fichier à chaque appel — des centaines de millisecondes au lieu de
  quelques-unes — et ferait exploser la mémoire sous charge avec des copies concurrentes.
  La contrepartie : un démarrage plus lent et un redémarrage nécessaire pour changer de
  version du modèle. »

## Exemple : « Ton rapport de drift signale `bureau_balance`. Que fais-tu ? »

- **à revoir** : « Je réentraîne le modèle. » (réflexe sans analyse)
- **partiel** : « C'est une dérive de distribution, il faut surveiller. » (constat sans
  interprétation ni action)
- **maîtrisé** : « La part de clients couverts par `bureau_balance` passe de 30 % à 87 % :
  c'est un changement de population ou de collecte, pas forcément une dégradation. Je
  vérifie d'abord l'impact sur la distribution des scores et sur les features importantes
  du modèle ; sans cible en production, je ne peux pas mesurer la performance réelle. Si
  les scores dérivent, je planifie un réentraînement sur des données récentes, sinon
  j'ajuste le seuil d'alerte pour cette feature. »
