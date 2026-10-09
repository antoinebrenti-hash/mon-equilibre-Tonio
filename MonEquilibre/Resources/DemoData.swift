import Foundation
import SwiftData

/// Données de démonstration pour tester rapidement tous les écrans,
/// et produits factices pour le mock de recherche (aucun réseau).
public enum DemoData {

    // MARK: Produits factices (mock scan / recherche)

    public static let demoBarcodes: [String: FoodProductInfo] = [
        "3017620422003": FoodProductInfo(
            name: "Pâte à tartiner (démo)", brand: "MarqueDémo", barcode: "3017620422003",
            facts: NutritionFacts(caloriesKcal: 539, proteinG: 6.3, carbG: 57.5, sugarG: 56.3,
                                  fatG: 30.9, saturatedFatG: 10.6, fiberG: 0, saltG: 0.107),
            defaultServingGrams: 15, source: .openFoodFacts),
        "5449000000996": FoodProductInfo(
            name: "Boisson gazeuse (démo)", brand: "MarqueDémo", barcode: "5449000000996",
            facts: NutritionFacts(caloriesKcal: 42, proteinG: 0, carbG: 10.6, sugarG: 10.6,
                                  fatG: 0, saturatedFatG: 0, fiberG: 0, saltG: 0),
            defaultServingGrams: 330, source: .openFoodFacts)
    ]

    public static let demoSearchResults: [FoodProductInfo] = [
        FoodProductInfo(name: "Blanc de poulet", facts: NutritionFacts(caloriesKcal: 110, proteinG: 23, carbG: 0, fatG: 1.5, fiberG: 0), defaultServingGrams: 150, source: .userCreated),
        FoodProductInfo(name: "Riz complet cuit", facts: NutritionFacts(caloriesKcal: 123, proteinG: 2.7, carbG: 25.6, sugarG: 0.4, fatG: 1.0, fiberG: 1.6), defaultServingGrams: 200, source: .userCreated),
        FoodProductInfo(name: "Lentilles cuites", facts: NutritionFacts(caloriesKcal: 116, proteinG: 9, carbG: 20, fatG: 0.4, fiberG: 8), defaultServingGrams: 200, source: .userCreated),
        FoodProductInfo(name: "Yaourt nature", facts: NutritionFacts(caloriesKcal: 61, proteinG: 3.5, carbG: 4.7, sugarG: 4.7, fatG: 3.3, fiberG: 0), defaultServingGrams: 125, source: .userCreated),
        FoodProductInfo(name: "Pomme", facts: NutritionFacts(caloriesKcal: 52, proteinG: 0.3, carbG: 14, sugarG: 10, fatG: 0.2, fiberG: 2.4), defaultServingGrams: 180, source: .userCreated),
        FoodProductInfo(name: "Œuf", facts: NutritionFacts(caloriesKcal: 143, proteinG: 12.6, carbG: 0.7, fatG: 9.5, saturatedFatG: 3.1, fiberG: 0), defaultServingGrams: 55, source: .userCreated),
        FoodProductInfo(name: "Flocons d'avoine", facts: NutritionFacts(caloriesKcal: 375, proteinG: 13, carbG: 60, sugarG: 1, fatG: 7, fiberG: 10), defaultServingGrams: 50, source: .userCreated)
    ]

    // MARK: Seed SwiftData (données de démonstration complètes)

    /// Remplit un contexte avec un profil, des pesées, des repas et une séance.
    /// À appeler depuis les réglages (bouton « Charger les données de démonstration »).
    @MainActor
    public static func seed(into context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Profil
        let profile = UserProfile(
            displayName: "Alex",
            birthDate: cal.date(byAdding: .year, value: -34, to: today),
            heightCm: 178,
            calculationSex: .male,
            activityLevel: .light,
            occupation: "Bureau",
            trainingsPerWeek: 3,
            availableEquipment: ["haltères", "élastique"]
        )
        context.insert(profile)

        let goal = UserGoal(primaryGoal: .loseFat, pace: .gentle, targetWeightKg: 76, acknowledgedEstimateDisclaimer: true)
        context.insert(goal)

        // Pesées sur 30 jours (légère tendance à la baisse + bruit).
        var kg = 83.0
        for d in stride(from: 30, through: 0, by: -1) {
            let date = cal.date(byAdding: .day, value: -d, to: today)!
            let noise = Double((d * 7) % 5) * 0.15 - 0.3   // pseudo-bruit déterministe
            context.insert(WeightEntry(date: date, kg: (kg + noise).rounded(toPlaces: 1)))
            kg -= 0.05
        }

        // Tour de taille (quelques points)
        for (i, d) in [30, 20, 10, 0].enumerated() {
            let date = cal.date(byAdding: .day, value: -d, to: today)!
            context.insert(WaistEntry(date: date, cm: 92.0 - Double(i) * 0.6))
        }

        // Repas d'aujourd'hui
        let breakfast = MealEntry(date: today, mealType: .breakfast, productName: "Flocons d'avoine + yaourt",
                                  quantity: 1, unit: .portion, grams: 175,
                                  facts: NutritionFacts(caloriesKcal: 320, proteinG: 18, carbG: 45, sugarG: 8, fatG: 7, fiberG: 6, saltG: 0.2),
                                  source: .userCreated)
        let lunch = MealEntry(date: today, mealType: .lunch, productName: "Poulet, riz complet, légumes",
                              quantity: 1, unit: .portion, grams: 450,
                              facts: NutritionFacts(caloriesKcal: 560, proteinG: 42, carbG: 60, fatG: 12, fiberG: 8, saltG: 1.2),
                              source: .userCreated)
        context.insert(breakfast)
        context.insert(lunch)

        // Eau
        context.insert(WaterEntry(date: today, milliliters: 1500))

        // Objectif nutritionnel du jour
        let calc = NutritionCalculator()
        let est = calc.estimate(weightKg: 83, heightCm: 178, ageYears: 34, sex: .male,
                                activity: .light, goal: .loseFat, pace: .gentle, activeEnergyKcal: 420)
        context.insert(DailyNutritionTarget(date: today, range: est.targetRange,
                                            proteinGrams: est.proteinGrams, carbGrams: est.carbGrams,
                                            fatGrams: est.fatGrams, fiberGramsMin: est.fiberGramsMin,
                                            waterTargetMl: 2000, isConfirmedByUser: true))

        // Une séance réalisée hier
        let session = WorkoutSession(date: cal.date(byAdding: .day, value: -1, to: today)!,
                                     title: "Haut du corps", perceivedDifficulty: 6,
                                     completed: [
                                        CompletedExercise(exerciseID: "pushup_standard", exerciseName: "Pompes classiques", setsDone: 3, repsDone: [12, 10, 9]),
                                        CompletedExercise(exerciseID: "db_row", exerciseName: "Rowing avec haltère", setsDone: 3, repsDone: [12, 12, 10], weightsKg: [12, 12, 12])
                                     ],
                                     estimatedActiveKcal: 250)
        context.insert(session)

        try? context.save()
    }

    /// Supprime toutes les données de démonstration (et utilisateur).
    @MainActor
    public static func clearAll(context: ModelContext) {
        func wipe<T: PersistentModel>(_ type: T.Type) {
            if let items = try? context.fetch(FetchDescriptor<T>()) {
                items.forEach { context.delete($0) }
            }
        }
        wipe(UserProfile.self); wipe(UserGoal.self); wipe(DailyNutritionTarget.self)
        wipe(FoodProduct.self); wipe(MealEntry.self); wipe(Recipe.self); wipe(RecipeIngredient.self)
        wipe(WeightEntry.self); wipe(WaistEntry.self); wipe(WaterEntry.self)
        wipe(BodyMeasurement.self); wipe(ProgressPhoto.self)
        wipe(WorkoutPlan.self); wipe(WorkoutDay.self); wipe(PlannedExercise.self)
        wipe(WorkoutSession.self); wipe(CompletedExercise.self)
        try? context.save()
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let p = pow(10.0, Double(places))
        return (self * p).rounded() / p
    }
}
