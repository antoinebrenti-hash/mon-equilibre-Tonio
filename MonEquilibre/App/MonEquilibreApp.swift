import SwiftUI
import SwiftData

@main
struct MonEquilibreApp: App {
    /// Conteneur SwiftData regroupant tous les modèles persistés localement.
    let container: ModelContainer
    @StateObject private var env = AppEnvironment.live()

    init() {
        let schema = Schema([
            UserProfile.self, UserGoal.self, DailyNutritionTarget.self, AppSettings.self,
            FoodProduct.self, MealEntry.self, Recipe.self, RecipeIngredient.self,
            WeightEntry.self, WaistEntry.self, WaterEntry.self, BodyMeasurement.self, ProgressPhoto.self,
            WorkoutPlan.self, WorkoutDay.self, PlannedExercise.self, WorkoutSession.self, CompletedExercise.self
        ])
        // Stockage local uniquement. iCloud reste une option future, non activée par défaut.
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Impossible de créer le ModelContainer : \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(env)
        }
        .modelContainer(container)
    }
}
