import Foundation

/// Sexe physiologique utilisé **uniquement** pour l'estimation du métabolisme.
/// Ce champ n'a pas d'autre usage dans l'application.
public enum CalculationSex: String, Codable, CaseIterable, Sendable {
    case male
    case female
}

/// Niveau d'activité quotidienne (hors entraînements structurés).
public enum ActivityLevel: String, Codable, CaseIterable, Sendable {
    case sedentary     // travail assis, peu de marche
    case light         // marche légère quotidienne
    case moderate      // activité régulière modérée
    case active        // métier physique ou marche importante
    case veryActive    // métier très physique

    /// Facteur multiplicatif appliqué au métabolisme de base (valeurs usuelles documentées).
    public var factor: Double {
        switch self {
        case .sedentary:  return 1.20
        case .light:      return 1.375
        case .moderate:   return 1.55
        case .active:     return 1.725
        case .veryActive: return 1.90
        }
    }
}

/// Objectif principal choisi par l'utilisateur.
public enum PrimaryGoal: String, Codable, CaseIterable, Sendable {
    case loseFat        // perte de masse grasse
    case maintain       // maintien
    case recomposition  // maintien du poids, léger déficit
}

/// Rythme de perte souhaité. Volontairement prudent.
public enum PaceLevel: String, Codable, CaseIterable, Sendable {
    case gentle    // ~0,25 kg / semaine
    case moderate  // ~0,45 kg / semaine
    case steady    // ~0,60 kg / semaine (plafond raisonnable proposé)

    /// Déficit hebdomadaire visé en kcal (1 kg de masse grasse ≈ 7700 kcal).
    var weeklyDeficitKcal: Double {
        switch self {
        case .gentle:   return 0.25 * 7700
        case .moderate: return 0.45 * 7700
        case .steady:   return 0.60 * 7700
        }
    }
}

/// Une **plage** de calories (l'app ne présente jamais un chiffre comme parfaitement exact).
public struct CalorieRange: Equatable, Sendable {
    public let low: Int
    public let center: Int
    public let high: Int

    public init(low: Int, center: Int, high: Int) {
        self.low = low
        self.center = center
        self.high = high
    }
}

/// Résultat complet d'une estimation.
public struct NutritionEstimate: Equatable, Sendable {
    public let bmr: Int                 // métabolisme de base estimé
    public let maintenance: Int         // dépense totale estimée (maintien)
    public let targetRange: CalorieRange
    public let proteinGrams: Int
    public let carbGrams: Int
    public let fatGrams: Int
    public let fiberGramsMin: Int
    public let isSafetyLimited: Bool    // true si un plancher de sécurité a été appliqué
}

/// Protocole permettant l'injection de dépendances et le test.
public protocol NutritionCalculating {
    func basalMetabolicRate(weightKg: Double, heightCm: Double, ageYears: Int, sex: CalculationSex) -> Double
    func maintenanceCalories(bmr: Double, activity: ActivityLevel, activeEnergyKcal: Double?) -> Double
    func estimate(weightKg: Double,
                  heightCm: Double,
                  ageYears: Int,
                  sex: CalculationSex,
                  activity: ActivityLevel,
                  goal: PrimaryGoal,
                  pace: PaceLevel,
                  activeEnergyKcal: Double?) -> NutritionEstimate
}

/// Moteur de calcul nutritionnel. Structure pure, sans effet de bord, entièrement testable.
public struct NutritionCalculator: NutritionCalculating {

    /// Plancher calorique de sécurité. En dessous, on ne descend jamais automatiquement.
    /// Valeurs prudentes et volontairement conservatrices.
    public struct SafetyFloor {
        public static let male = 1500.0
        public static let female = 1200.0
    }

    /// Déficit maximal autorisé en proportion du maintien (jamais de régime agressif).
    public static let maxDeficitFraction = 0.20

    public init() {}

    // MARK: - Métabolisme de base (Mifflin-St Jeor, adulte)

    public func basalMetabolicRate(weightKg: Double,
                                   heightCm: Double,
                                   ageYears: Int,
                                   sex: CalculationSex) -> Double {
        let base = 10.0 * weightKg + 6.25 * heightCm - 5.0 * Double(ageYears)
        switch sex {
        case .male:   return base + 5.0
        case .female: return base - 161.0
        }
    }

    // MARK: - Dépense totale (maintien)

    /// Si HealthKit fournit une énergie active moyenne fiable, on l'utilise en
    /// complément du métabolisme de base plutôt que le seul facteur d'activité,
    /// puis on fait une moyenne pondérée des deux estimations pour rester prudent.
    public func maintenanceCalories(bmr: Double,
                                    activity: ActivityLevel,
                                    activeEnergyKcal: Double?) -> Double {
        let factorEstimate = bmr * activity.factor
        guard let active = activeEnergyKcal, active > 0 else {
            return factorEstimate
        }
        // Estimation basée sur les données réelles : BMR + énergie active mesurée
        // (on ajoute ~10 % de thermogenèse alimentaire).
        let measuredEstimate = (bmr + active) * 1.10
        // Moyenne des deux approches : évite de sur-réagir à une seule source.
        return (factorEstimate + measuredEstimate) / 2.0
    }

    // MARK: - Estimation complète

    public func estimate(weightKg: Double,
                         heightCm: Double,
                         ageYears: Int,
                         sex: CalculationSex,
                         activity: ActivityLevel,
                         goal: PrimaryGoal,
                         pace: PaceLevel,
                         activeEnergyKcal: Double?) -> NutritionEstimate {

        let bmr = basalMetabolicRate(weightKg: weightKg, heightCm: heightCm, ageYears: ageYears, sex: sex)
        let maintenance = maintenanceCalories(bmr: bmr, activity: activity, activeEnergyKcal: activeEnergyKcal)

        var isLimited = false
        var target: Double

        switch goal {
        case .maintain:
            target = maintenance
        case .loseFat, .recomposition:
            let dailyDeficit = pace.weeklyDeficitKcal / 7.0
            let cappedDeficit = min(dailyDeficit, maintenance * Self.maxDeficitFraction)
            target = maintenance - cappedDeficit
        }

        // Plancher de sécurité : ne jamais descendre sous le seuil, ni sous le métabolisme de base.
        let floor = max(sex == .male ? SafetyFloor.male : SafetyFloor.female, bmr * 0.95)
        if target < floor {
            target = floor
            isLimited = true
        }

        // Répartition des macronutriments (prudente, adaptée à la préservation musculaire).
        // Protéines : 1,8 g/kg de poids. Lipides : 25 % des calories. Glucides : le reste.
        let protein = 1.8 * weightKg
        let proteinKcal = protein * 4.0
        let fatKcal = target * 0.25
        let fat = fatKcal / 9.0
        let carbKcal = max(0, target - proteinKcal - fatKcal)
        let carb = carbKcal / 4.0
        let fiberMin = max(25.0, target / 1000.0 * 14.0) // ~14 g / 1000 kcal

        let center = Int(target.rounded())
        let range = CalorieRange(low: center - 100, center: center, high: center + 100)

        return NutritionEstimate(
            bmr: Int(bmr.rounded()),
            maintenance: Int(maintenance.rounded()),
            targetRange: range,
            proteinGrams: Int(protein.rounded()),
            carbGrams: Int(carb.rounded()),
            fatGrams: Int(fat.rounded()),
            fiberGramsMin: Int(fiberMin.rounded()),
            isSafetyLimited: isLimited
        )
    }
}
