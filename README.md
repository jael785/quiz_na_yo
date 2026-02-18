 Quiz Na Yo

Quiz Na Yo est une application mobile Flutter de quiz hybride combinant :

🔐 Authentification complète (Email/Mot de passe + Google)

🧠 Questions via API externe (OpenTDB)

📂 Mode hors ligne (JSON local)

☁️ Questions dynamiques via Cloud Firestore

🏆 Leaderboard en temps réel

👑 Gestion des rôles (Admin / Utilisateur)

Le projet respecte une architecture organisée et une séparation claire des responsabilités.

📱 Aperçu Fonctionnel

L'application permet :

Création de compte et connexion sécurisée

Choix du mode de quiz (API, Local, Firestore)

Passage du quiz avec timer

Affichage du score et de la durée

Classement en temps réel

Interface administrateur pour gérer le contenu

🧩 Technologies Utilisées
Technologie	Rôle
Flutter	Interface mobile
Provider	Gestion d’état
Firebase Auth	Authentification
Cloud Firestore	Base de données temps réel
OpenTDB API	Questions externes
JSON local	Mode hors ligne
🏗️ Architecture du Projet
lib/
├── controllers/
├── core/
├── models/
├── providers/
├── services/
├── views/
│    ├── screens/
│    └── widgets/
├── firebase_options.dart
└── main.dart


Architecture organisée selon une séparation logique :

Models → Structures de données

Services → Accès API & Firebase

Providers → Gestion d’état

Controllers → Coordination logique

Views → Interface utilisateur

📂 Structure Détaillée des Fichiers
🔹 main.dart

Point d’entrée de l’application.
Initialise Firebase, configure les Providers et lance l’écran principal.

🔹 firebase_options.dart

Fichier généré par FlutterFire contenant la configuration Firebase.

📁 controllers/
auth_controller.dart

Coordonne les opérations d’authentification entre le Provider et le Service.

📁 core/
admin_config.dart

Contient la configuration du rôle administrateur (UID principal).

📁 models/
user_model.dart

Représentation d’un utilisateur.

question_model.dart

Représentation normalisée d’une question (API, Local, Firestore).

leaderboard_entry_model.dart

Structure des données pour le classement.

📁 services/
auth_service.dart

Gestion complète de l’authentification Firebase :

Inscription Email/Mot de passe

Connexion Email/Mot de passe

Connexion Google

Déconnexion

firestore_service.dart

Centralise toutes les interactions avec Cloud Firestore :

Récupération des questions dynamiques

Enregistrement des scores

Mise à jour du leaderboard

Gestion des données administratives

api_service.dart

Gère les appels HTTP vers OpenTDB et transforme les réponses en objets QuestionModel.

local_question_service.dart

Charge les questions depuis un fichier JSON embarqué pour le mode offline.

📁 providers/

Les Providers séparent la logique métier de l’interface.

auth_provider.dart

Gère l’état de connexion et la redirection Admin / Utilisateur.

quiz_provider.dart

Cœur logique du quiz :

Chargement des questions

Timer par question

Calcul du score

Gestion du chronomètre

Rejouer le dernier mode

leaderboard_provider.dart

Récupération et tri du classement en temps réel.

dashboard_provider.dart

Gestion des statistiques utilisateur.

📁 views/
📂 screens/
splash_screen.dart

Écran de démarrage.

gate_screen.dart

Décide automatiquement de la redirection selon l’état d’authentification.

login_screen.dart

Connexion (Email/Mot de passe + Google).

register_screen.dart

Inscription Email/Mot de passe.

home_screen.dart

Choix du mode de quiz.

quiz_screen.dart

Affichage des questions et gestion du timer.

result_screen.dart

Affichage du score final et option rejouer.

leaderboard_screen.dart

Affichage du classement global.

📂 screens/admin/

Contient les écrans permettant à l’administrateur de gérer dynamiquement les données visibles par les utilisateurs.
Toute modification est immédiatement synchronisée via Firestore.

📂 widgets/
loading_overlay.dart

Indicateur global de chargement.

shimmer_block.dart

Effet visuel de chargement pour améliorer l’UX.

🔐 Authentification

L’application propose :

Inscription Email / Mot de passe

Connexion Email / Mot de passe

Connexion Google

Persistance automatique de session

Déconnexion sécurisée

Un utilisateur administrateur est détecté via un UID configuré dans admin_config.dart.

🎮 Modes de Quiz

Mode API → Questions en ligne

Mode Local → Questions embarquées (offline)

Mode Firestore → Questions créées dynamiquement

Le QuizProvider sélectionne automatiquement la source selon le mode choisi.

🏆 Leaderboard

Après chaque quiz :

Le score est enregistré

Le meilleur score est mis à jour si nécessaire

Le classement se met à jour en temps réel

🚀 Installation & Lancement
1️⃣ Cloner le projet
git clone <repo-url>
cd quiz_na_yo

2️⃣ Installer les dépendances
flutter pub get

3️⃣ Configurer Firebase
flutterfire configure


Vérifier :

google-services.json (Android)

SHA1 ajouté dans Firebase

firebase_options.dart généré

4️⃣ Lancer l’application
flutter run

🌐 Déploiement Web (Optionnel)
flutter build web
firebase deploy

🛠️ Compatibilité IDE

Le projet est compatible avec :

Android Studio

Visual Studio Code

IntelliJ IDEA

Requis :

Flutter SDK installé

Dart SDK

Android SDK configuré

🎓 Objectifs Académiques

Ce projet démontre :

Architecture Flutter organisée

Intégration complète Firebase

Gestion d’état avec Provider

CRUD temps réel

API REST externe

Gestion des rôles

Mode offline + online

Classement temps réel

📌 Conclusion

Quiz Na Yo est une application mobile complète, structurée et évolutive combinant :

Authentification sécurisée

Backend dynamique Firestore

API externe

Mode hors ligne

Administration et classement en temps réel