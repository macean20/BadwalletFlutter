# BadWallet Mobile

Application mobile fintech multiplateforme développée en Flutter pour l'écosystème BadWallet. Elle permet de gérer son portefeuille, d'effectuer des transferts d'argent et de régler des factures en temps réel.

## 📱 Fonctionnalités

1. **Authentification & Onboarding (Simulé)**
   - Écran de démarrage avec animations fluides et logo personnalisé.
   - Saisie du numéro de téléphone (format Sénégal +221).
   - Vérification de l'existence du numéro dans la base de données.
   - Simulation d'authentification par code PIN ou par biométrie (empreinte digitale).
   - Écran de création de portefeuille si le numéro n'est pas enregistré.

2. **Tableau de Bord & Gestion du Solde**
   - Affichage dynamique du solde avec option de masquage (sécurité).
   - Accès rapide aux actions clés (Transfert, Paiement de factures, Historique).
   - Liste des 5 dernières transactions avec code couleur (Vert pour les crédits, Rouge pour les débits).
   - Actualisation par glissement vers le bas (Pull-to-refresh).

3. **Transfert d'Argent**
   - Sélection du destinataire avec recherche dans la liste des contacts de test.
   - Pavé numérique virtuel personnalisé pour saisir le montant.
   - Calcul des frais en temps réel (1%, plafonné à 5000 XOF).
   - Écran de confirmation glissant et écran de succès d'opération.

4. **Règlement de Factures (Bulk Payments)**
   - Grille des fournisseurs sénégalais (Senelec, Woyofal, Rapido, ISM).
   - Récupération des factures impayées depuis le service externe.
   - Multi-sélection de factures pour un paiement groupé en une seule transaction.
   - Écran de confirmation et récapitulatif détaillé.

5. **Historique des Transactions**
   - Historique complet de toutes les opérations.
   - Filtres par type (Toutes, Dépôts, Transferts, Paiements).
   - Détails de la transaction, heure de création et référence unique.

---

## 🛠️ Architecture du Projet

L'application suit scrupuleusement l'architecture **« Feature-First »** :

```text
lib/
├── core/
│   ├── api_client.dart       # Configuration de Dio (adresse IP dynamique pour émulateur)
│   ├── secure_storage.dart   # Stockage sécurisé des identifiants (PIN, téléphone)
│   └── theme.dart            # Système de design sombre et premium
├── models/
│   ├── bill_model.dart       # Modèle de données Facture
│   ├── transaction_model.dart # Modèle de données Transaction
│   └── wallet_model.dart     # Modèle de données Portefeuille
├── features/
│   ├── auth/                 # Splash, Login, Enregistrement et providers associés
│   ├── dashboard/            # Accueil, solde et gestion d'état
│   ├── transfers/            # Transfert d'argent et clavier numérique
│   ├── bills/                # Liste des fournisseurs et paiement groupé de factures
│   └── history/              # Historique complet et filtres
└── main.dart                 # Point d'entrée de l'application et injection
```

---

## 🚀 Lancement local

### Prérequis
- Flutter SDK (v3.19+)
- Dart SDK (v3.3+)
- Backend `badwallet-api` et `payment-service` lancés sur le port `8080` (l'application mobile utilise `10.0.2.2:8080` sur l'émulateur Android pour pointer sur le localhost de votre machine).

### Installation
1. Télécharger les dépendances :
   ```bash
   flutter pub get
   ```
2. Générer les icônes de l'application :
   ```bash
   flutter pub run flutter_launcher_icons
   ```
3. Lancer l'application en mode débogage :
   ```bash
   flutter run
   ```

### Génération du livrable (.apk)
Pour générer l'APK de production optimisé et signé :
```bash
flutter build apk --release
```
Le fichier généré sera disponible dans `build/app/outputs/flutter-apk/app-release.apk`.
