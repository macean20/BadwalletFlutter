# 📱 Explications du Projet — BadWallet Mobile

Ce document présente une explication simple et structurée du projet **BadWallet Mobile**, son architecture, ses fonctionnalités et les technologies utilisées, conformément aux exigences du sujet.

---

## 🎯 1. Présentation du Projet
**BadWallet Mobile** est une application mobile "Consumer" (orientée client final) conçue pour permettre aux utilisateurs de gérer leur portefeuille électronique directement depuis leur smartphone. Son design moderne et fluide s'inspire d'applications populaires telles que Wave, Orange Money ou PayPal.

L'application communique avec deux microservices backend Spring Boot fonctionnant sur la machine hôte :
*   **BadWallet API** : Gère les portefeuilles, les soldes et les transferts d'argent.
*   **Payment Service** : Gère la facturation externe (récupération et paiement de factures).

---

## 🛠️ 2. Technologies Utilisées
L'application s'appuie sur la stack technologique demandée :
*   **Flutter** : Framework de développement multiplateforme pour créer une interface utilisateur moderne et performante.
*   **Dart** : Langage de programmation moderne utilisé par Flutter.
*   **HTTP/Dio** : Client HTTP robuste permettant de communiquer avec l'API backend (`localhost:8080` ou `10.0.2.2:8080` sur l'émulateur Android).
*   **Provider** : Solution de gestion d'état légère permettant de propager les données de l'API (solde, historique, factures) à travers l'interface utilisateur.
*   **Flutter Secure Storage** : Utilisé pour sauvegarder localement de manière chiffrée le numéro de téléphone et le PIN de l'utilisateur pour la persistance de session.
*   **Flutter Launcher Icons** : Outil pour générer l'icône personnalisée de l'application sur Android et iOS.
*   **Intl** : Bibliothèque de formatage pour les dates et la devise (ex: `50 000 XOF`).

---

## 📁 3. Architecture du Projet (Feature-First)
Le projet est organisé selon une structure **« Feature-First »** (par fonctionnalité), ce qui permet de séparer proprement le code et de faciliter son évolution.

```text
lib/
├── core/                 # Socle commun de l'application
│   ├── api_client.dart   # Client Dio configuré pour se connecter aux APIs
│   ├── secure_storage.dart # Logique de stockage sécurisé du numéro et PIN
│   └── theme.dart        # Thème graphique premium et palette de couleurs
│
├── models/               # Modèles de données désérialisés du JSON backend
│   ├── wallet_model.dart # Représente le portefeuille d'un utilisateur
│   ├── transaction_model.dart # Représente un transfert ou dépôt
│   └── bill_model.dart   # Représente une facture (Senelec, Rapido, etc.)
│
├── features/             # Modules fonctionnels de l'application
│   ├── auth/             # Onboarding, Splash screen, connexion par PIN & biométrie
│   ├── dashboard/        # Accueil, affichage et masquage du solde
│   ├── transfers/        # Clavier numérique personnalisé et envoi d'argent
│   ├── bills/            # Récupération et paiement groupé de factures
│   └── history/          # Suivi complet de l'historique avec filtres
│
└── main.dart             # Point d'entrée de l'application et injection des Providers
```

---

## ⚙️ 4. Fonctionnalités Principales & Correspondances API

### 🔑 1. Authentification & Onboarding (Simulé et Réel)
*   **Splash Screen** : Écran d'accueil animé affichant le logo de BadWallet au démarrage, puis vérifiant si une session existe déjà.
*   **Connexion par téléphone** : L'utilisateur saisit son numéro (format Sénégal `+221...`). L'app interroge le backend (`GET /api/wallets/{phone}`) pour vérifier si le compte existe. Si oui, l'utilisateur saisit son code PIN.
*   **Biométrie** : Simulation d'empreinte digitale locale pour déverrouiller l'accès de façon ergonomique.
*   **Création de compte** : Si le numéro n'existe pas en base de données, l'application propose un écran d'enregistrement (`POST /api/wallets`).

### 📊 2. Tableau de Bord (Home)
*   **Affichage du solde** : Le solde est récupéré en temps réel (`GET /api/wallets/{phone}/balance`). Il peut être masqué/affiché en cliquant sur une icône d'œil pour garantir la confidentialité en public.
*   **Actions rapides** : 3 boutons permettent d'accéder instantanément aux écrans de Transfert, Paiement de factures et Historique.
*   **Dernières transactions** : Affiche les 5 opérations les plus récentes avec un pull-to-refresh pour actualiser le solde et les transactions.

### 💸 3. Opérations Financières
*   **Transferts d'argent (Send)** :
    *   Saisie du destinataire (avec possibilité de sélectionner dans une liste de contacts de démonstration).
    *   Saisie du montant via un **pavé numérique virtuel personnalisé** intégré directement dans l'interface (évite d'ouvrir le clavier système).
    *   Calcul des frais de **1%** en temps réel (plafonné à 5000 XOF).
    *   Écran de confirmation coulissant et écran de succès d'opération.
    *   **Endpoint API** : `POST /api/wallets/transfer`

*   **Paiement de Factures (Bills)** :
    *   Grille des fournisseurs locaux (SENELEC, WOYAFAL, RAPIDO, ISM).
    *   Récupération dynamique des factures impayées du client (`GET /api/external/factures/{phone}/current?unite=NAME`).
    *   **Paiement Groupé (Bulk)** : L'utilisateur coche une ou plusieurs factures et peut toutes les régler d'un coup.
    *   **Endpoint API** : `POST /api/wallets/pay-factures`

### 📜 4. Historique des Transactions (History)
*   Écran dédié listant l'intégralité des transactions de l'utilisateur (`GET /api/wallets/{phone}/transactions`).
*   Des onglets de filtrage permettent d'isoler rapidement les opérations (Toutes, Dépôts, Transferts, Paiements).
*   **Code couleur intuitif** :
    *   **Vert** pour les entrées d'argent (Dépôts, transferts reçus).
    *   **Rouge** pour les sorties d'argent (Paiements de factures, transferts envoyés).

---

## 📶 5. Gestion de la Connexion Réseau (`10.0.2.2`)
Sur un émulateur Android, l'adresse réseau standard `localhost` ou `127.0.0.1` pointe vers le système interne de l'émulateur lui-même. Pour rediriger les requêtes vers le serveur Spring Boot qui tourne sur votre machine hôte, Flutter utilise l'adresse IP spéciale **`10.0.2.2:8080`**.
Cette configuration dynamique est gérée de manière transparente dans `lib/core/api_client.dart`.

---

## 📦 6. Génération de l'APK de Production
Pour compiler et livrer le fichier final installable sur un smartphone Android réel :
1.  On configure l'icône de l'application dans `pubspec.yaml` puis on génère les ressources d'icônes :
    ```bash
    flutter pub run flutter_launcher_icons
    ```
2.  On lance la compilation finale optimisée :
    ```bash
    flutter build apk --release
    ```
Le livrable final est généré à l'emplacement suivant :
`build/app/outputs/flutter-apk/app-release.apk`
