import Foundation
import SwiftData

/// Un plan d'entraînement enregistré (résultat du planificateur, modifiable).
@Model
public final class WorkoutPlan {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var levelRaw: String            // TrainingLevel
    public var settingRaw: String          // TrainingSetting
    public var goalRaws: [String]          // [TrainingGoal]
    public var daysPerWeek: Int
    public var sessionMinutes: Int
    public var isActive: Bool
    @Relationship(deleteRule: .cascade) public var days: [WorkoutDay]
    public var notes: [String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(),
                name: String,
                level: TrainingLevel,
                setting: TrainingSetting,
                goals: [TrainingGoal],
                daysPerWeek: Int,
                sessionMinutes: Int,
                isActive: Bool = true,
                days: [WorkoutDay] = [],
                notes: [String] = []) {
        self.id = id
        self.name = name
        self.levelRaw = level.rawValue
        self.settingRaw = setting.rawValue
        self.goalRaws = goals.map(\.rawValue)
        self.daysPerWeek = daysPerWeek
        self.sessionMinutes = sessionMinutes
        self.isActive = isActive
        self.days = days
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    public var level: TrainingLevel { TrainingLevel(rawValue: levelRaw) ?? .beginner }
    public var setting: TrainingSetting { TrainingSetting(rawValue: settingRaw) ?? .homeNoEquipment }
    public var goals: [TrainingGoal] { goalRaws.compactMap(TrainingGoal.init(rawValue:)) }
}

/// Une journée du plan (position 0–6 dans la semaine).
@Model
public final class WorkoutDay {
    @Attribute(.unique) public var id: UUID
    public var weekdayIndex: Int           // 0 = lundi ... 6 = dimanche
    public var title: String
    public var isRestDay: Bool
    @Relationship(deleteRule: .cascade) public var plannedExercises: [PlannedExercise]
    public var createdAt: Date

    public init(id: UUID = UUID(), weekdayIndex: Int, title: String, isRestDay: Bool = false,
                plannedExercises: [PlannedExercise] = []) {
        self.id = id
        self.weekdayIndex = weekdayIndex
        self.title = title
        self.isRestDay = isRestDay
        self.plannedExercises = plannedExercises
        self.createdAt = Date()
    }
}

/// Un exercice planifié dans une journée (référence l'ID de la bibliothèque).
@Model
public final class PlannedExercise {
    @Attribute(.unique) public var id: UUID
    public var exerciseID: String          // référence Exercise.id
    public var exerciseName: String        // dénormalisé pour l'affichage
    public var blockRaw: String            // BlockType
    public var sets: Int
    public var reps: String
    public var restSeconds: Int
    public var orderIndex: Int
    public var createdAt: Date

    public init(id: UUID = UUID(), exerciseID: String, exerciseName: String, block: BlockType,
                sets: Int, reps: String, restSeconds: Int, orderIndex: Int) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.blockRaw = block.rawValue
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.orderIndex = orderIndex
        self.createdAt = Date()
    }

    public var block: BlockType { BlockType(rawValue: blockRaw) ?? .main }
}

/// Une séance réellement réalisée.
@Model
public final class WorkoutSession {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var title: String
    public var perceivedDifficulty: Int    // 1–10 (RPE)
    public var painNote: String?           // possibilité de noter une douleur
    @Relationship(deleteRule: .cascade) public var completed: [CompletedExercise]
    public var estimatedActiveKcal: Double?
    public var createdAt: Date

    public init(id: UUID = UUID(), date: Date = Date(), title: String,
                perceivedDifficulty: Int = 5, painNote: String? = nil,
                completed: [CompletedExercise] = [], estimatedActiveKcal: Double? = nil) {
        self.id = id
        self.date = date
        self.title = title
        self.perceivedDifficulty = perceivedDifficulty
        self.painNote = painNote
        self.completed = completed
        self.estimatedActiveKcal = estimatedActiveKcal
        self.createdAt = Date()
    }
}

/// Un exercice réalisé (charges et répétitions effectivement faites).
@Model
public final class CompletedExercise {
    @Attribute(.unique) public var id: UUID
    public var exerciseID: String
    public var exerciseName: String
    public var setsDone: Int
    public var repsDone: [Int]             // répétitions par série
    public var weightsKg: [Double]         // charge par série (0 = poids du corps)
    public var createdAt: Date

    public init(id: UUID = UUID(), exerciseID: String, exerciseName: String,
                setsDone: Int, repsDone: [Int] = [], weightsKg: [Double] = []) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.setsDone = setsDone
        self.repsDone = repsDone
        self.weightsKg = weightsKg
        self.createdAt = Date()
    }
}
