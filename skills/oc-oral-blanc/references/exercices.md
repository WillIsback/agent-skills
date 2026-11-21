# Exercices pratiques du mode apprentissage

Un exercice dure **au plus 15 minutes**, se fait dans `exercices/` (non versionné) et a
un **critère de réussite observable**. William le réalise lui-même ; l'agent donne la
consigne, répond aux questions et vérifie le résultat. Choisir celui qui touche
exactement la notion non maîtrisée ; en inventer un du même format si aucun ne convient.

| Domaine | Exercice | Critère de réussite |
|---|---|---|
| Tests | Casser volontairement une ligne du code testé, lancer la suite, expliquer quel test échoue et pourquoi. | William prédit le test en échec **avant** de lancer, puis l'explique. |
| Tests | Écrire un test pour un cas limite non couvert (valeur manquante, hors plage, mauvais type). | Le test échoue sur une version fautive et passe sur la bonne. |
| Couverture | Lire le rapport de couverture et désigner la ligne non couverte la plus risquée. | Choix argumenté par l'impact d'une erreur sur cette ligne. |
| API et validation | Écrire une règle de validation (schéma Pydantic, bornes) et l'essayer avec `curl` sur une entrée valide et deux invalides. | Codes HTTP et messages attendus obtenus et expliqués. |
| API | Mesurer la latence de 50 requêtes avec et sans chargement du modèle à chaque appel. | Écart mesuré et expliqué. |
| Docker | Construire l'image à la main, puis retirer une ligne `COPY` et observer l'échec. | William explique ce que chaque instruction apporte et pourquoi l'image n'embarque que le nécessaire. |
| CI/CD | Lire un run GitHub Actions et retracer l'ordre des jobs et leurs dépendances (`needs`). | Schéma correct de l'ordre test → build → déploiement. |
| CI/CD | Introduire une erreur de lint sur une branche et prédire quel job bloque. | Prédiction juste et explication du rôle de la protection de branche. |
| Données et drift | Interpréter un graphique ou un rapport de drift (Evidently ou équivalent) sur une feature. | Distinguer changement de population, problème de collecte et vraie dégradation ; proposer une action. |
| Données | Calculer à la main un PSI ou une statistique de test sur deux petits échantillons. | Valeur cohérente avec l'outil et lecture correcte du seuil. |
| Performance | Profiler une fonction (`cProfile`), trouver le goulot d'étranglement. | Goulot nommé avec le chiffre qui le prouve. |
| Performance | Comparer le temps d'inférence avant et après une optimisation (ONNX, batch). | Gain mesuré, et vérification que les prédictions sont identiques ou dans une tolérance définie. |
| ML | Changer le seuil de décision et observer l'effet sur le coût métier. | William relie seuil, faux positifs, faux négatifs et coût. |
| Sécurité | Repérer où un secret pourrait fuiter (logs, image, dépôt) et vérifier qu'il ne fuit pas. | Emplacement sûr justifié (secret CI, variable d'environnement). |
