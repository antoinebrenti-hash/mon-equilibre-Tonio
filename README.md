# Mon Équilibre — application iPhone (SwiftUI / SwiftData / HealthKit)

Application personnelle de suivi des calories, du poids, du tour de taille et
d'entraînement, **100 % locale** (aucun serveur obligatoire, aucune IA payante).
Le scan de codes-barres et Open Food Facts sont **facultatifs**.

> ⚠️ **Important — il faut un Mac.** Une application iPhone native ne peut être
> compilée et installée que depuis **Xcode sur macOS**. Ce dossier contient tout
> le code source ; les étapes de compilation/installation se font sur un Mac.
> Le code a été écrit avec soin mais n'a **pas** pu être compilé sur la machine
> qui l'a généré (Windows). Prévois une première passe de compilation dans Xcode
> pour corriger d'éventuels avertissements mineurs.

---

## A. Vue d'ensemble de l'architecture

Architecture **MVVM + services** avec injection de dépendances, séparation stricte :

- **Models** — objets SwiftData persistés localement (`@Model`) + types de valeur (`NutritionFacts`, `Exercise`).
- **Calculations** — moteurs **purs et testables**, sans dépendance UI ni base de données :
  - `NutritionCalculator` : métabolisme (Mifflin-St Jeor), maintien, objectif en **plage**, planchers de sécurité.
  - `WeightTrend` + `MaintenanceRecalibrator` : moyenne mobile, tendance (régression), recalibrage prudent après ≥ 14 jours.
  - `WorkoutPlanner` : génération d'un programme hebdomadaire équilibré avec jours de récupération.
  - `FoodAdvisor` : écran « Que puis-je manger ? » (plusieurs pistes, jamais « bon/mauvais »).
  - `WeeklyReview` : bilan hebdomadaire prudent (jamais de diagnostic).
- **Services** (avec protocoles + mocks) :
  - `HealthDataProviding` → `HealthKitService` / `MockHealthKitService`.
  - `FoodProductProviding` → `OpenFoodFactsService` / `MockFoodProductService`.
  - `NotificationScheduling` → `NotificationService` / `MockNotificationService`.
  - `DataExporting` → `DataExportService` (CSV + JSON).
- **Views** — SwiftUI, 5 onglets (Accueil, Repas, Progrès, Exercices, Profil).
- **Components** — composants réutilisables (cartes, jauges, bannières de sécurité, états vides…).
- **Resources** — bibliothèque d'exercices, données de démonstration, localisation FR/PL.

`AppEnvironment` choisit automatiquement les implémentations **réelles** (appareil)
ou **mocks** (simulateur / aperçus / tests).

## Écrans principaux

| Onglet | Contenu |
|---|---|
| Accueil | Tableau de bord du jour : jauge calories, macros, eau, pas & calories actives (Apple Santé), poids & tendance, boutons rapides, message non culpabilisant. |
| Repas | Repas par catégorie, recherche / saisie manuelle / scan / cache local, correction des valeurs avant enregistrement, écran « Que manger ? ». |
| Progrès | Poids (points + moyenne mobile), tour de taille, calories/jour, régularité, sélecteur de période, export CSV. |
| Exercices | Génération d'un programme équilibré, séances (échauffement → principal → complémentaire → retour au calme), fiches exercices avec consignes et avertissements. |
| Profil | Identité, corps, objectif, **drapeaux de sécurité santé** (bloquent le déficit automatique), calcul & confirmation de l'objectif, Apple Santé, notifications, export, suppression, mentions médicales. |

---

## B. Arborescence du projet

```
MonEquilibre/
├── project.yml                      # génère le .xcodeproj via XcodeGen (optionnel mais recommandé)
├── README.md
├── MonEquilibre/
│   ├── App/
│   │   ├── MonEquilibreApp.swift     # @main, ModelContainer SwiftData
│   │   ├── ContentView.swift         # TabView 5 onglets
│   │   ├── AppEnvironment.swift      # injection de dépendances (live/preview)
│   │   ├── MonEquilibre.entitlements # HealthKit
│   │   └── Info-reference.plist      # clés Info.plist de référence
│   ├── Models/
│   │   ├── Enums.swift
│   │   ├── Exercise.swift            # donnée de référence (struct)
│   │   ├── UserModels.swift          # UserProfile, UserGoal, DailyNutritionTarget, AppSettings
│   │   ├── FoodModels.swift          # FoodProduct, MealEntry, Recipe, RecipeIngredient, NutritionFacts
│   │   ├── TrackingModels.swift      # Weight/Waist/Water/BodyMeasurement/ProgressPhoto
│   │   └── WorkoutModels.swift       # WorkoutPlan/Day/PlannedExercise/Session/CompletedExercise
│   ├── Calculations/
│   │   ├── NutritionCalculator.swift
│   │   ├── WeightTrend.swift
│   │   ├── WorkoutPlanner.swift
│   │   ├── FoodAdvisor.swift
│   │   └── WeeklyReview.swift
│   ├── Services/
│   │   ├── HealthKitService.swift
│   │   ├── FoodProductService.swift  # Open Food Facts + mock
│   │   ├── NotificationService.swift
│   │   └── DataExportService.swift
│   ├── Views/
│   │   ├── Home/HomeView.swift
│   │   ├── Meals/{MealsView, AddFoodView, BarcodeScannerView, WhatCanIEatView}.swift
│   │   ├── Progress/{ProgressDashboardView, QuickEntrySheets, WeeklyReviewView}.swift
│   │   ├── Workouts/{WorkoutsView, WorkoutSetupView}.swift
│   │   └── Profile/ProfileView.swift
│   ├── Components/UIComponents.swift
│   └── Resources/
│       ├── ExerciseLibrary.swift
│       ├── DemoData.swift
│       ├── fr.lproj/{Localizable, InfoPlist}.strings
│       └── pl.lproj/{Localizable, InfoPlist}.strings
└── MonEquilibreTests/
    └── CalculationTests.swift
```

---

## C / D. Créer le projet Xcode & vérifier

### Méthode recommandée — XcodeGen (fiable, reproductible)

Sur le Mac, dans le dossier `MonEquilibre/` :

```bash
brew install xcodegen
xcodegen generate
open MonEquilibre.xcodeproj
```

`project.yml` configure déjà : cible iOS 17, textes d'autorisation, entitlements
HealthKit, cible de tests. Il ne reste qu'à choisir ton **équipe de signature**.

### Méthode manuelle (sans XcodeGen)

1. Xcode → **File > New > Project… > iOS > App**.
2. Product Name : `MonEquilibre`, Interface : **SwiftUI**, Storage : **SwiftData**, Language : **Swift**.
3. Supprime les fichiers `ContentView.swift` / `…App.swift` créés par défaut.
4. Glisse le dossier `MonEquilibre/` de ce projet dans le navigateur Xcode
   (« Copy items if needed », « Create groups »).
5. Ajoute une cible de test si besoin et glisses-y `MonEquilibreTests/`.
6. Renseigne les clés d'autorisation (voir `App/Info-reference.plist`) dans
   la cible → onglet **Info**.

### Vérifications (étape D)

- **Imports** : `SwiftUI`, `SwiftData`, `Charts`, `HealthKit`, `VisionKit`,
  `UserNotifications` sont tous des frameworks Apple (aucune dépendance externe).
- Les usages de `HealthKit`, `VisionKit`, `UserNotifications` sont protégés par
  `#if canImport(...)` : l'app compile aussi dans des contextes réduits.
- Aucune donnée n'est envoyée à un serveur, sauf appel **facultatif** à Open Food
  Facts lors d'une recherche/scan.

---

## E. Tests & données de démonstration

- Tests unitaires : `MonEquilibreTests/CalculationTests.swift` couvre le
  métabolisme, le maintien, l'objectif, les **limites de sécurité**, la portion,
  la recette, la moyenne mobile, le recalibrage, la génération du programme, les
  **jours de récupération**, l'équilibre du programme et l'export CSV.
  Lance-les avec **⌘U**.
- Données de démonstration : **Profil → « Charger les données de démonstration »**
  crée un profil, 30 jours de pesées, des repas, une séance, un objectif. Le
  simulateur utilise déjà des mocks (pas de réseau, pas de permission requise).

---

## F. Installer sur ton iPhone

1. **Ouvre le projet** (`open MonEquilibre.xcodeproj`).
2. Cible **MonEquilibre → Signing & Capabilities** : coche *Automatically manage
   signing*, choisis ton **Team** (ton identifiant Apple ; un compte gratuit
   suffit pour installer sur ton propre appareil).
3. Vérifie la capability **HealthKit** (déjà déclarée via les entitlements). Si
   absente : **+ Capability → HealthKit**.
4. Vérifie les **descriptions d'autorisation** (Santé + Caméra) dans l'onglet
   **Info** (déjà fournies via `project.yml` / `Info-reference.plist`).
5. **Connecte ton iPhone** en USB, déverrouille-le, « Faire confiance » à l'ordinateur.
6. Dans la barre d'Xcode, **sélectionne ton iPhone** comme destination.
7. **⌘R** pour compiler et installer.
8. Sur l'iPhone (compte gratuit) : **Réglages → Général → VPN et gestion de
   l'appareil → ton profil développeur → Faire confiance**. Relance l'app.
9. **Archive** (pour TestFlight/App Store) : destination *Any iOS Device* →
   **Product → Archive**.
10. **TestFlight** : dans l'Organizer, *Distribute App → App Store Connect →
    Upload*, puis dans App Store Connect, ajoute la build à TestFlight et
    invite-toi comme testeur (l'app TestFlight installe la bêta sur ton iPhone).
11. **Compte payant requis ?** Installer sur *ton* appareil via Xcode : **compte
    gratuit** (l'app expire au bout de 7 jours et se réinstalle avec ⌘R).
    TestFlight, l'App Store et les provisioning longue durée : **Apple Developer
    Program payant (99 €/an)**.
12. **Conserver/mettre à jour tes données entre versions** : les données vivent
    dans le store SwiftData local de l'app. Tant que le **Bundle Identifier** ne
    change pas et que tu **réinstalles par-dessus** (⌘R ou TestFlight), tes
    données sont conservées. La désinstallation efface le store. Utilise l'**export
    CSV/JSON** (onglet Progrès) comme sauvegarde. La synchronisation iCloud est
    prévue comme évolution future (non activée par défaut, pour la vie privée).

---

## Choix de conception (santé & prudence)

- Objectif présenté en **plage**, jamais comme une vérité exacte ; **plancher de
  sécurité** (jamais sous ~1500 kcal H / ~1200 kcal F ni sous le métabolisme).
- **Aucun déficit automatique** si un drapeau de sécurité est coché (mineur,
  grossesse/allaitement, antécédent de TCA, maladie chronique, etc.) → orientation
  vers un avis professionnel.
- Recalibrage **seulement après ≥ 14 jours**, plafonné, et **confirmé par toi**.
- Ton **non culpabilisant** partout ; on met en avant la **moyenne de la semaine**.
- Programmes toujours **équilibrés**, avec **récupération** et **avertissements**
  clairs (arrêt en cas de douleur, malaise, vertige…).
- L'app **ne promet pas** de perte de graisse localisée : elle explique que la
  graisse abdominale diminue surtout avec la baisse **générale** de masse grasse.

## Limites connues / à finir dans Xcode

- La localisation **polonaise** est amorcée (`*.lproj/Localizable.strings`,
  autorisations traduites). L'interface est aujourd'hui rédigée en **français**
  dans le code ; pour un polonais complet, migre les textes vers un **String
  Catalog** (`.xcstrings`) — Xcode extrait alors chaque chaîne à traduire.
- Le scan de codes-barres nécessite un **appareil réel** (la caméra n'existe pas
  au simulateur) ; l'app bascule proprement vers la saisie manuelle sinon.
- Première compilation : corrige d'éventuels avertissements mineurs propres à ta
  version d'Xcode (le code cible iOS 17 / Swift 5).
