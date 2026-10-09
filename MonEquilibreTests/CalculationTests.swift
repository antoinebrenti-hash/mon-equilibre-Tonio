import XCTest
@testable import MonEquilibre

final class NutritionCalculatorTests: XCTestCase {

    let calc = NutritionCalculator()

    func testBMR_Male_MifflinStJeor() {
        // 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
        let bmr = calc.basalMetabolicRate(weightKg: 80, heightCm: 180, ageYears: 30, sex: .male)
        XCTAssertEqual(bmr, 1780, accuracy: 0.5)
    }

    func testBMR_Female_MifflinStJeor() {
        // 10*60 + 6.25*165 - 5*30 - 161 = 600 + 1031.25 - 150 - 161 = 1320.25
        let bmr = calc.basalMetabolicRate(weightKg: 60, heightCm: 165, ageYears: 30, sex: .female)
        XCTAssertEqual(bmr, 1320.25, accuracy: 0.5)
    }

    func testMaintenance_UsesActivityFactor_WhenNoHealthData() {
        let bmr = 1780.0
        let m = calc.maintenanceCalories(bmr: bmr, activity: .light, activeEnergyKcal: nil)
        XCTAssertEqual(m, bmr * 1.375, accuracy: 0.5)
    }

    func testMaintenance_BlendsHealthData_WhenAvailable() {
        let bmr = 1780.0
        let factor = bmr * 1.375
        let measured = (bmr + 500) * 1.10
        let expected = (factor + measured) / 2
        let m = calc.maintenanceCalories(bmr: bmr, activity: .light, activeEnergyKcal: 500)
        XCTAssertEqual(m, expected, accuracy: 0.5)
    }

    func testObjective_LoseFat_ProducesRangeBelowMaintenance() {
        let est = calc.estimate(weightKg: 90, heightCm: 180, ageYears: 30, sex: .male,
                                activity: .light, goal: .loseFat, pace: .gentle, activeEnergyKcal: nil)
        XCTAssertLessThan(est.targetRange.center, est.maintenance)
        XCTAssertEqual(est.targetRange.high - est.targetRange.low, 200)
        XCTAssertLessThan(est.targetRange.low, est.targetRange.center)
    }

    func testSafetyFloor_NeverBelowMinimum() {
        // Petite personne + rythme soutenu : le plancher de sécurité doit s'appliquer.
        let est = calc.estimate(weightKg: 48, heightCm: 150, ageYears: 60, sex: .female,
                                activity: .sedentary, goal: .loseFat, pace: .steady, activeEnergyKcal: nil)
        XCTAssertGreaterThanOrEqual(est.targetRange.center, Int(NutritionCalculator.SafetyFloor.female))
        XCTAssertTrue(est.isSafetyLimited)
    }

    func testDeficit_NeverExceedsMaxFraction() {
        let est = calc.estimate(weightKg: 120, heightCm: 185, ageYears: 30, sex: .male,
                                activity: .veryActive, goal: .loseFat, pace: .steady, activeEnergyKcal: nil)
        let deficit = est.maintenance - est.targetRange.center
        XCTAssertLessThanOrEqual(Double(deficit), Double(est.maintenance) * NutritionCalculator.maxDeficitFraction + 1)
    }
}

final class PortionAndRecipeTests: XCTestCase {

    func testScaledPortion() {
        let per100 = NutritionFacts(caloriesKcal: 200, proteinG: 10, carbG: 20, fatG: 5, fiberG: 2)
        let scaled = per100.scaled(toGrams: 250)
        XCTAssertEqual(scaled.caloriesKcal, 500, accuracy: 0.001)
        XCTAssertEqual(scaled.proteinG, 25, accuracy: 0.001)
    }

    @MainActor
    func testRecipeTotalsAndPerServing() {
        let a = RecipeIngredient(name: "Riz", grams: 200, facts: NutritionFacts(caloriesKcal: 120))
        let b = RecipeIngredient(name: "Poulet", grams: 150, facts: NutritionFacts(caloriesKcal: 110, proteinG: 23))
        let recipe = Recipe(name: "Bowl", servings: 2, ingredients: [a, b])
        // 200g*1.2 + 150g*1.1 = 240 + 165 = 405 kcal total
        XCTAssertEqual(recipe.totalFacts.caloriesKcal, 405, accuracy: 0.5)
        XCTAssertEqual(recipe.perServingFacts.caloriesKcal, 202.5, accuracy: 0.5)
    }
}

final class WeightTrendTests: XCTestCase {

    let trend = WeightTrend()

    private func makePoints(_ kgs: [Double]) -> [WeightPoint] {
        let cal = Calendar.current
        let start = cal.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        return kgs.enumerated().map { i, kg in
            WeightPoint(date: cal.date(byAdding: .day, value: i, to: start)!, kg: kg)
        }
    }

    func testMovingAverageSmoothsNoise() {
        let pts = makePoints([80, 81, 79, 80, 81, 79, 80])
        let smoothed = trend.movingAverage(pts, windowDays: 7)
        XCTAssertEqual(smoothed.count, pts.count)
        // La dernière valeur lissée est proche de la moyenne (~80).
        XCTAssertEqual(smoothed.last!.kg, 80, accuracy: 0.5)
    }

    func testSlopeDetectsDownwardTrend() {
        let pts = makePoints([82, 81.8, 81.6, 81.4, 81.2, 81.0, 80.8])
        let slope = trend.slopeKgPerWeek(pts)
        XCTAssertLessThan(slope, 0)          // tendance à la baisse
        XCTAssertEqual(slope, -1.4, accuracy: 0.2)
    }
}

final class RecalibratorTests: XCTestCase {

    let recal = MaintenanceRecalibrator()

    func testNotEnoughData_NoChange() {
        let s = recal.suggest(.init(avgDailyIntakeKcal: 2000, weightTrendSlopeKgPerWeek: -0.3,
                                    currentMaintenanceEstimate: 2400, daysOfData: 10))
        XCTAssertFalse(s.hasEnoughData)
        XCTAssertEqual(s.deltaFromCurrent, 0)
    }

    func testAdjustmentIsCappedAndRequiresConfirmation() {
        // Perte réelle importante alors qu'on mange 2000 : maintien empirique très supérieur.
        let s = recal.suggest(.init(avgDailyIntakeKcal: 2000, weightTrendSlopeKgPerWeek: -1.0,
                                    currentMaintenanceEstimate: 2100, daysOfData: 21))
        XCTAssertTrue(s.hasEnoughData)
        XCTAssertTrue(s.requiresUserConfirmation)
        XCTAssertLessThanOrEqual(abs(s.deltaFromCurrent), Int(MaintenanceRecalibrator.maxAdjustment))
    }
}

final class WorkoutPlannerTests: XCTestCase {

    let planner = WorkoutPlanner()
    let library = ExerciseLibrary.all

    func testGeneratesSevenDays() {
        let plan = planner.generateWeeklyPlan(goals: [.generalFitness], level: .beginner,
                                              setting: .homeNoEquipment, daysPerWeek: 3,
                                              sessionMinutes: 45, library: library)
        XCTAssertEqual(plan.days.count, 7)
    }

    func testTrainingDaysMatchRequestedCount() {
        let plan = planner.generateWeeklyPlan(goals: [.chest], level: .intermediate,
                                              setting: .gym, daysPerWeek: 4,
                                              sessionMinutes: 60, library: library)
        let trainingDays = plan.days.filter { !$0.isRestDay }.count
        XCTAssertEqual(trainingDays, 4)
    }

    func testRecoveryDaysArePresent() {
        let plan = planner.generateWeeklyPlan(goals: [.chest], level: .beginner,
                                              setting: .homeNoEquipment, daysPerWeek: 3,
                                              sessionMinutes: 45, library: library)
        XCTAssertGreaterThan(plan.days.filter { $0.isRestDay }.count, 0)
    }

    func testChestGoalStillIncludesBackForBalance() {
        // Même avec un objectif pectoraux, le programme reste équilibré (présence de tirage/dos).
        let plan = planner.generateWeeklyPlan(goals: [.chest], level: .beginner,
                                              setting: .gym, daysPerWeek: 3,
                                              sessionMinutes: 60, library: library)
        let allExerciseIDs = plan.days.flatMap { $0.exercises.map(\.exerciseID) }
        let backExercises = Set(library.filter { $0.primaryMuscles.contains(.back) }.map(\.id))
        XCTAssertTrue(allExerciseIDs.contains { backExercises.contains($0) },
                      "Le programme devrait inclure du travail de dos pour l'équilibre.")
    }

    func testEverySessionHasWarmupAndCooldown() {
        let plan = planner.generateWeeklyPlan(goals: [.generalFitness], level: .beginner,
                                              setting: .homeNoEquipment, daysPerWeek: 2,
                                              sessionMinutes: 45, library: library)
        for day in plan.days where !day.isRestDay {
            XCTAssertTrue(day.exercises.contains { $0.block == .warmup }, "Échauffement manquant.")
            XCTAssertTrue(day.exercises.contains { $0.block == .cooldown }, "Retour au calme manquant.")
        }
    }
}

final class WeeklyReviewTests: XCTestCase {

    let review = WeeklyReview()

    func testNotEnoughData() {
        let r = review.evaluate(.init(daysWithMealData: 2, avgCaloriesKcal: nil, weightSlopeKgPerWeek: nil,
                                      waistDeltaCm: nil, plannedSessions: 3, completedSessions: 1, avgSteps: nil))
        XCTAssertEqual(r.verdict, .notEnoughData)
    }

    func testTooFastLoss() {
        let r = review.evaluate(.init(daysWithMealData: 6, avgCaloriesKcal: 1500, weightSlopeKgPerWeek: -1.2,
                                      waistDeltaCm: -0.5, plannedSessions: 3, completedSessions: 3, avgSteps: 8000))
        XCTAssertEqual(r.verdict, .possiblyTooFast)
    }
}

final class DataExportTests: XCTestCase {

    let export = DataExportService()

    @MainActor
    func testWeightCSVHeaderAndRows() {
        let entries = [WeightEntry(date: Date(timeIntervalSince1970: 0), kg: 80.5)]
        let csv = export.weightCSV(entries)
        XCTAssertTrue(csv.hasPrefix("date,kg,source"))
        XCTAssertTrue(csv.contains("80.5"))
    }

    @MainActor
    func testMealsCSVEscapesCommas() {
        let entry = MealEntry(mealType: .lunch, productName: "Riz, poulet", quantity: 200, grams: 200,
                              facts: NutritionFacts(caloriesKcal: 300))
        let csv = export.mealsCSV([entry])
        XCTAssertTrue(csv.contains("\"Riz, poulet\""), "Le champ contenant une virgule doit être entre guillemets.")
    }
}
