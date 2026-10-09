import Foundation

/// Un exercice de la bibliothèque de référence.
/// C'est de la **donnée de référence statique** (pas de la donnée utilisateur),
/// donc un simple struct Codable — il n'est pas persisté dans SwiftData.
public struct Exercise: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let primaryMuscles: [MuscleGroup]
    public let secondaryMuscles: [MuscleGroup]
    public let requiredEquipment: [String]
    public let allowedSettings: [TrainingSetting]
    public let level: TrainingLevel
    public let instructions: [String]      // consignes d'exécution
    public let commonMistakes: [String]    // erreurs fréquentes
    public let easierVariant: String?      // variante plus facile
    public let harderVariant: String?      // variante plus difficile
    public let warning: String?            // avertissement éventuel
    public let sfSymbol: String            // illustration locale (SF Symbol)

    public init(id: String,
                name: String,
                primaryMuscles: [MuscleGroup],
                secondaryMuscles: [MuscleGroup] = [],
                requiredEquipment: [String] = [],
                allowedSettings: [TrainingSetting],
                level: TrainingLevel,
                instructions: [String] = [],
                commonMistakes: [String] = [],
                easierVariant: String? = nil,
                harderVariant: String? = nil,
                warning: String? = nil,
                sfSymbol: String = "figure.strengthtraining.traditional") {
        self.id = id
        self.name = name
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.requiredEquipment = requiredEquipment
        self.allowedSettings = allowedSettings
        self.level = level
        self.instructions = instructions
        self.commonMistakes = commonMistakes
        self.easierVariant = easierVariant
        self.harderVariant = harderVariant
        self.warning = warning
        self.sfSymbol = sfSymbol
    }

    /// Score numérique utilisé pour ordonner les candidats dans le planificateur.
    public var difficultyScore: Int { level.rawValueOrder }
}
