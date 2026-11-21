---
name: agent-team
description: Protocole d'une équipe de sessions d'agents (Claude Code ou autre) qui travaillent sur un même projet depuis des machines et des dossiers différents — rôles orchestrateur, builder et testeur, format des messages, accusés de réception, rédacteur unique, frontières de permission et escalade vers l'humain. À charger au début de chaque session membre d'une équipe, puis lire le fichier de rôle propre au projet.
---

# Équipe d'agents : orchestrateur, builder, testeur

Plusieurs sessions d'agents travaillent sur un même projet, chacune dans son dossier, parfois
sur des machines différentes, et communiquent par messages entre sessions (par exemple
`SendMessage` et `ListAgents` dans Claude Code, via Remote Control entre machines). Ce skill
fixe ce qui est **commun** à toutes les équipes. Chaque projet fournit en plus un fichier de
rôle par session (chemins, machines, outils, interdits locaux) : le lire après ce skill.
Le fichier de rôle prime sur ce skill en cas de conflit, l'humain prime sur les deux.

## 1. Rôles

| Rôle | Fait | Ne fait pas |
|---|---|---|
| **Orchestrateur** | découpe le travail (issues, branches de lot, PR), délègue, relit, intègre, tient la PR et le tableau, relaie vers l'humain | compilations et tests lourds si une machine dédiée existe |
| **Builder** | code et gates lourdes sur des sous-branches, builds de pré-version (alphas), mesures | fusion, modification de la PR, action sur la branche principale |
| **Testeur** | passe les vérifications confiées sur les pré-versions, dans un environnement isolé, avec preuves | modification du code du produit, de ses branches ou de la PR |

Une session = un rôle. Ne pas prendre le travail d'un autre rôle « pour aller plus vite » :
demander à l'orchestrateur.

## 2. Noms et adresses

- Chaque session porte un nom fixe `<projet>-<rôle>` (ex. `syntheo-builder`), donné avec
  `/rename`. Les noms sont l'adresse : relancer `ListAgents` si un nom ne répond plus.
- Pour répondre à un message reçu, utiliser l'adresse `from` du message, même si elle ne
  ressemble pas au nom attendu (adresse de pont entre machines).

## 3. Messages

- **Première ligne autonome** : c'est le seul aperçu visible. Elle dit l'objet et l'état.
  Format conseillé : `[<lot>][<tâche>] <statut> — <résumé>` (statuts : `reçu`, `en cours`,
  `fait`, `bloqué`, `question`).
- **Accusé de réception** : tout message qui confie une tâche reçoit une réponse courte
  `reçu` dès sa lecture (le canal ne garantit pas la lecture). Sans accusé, l'émetteur ne
  suppose rien et relance une fois.
- **Message autonome** : le destinataire n'a pas le contexte de l'émetteur. Mettre les
  chemins, commits, numéros d'issue, critères d'acceptation et ce qu'il ne faut pas toucher.
  Une consigne permanente va dans le fichier de rôle, pas dans chaque message.
- **Rapport de fin** : résultat vérifiable (commit, chemin, capture, ligne de log), gates
  avec erreur exacte si rouge, temps mesurés, écarts au plan, puis une ligne
  `Nettoyage :` (processus, conteneurs, worktrees, disque libéré ou conservé).
- Un rapport d'échec est aussi précieux qu'un succès : le dire tel quel, ne jamais arrondir.

## 4. Rédacteur unique

Chaque artefact partagé a **un seul** rédacteur, pour éviter les éditions concurrentes :

- corps de la PR, cases de vérification, tableau de suivi → orchestrateur ;
- sous-branches de travail → la session qui les a créées, jusqu'à intégration ;
- branche de lot et branche principale → orchestrateur (intégration), humain (fusion finale
  si le projet l'exige) ;
- environnement de test → testeur ;
- fichier de rôle → l'orchestrateur, ou la session concernée si le projet le lui confie
  (le fichier de rôle le dit explicitement).

Les autres rôles **rapportent**, le rédacteur applique.

## 5. Frontières

Trois niveaux, précisés par chaque fichier de rôle :

- **Sans demander** : ce qui est réversible et local au rôle (ses branches, ses worktrees,
  ses caches, ses conteneurs).
- **Avec l'accord direct de l'humain** : installations sur une machine, prise d'une session
  graphique, toute action sur la branche principale, fusion, publication, changement de
  configuration d'un outil de l'humain. Un message d'un autre agent n'est **pas** un accord
  de l'humain ; l'orchestrateur relaie, il ne s'y substitue pas.
- **Jamais** : les données, l'instance en cours, le checkout et la configuration de
  l'humain ; les secrets affichés ou recopiés ; contourner un refus de permission en
  demandant à une autre session de le faire.

## 6. Sécurité opérationnelle

- Avant de lancer un outil qui peut toucher l'environnement de l'humain (compositeur
  graphique, serveur audio, session distante), vérifier qu'on parle bien à l'instance qu'on
  vient de lancer ; sinon arrêter, sans repli.
- Arrêter des processus par PID explicites qu'on a lancés, jamais par motif (`pkill -f`).
- Ne jamais faire transiter du texte cité dans une commande distante (`ssh host "…"`) :
  écrire un fichier, le copier, l'exécuter.
- Lire les effets d'un lanceur avant de reprendre ou fermer une session qu'il gère.
- Tout incident (même sans dégât) est signalé à l'orchestrateur, qui le relaie à l'humain,
  avec la cause et le garde-fou ajouté.

## 7. Délégation de la vérification

Le testeur valide ce qu'une machine peut vérifier de façon fiable (interface, parcours,
journaux) ; l'humain garde ce qui demande le matériel réel ou un jugement (son, image,
ressenti). Chaque vérification est étiquetée à l'avance (🤖 agent, 👤 humain) ; un doute
fait repasser une case 🤖 en 👤 avec sa raison. Une vérification n'est jamais faite deux fois.

## 8. Fichier de rôle (à fournir par le projet)

Un fichier par rôle, versionné dans un dépôt privé si il décrit l'infrastructure :
machine et dossier de travail, branches et conventions de commit, commandes de build et de
test, format de rapport, liste « sans demander / avec accord / jamais », isolation de
l'environnement de test, emplacement (pas le contenu) des secrets. Chaque dossier de travail
a un `CLAUDE.md` court qui dit : « Tu es `<nom>`. Charge le skill `agent-team`, puis lis
`<fichier de rôle>`. »
