import Foundation

/// Type de repas.
public enum MealType: String, Codable, CaseIterable, Sendable, Identifiable {
    case breakfast, lunch, dinner, snack
    public var id: String { rawValue }
}

/// Unité de mesure d'une portion.
public enum ServingUnit: String, Codable, CaseIterable, Sendable {
    case gram, milliliter, piece, portion
}

/// Catégorie de recommandation d'un aliment (jamais « bon » / « mauvais »).
public enum FoodCategory: String, Codable, CaseIterable, Sendable {
    case preferOften      // à privilégier régulièrement
    case normal           // à consommer normalement
    case limit            // à limiter selon les quantités
    case treat            // aliment plaisir, à intégrer raisonnablement
}

/// Source d'information d'un produit.
public enum ProductSource: String, Codable, Sendable {
    case openFoodFacts
    case manual
    case userCreated
}

/// Système d'unités préféré (métrique par défaut).
public enum UnitSystem: String, Codable, CaseIterable, Sendable {
    case metric, imperial
}

/// Langue de l'application.
public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case system, french, polish
    public var localeIdentifier: String? {
        switch self {
        case .system: return nil
        case .french: return "fr"
        case .polish: return "pl"
        }
    }
}

/// Drapeaux de sécurité santé. Leur présence bloque la génération automatique
/// d'un déficit calorique et déclenche un parcours prudent.
public enum HealthSafetyFlag: String, Codable, CaseIterable, Sendable {
    case under18
    case pregnantOrBreastfeeding
    case eatingDisorderHistory
    case chronicIllness
    case weightAffectingMedication
    case veryLowWeight
    case recentUnintendedWeightLoss
    case injuryOrPain
    case heartCondition
    case medicalExerciseContraindication

    public var requiresProfessionalAdvice: Bool { true }
}
