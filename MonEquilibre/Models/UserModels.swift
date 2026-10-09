import Foundation
import SwiftData

/// Profil de l'utilisateur. Les données de santé sont facultatives autant que possible.
@Model
public final class UserProfile {
    @Attribute(.unique) public var id: UUID
    public var displayName: String
    public var birthDate: Date?
    public var heightCm: Double?
    public var calculationSexRaw: String   // CalculationSex
    public var activityLevelRaw: String    // ActivityLevel
    public var occupation: String?
    public var trainingsPerWeek: Int
    public var averageSleepHours: Double?

    // Préférences / restrictions alimentaires (facultatives).
    public var dietaryPreferences: [String]
    public var excludedFoods: [String]
    public var allergies: [String]

    // Matériel sportif disponible et limitations physiques.
    public var availableEquipment: [String]
    public var physicalLimitations: [String]

    // Drapeaux de sécurité santé (bloquent les objectifs automatiques).
    public var safetyFlagsRaw: [String]    // HealthSafetyFlag

    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(),
                displayName: String = "",
                birthDate: Date? = nil,
                heightCm: Double? = nil,
                calculationSex: CalculationSex = .male,
                activityLevel: ActivityLevel = .light,
                occupation: String? = nil,
                trainingsPerWeek: Int = 3,
                averageSleepHours: Double? = nil,
                dietaryPreferences: [String] = [],
                excludedFoods: [String] = [],
                allergies: [String] = [],
                availableEquipment: [String] = [],
                physicalLimitations: [String] = [],
                safetyFlags: [HealthSafetyFlag] = []) {
        self.id = id
        self.displayName = displayName
        self.birthDate = birthDate
        self.heightCm = heightCm
        self.calculationSexRaw = calculationSex.rawValue
        self.activityLevelRaw = activityLevel.rawValue
        self.occupation = occupation
        self.trainingsPerWeek = trainingsPerWeek
        self.averageSleepHours = averageSleepHours
        self.dietaryPreferences = dietaryPreferences
        self.excludedFoods = excludedFoods
        self.allergies = allergies
        self.availableEquipment = availableEquipment
        self.physicalLimitations = physicalLimitations
        self.safetyFlagsRaw = safetyFlags.map(\.rawValue)
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Accès typés (les enums sont stockés en brut pour la robustesse des migrations).
    public var calculationSex: CalculationSex {
        get { CalculationSex(rawValue: calculationSexRaw) ?? .male }
        set { calculationSexRaw = newValue.rawValue }
    }
    public var activityLevel: ActivityLevel {
        get { ActivityLevel(rawValue: activityLevelRaw) ?? .light }
        set { activityLevelRaw = newValue.rawValue }
    }
    public var safetyFlags: [HealthSafetyFlag] {
        get { safetyFlagsRaw.compactMap(HealthSafetyFlag.init(rawValue:)) }
        set { safetyFlagsRaw = newValue.map(\.rawValue) }
    }

    /// Âge en années à partir de la date de naissance.
    public var ageYears: Int? {
        guard let birthDate else { return nil }
        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }

    /// Vrai si un objectif calorique automatique ne doit pas être généré.
    public var blocksAutomaticDeficit: Bool { !safetyFlags.isEmpty }
}

/// Objectif de l'utilisateur.
@Model
public final class UserGoal {
    @Attribute(.unique) public var id: UUID
    public var primaryGoalRaw: String   // PrimaryGoal
    public var paceRaw: String          // PaceLevel
    public var targetWeightKg: Double?
    public var acknowledgedEstimateDisclaimer: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(),
                primaryGoal: PrimaryGoal = .maintain,
                pace: PaceLevel = .gentle,
                targetWeightKg: Double? = nil,
                acknowledgedEstimateDisclaimer: Bool = false) {
        self.id = id
        self.primaryGoalRaw = primaryGoal.rawValue
        self.paceRaw = pace.rawValue
        self.targetWeightKg = targetWeightKg
        self.acknowledgedEstimateDisclaimer = acknowledgedEstimateDisclaimer
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    public var primaryGoal: PrimaryGoal {
        get { PrimaryGoal(rawValue: primaryGoalRaw) ?? .maintain }
        set { primaryGoalRaw = newValue.rawValue }
    }
    public var pace: PaceLevel {
        get { PaceLevel(rawValue: paceRaw) ?? .gentle }
        set { paceRaw = newValue.rawValue }
    }
}

/// Objectif nutritionnel journalier (calculé, puis éventuellement confirmé par l'utilisateur).
@Model
public final class DailyNutritionTarget {
    @Attribute(.unique) public var id: UUID
    public var date: Date               // jour concerné (début de journée)
    public var caloriesLow: Int
    public var caloriesCenter: Int
    public var caloriesHigh: Int
    public var proteinGrams: Int
    public var carbGrams: Int
    public var fatGrams: Int
    public var fiberGramsMin: Int
    public var waterTargetMl: Int
    public var isConfirmedByUser: Bool  // l'utilisateur voit et confirme tout changement
    public var createdAt: Date

    public init(id: UUID = UUID(),
                date: Date,
                range: CalorieRange,
                proteinGrams: Int,
                carbGrams: Int,
                fatGrams: Int,
                fiberGramsMin: Int,
                waterTargetMl: Int = 2000,
                isConfirmedByUser: Bool = false) {
        self.id = id
        self.date = date
        self.caloriesLow = range.low
        self.caloriesCenter = range.center
        self.caloriesHigh = range.high
        self.proteinGrams = proteinGrams
        self.carbGrams = carbGrams
        self.fatGrams = fatGrams
        self.fiberGramsMin = fiberGramsMin
        self.waterTargetMl = waterTargetMl
        self.isConfirmedByUser = isConfirmedByUser
        self.createdAt = Date()
    }

    public var range: CalorieRange {
        CalorieRange(low: caloriesLow, center: caloriesCenter, high: caloriesHigh)
    }
}

/// Réglages de l'application.
@Model
public final class AppSettings {
    @Attribute(.unique) public var id: UUID
    public var unitSystemRaw: String    // UnitSystem
    public var languageRaw: String      // AppLanguage
    public var healthKitEnabled: Bool

    // Notifications individuelles (activables une par une).
    public var notifyLogMeals: Bool
    public var notifyDrinkWater: Bool
    public var notifyWeighIn: Bool
    public var notifyWorkout: Bool
    public var notifyWeeklyPlan: Bool
    public var notifyActiveBreak: Bool
    public var notifyWeeklyReview: Bool

    public var acknowledgedMedicalDisclaimer: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(),
                unitSystem: UnitSystem = .metric,
                language: AppLanguage = .system,
                healthKitEnabled: Bool = false) {
        self.id = id
        self.unitSystemRaw = unitSystem.rawValue
        self.languageRaw = language.rawValue
        self.healthKitEnabled = healthKitEnabled
        self.notifyLogMeals = false
        self.notifyDrinkWater = false
        self.notifyWeighIn = false
        self.notifyWorkout = false
        self.notifyWeeklyPlan = false
        self.notifyActiveBreak = false
        self.notifyWeeklyReview = false
        self.acknowledgedMedicalDisclaimer = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    public var unitSystem: UnitSystem {
        get { UnitSystem(rawValue: unitSystemRaw) ?? .metric }
        set { unitSystemRaw = newValue.rawValue }
    }
    public var language: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .system }
        set { languageRaw = newValue.rawValue }
    }
}
