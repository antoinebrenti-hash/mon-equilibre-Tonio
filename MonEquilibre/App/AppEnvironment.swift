import Foundation
import SwiftUI

/// Conteneur d'injection de dépendances.
/// Choisit automatiquement les implémentations réelles ou les mocks
/// (utile pour le simulateur, les tests et les aperçus SwiftUI).
public final class AppEnvironment: ObservableObject {
    public let health: HealthDataProviding
    public let food: FoodProductProviding
    public let notifications: NotificationScheduling
    public let export: DataExporting
    public let nutrition: NutritionCalculating
    public let planner: WorkoutPlanning
    public let advisor: FoodAdvisor
    public let weeklyReview: WeeklyReview
    public let weightTrend: WeightTrend
    public let recalibrator: MaintenanceRecalibrator
    public let exerciseLibrary: [Exercise]

    public init(health: HealthDataProviding,
                food: FoodProductProviding,
                notifications: NotificationScheduling,
                export: DataExporting = DataExportService(),
                nutrition: NutritionCalculating = NutritionCalculator(),
                planner: WorkoutPlanning = WorkoutPlanner(),
                advisor: FoodAdvisor = FoodAdvisor(),
                weeklyReview: WeeklyReview = WeeklyReview(),
                weightTrend: WeightTrend = WeightTrend(),
                recalibrator: MaintenanceRecalibrator = MaintenanceRecalibrator(),
                exerciseLibrary: [Exercise] = ExerciseLibrary.all) {
        self.health = health
        self.food = food
        self.notifications = notifications
        self.export = export
        self.nutrition = nutrition
        self.planner = planner
        self.advisor = advisor
        self.weeklyReview = weeklyReview
        self.weightTrend = weightTrend
        self.recalibrator = recalibrator
        self.exerciseLibrary = exerciseLibrary
    }

    /// Environnement de production (appareil réel).
    public static func live() -> AppEnvironment {
        #if targetEnvironment(simulator)
        return preview()
        #else
        #if canImport(HealthKit)
        let health: HealthDataProviding = HealthKitService()
        #else
        let health: HealthDataProviding = MockHealthKitService()
        #endif
        #if canImport(UserNotifications)
        let notif: NotificationScheduling = NotificationService()
        #else
        let notif: NotificationScheduling = MockNotificationService()
        #endif
        return AppEnvironment(health: health,
                              food: OpenFoodFactsService(),
                              notifications: notif)
        #endif
    }

    /// Environnement de démonstration / aperçu (aucun réseau, aucune permission requise).
    public static func preview() -> AppEnvironment {
        AppEnvironment(health: MockHealthKitService(),
                       food: MockFoodProductService(byBarcode: DemoData.demoBarcodes,
                                                    searchResults: DemoData.demoSearchResults),
                       notifications: MockNotificationService())
    }
}
