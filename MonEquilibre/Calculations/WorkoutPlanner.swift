import Foundation

/// Objectifs d'entraînement sélectionnables.
public enum TrainingGoal: String, Codable, CaseIterable, Sendable {
    case loseFat, chest, back, posture, shoulders, arms, abs, legs, mobility, generalFitness
}

/// Niveau d'entraînement.
public enum TrainingLevel: String, Codable, CaseIterable, Sendable {
    case beginner, intermediate, advanced
}

/// Lieu / matériel.
public enum TrainingSetting: String, Codable, CaseIterable, Sendable {
    case homeNoEquipment      // maison sans matériel
    case homeMinimalEquipment // élastiques / haltères
    case gym                  // salle
}

/// Groupe musculaire (sert à la construction équilibrée des séances).
public enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case chest, back, shoulders, arms, legs, glutes, core, mobility, cardio, fullBody
}

/// Type de bloc dans une séance.
public enum BlockType: String, Codable, Sendable {
    case warmup, main, accessory, cooldown, mobility
}

/// Un exercice planifié (référence + prescription).
public struct PlannedExerciseSpec: Equatable, Sendable {
    public let exerciseID: String
    public let block: BlockType
    public let sets: Int
    public let reps: String      // "8–12", "30 s", etc.
    public let restSeconds: Int
    public init(exerciseID: String, block: BlockType, sets: Int, reps: String, restSeconds: Int) {
        self.exerciseID = exerciseID
        self.block = block
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
    }
}

/// Une journée d'entraînement générée.
public struct GeneratedWorkoutDay: Equatable, Sendable {
    public let title: String
    public let focus: [MuscleGroup]
    public let isRestDay: Bool
    public let exercises: [PlannedExerciseSpec]
}

/// Un plan hebdomadaire généré.
public struct GeneratedWeeklyPlan: Equatable, Sendable {
    public let days: [GeneratedWorkoutDay]  // 7 entrées (certaines = repos)
    public let level: TrainingLevel
    public let notes: [String]
}

public protocol WorkoutPlanning {
    func generateWeeklyPlan(goals: [TrainingGoal],
                            level: TrainingLevel,
                            setting: TrainingSetting,
                            daysPerWeek: Int,
                            sessionMinutes: Int,
                            library: [Exercise]) -> GeneratedWeeklyPlan
}

/// Générateur de programme hebdomadaire.
///
/// Principes appliqués :
/// - Même quand l'objectif principal est un muscle (pectoraux, dos…), la séance
///   reste **globale et équilibrée** pour éviter les déséquilibres et les blessures.
/// - Au moins un jour de récupération entre deux séances intenses du même groupe.
/// - Chaque séance = échauffement + principaux + complémentaires + retour au calme.
public struct WorkoutPlanner: WorkoutPlanning {

    public init() {}

    // Répétitions par niveau (hypertrophie/renforcement prudent).
    private func repsFor(_ level: TrainingLevel) -> (sets: Int, reps: String, rest: Int) {
        switch level {
        case .beginner:     return (2, "10–12", 75)
        case .intermediate: return (3, "8–12", 90)
        case .advanced:     return (4, "6–10", 120)
        }
    }

    /// Choisit un exercice de la bibliothèque pour un groupe et un contexte donnés.
    private func pick(_ group: MuscleGroup,
                      block: BlockType,
                      level: TrainingLevel,
                      setting: TrainingSetting,
                      library: [Exercise],
                      exclude: Set<String>) -> Exercise? {
        let candidates = library.filter { ex in
            ex.primaryMuscles.contains(group)
            && ex.allowedSettings.contains(setting)
            && ex.level.rawValueOrder <= level.rawValueOrder  // niveau égal ou plus simple
            && !exclude.contains(ex.id)
        }
        // Préférer l'exercice au niveau le plus proche demandé.
        return candidates.sorted { $0.difficultyScore < $1.difficultyScore }.last
            ?? library.first { $0.primaryMuscles.contains(group) && !exclude.contains($0.id) }
    }

    /// Construit une séance équilibrée autour de groupes cibles.
    private func buildSession(title: String,
                              targets: [MuscleGroup],
                              level: TrainingLevel,
                              setting: TrainingSetting,
                              sessionMinutes: Int,
                              library: [Exercise]) -> GeneratedWorkoutDay {
        let (sets, reps, rest) = repsFor(level)
        var used = Set<String>()
        var specs: [PlannedExerciseSpec] = []

        // 1. Échauffement (mobilité / cardio léger)
        if let warm = pick(.mobility, block: .warmup, level: .beginner, setting: setting, library: library, exclude: used)
            ?? pick(.cardio, block: .warmup, level: .beginner, setting: setting, library: library, exclude: used) {
            used.insert(warm.id)
            specs.append(PlannedExerciseSpec(exerciseID: warm.id, block: .warmup, sets: 1, reps: "5 min", restSeconds: 0))
        }

        // 2. Exercices principaux (groupes cibles)
        for g in targets {
            if let ex = pick(g, block: .main, level: level, setting: setting, library: library, exclude: used) {
                used.insert(ex.id)
                specs.append(PlannedExerciseSpec(exerciseID: ex.id, block: .main, sets: sets, reps: reps, restSeconds: rest))
            }
        }

        // 3. Complémentaires : on garantit un minimum d'équilibre (tirer + gainage).
        let balanceGroups: [MuscleGroup] = [.back, .core, .shoulders].filter { !targets.contains($0) }
        let accessoryBudget = max(1, (sessionMinutes / 15)) // plus la séance est longue, plus d'accessoires
        for g in balanceGroups.prefix(accessoryBudget) {
            if let ex = pick(g, block: .accessory, level: level, setting: setting, library: library, exclude: used) {
                used.insert(ex.id)
                specs.append(PlannedExerciseSpec(exerciseID: ex.id, block: .accessory, sets: max(2, sets - 1), reps: reps, restSeconds: 60))
            }
        }

        // 4. Retour au calme (mobilité)
        if let cool = pick(.mobility, block: .cooldown, level: .beginner, setting: setting, library: library, exclude: used) {
            specs.append(PlannedExerciseSpec(exerciseID: cool.id, block: .cooldown, sets: 1, reps: "3–5 min", restSeconds: 0))
        }

        return GeneratedWorkoutDay(title: title, focus: targets, isRestDay: false, exercises: specs)
    }

    private func restDay() -> GeneratedWorkoutDay {
        GeneratedWorkoutDay(title: "Récupération", focus: [.mobility], isRestDay: true, exercises: [])
    }

    public func generateWeeklyPlan(goals: [TrainingGoal],
                                   level: TrainingLevel,
                                   setting: TrainingSetting,
                                   daysPerWeek: Int,
                                   sessionMinutes: Int,
                                   library: [Exercise]) -> GeneratedWeeklyPlan {

        let clampedDays = max(1, min(6, daysPerWeek))
        var notes: [String] = [
            "Les exercices peuvent renforcer et développer certaines zones, mais la diminution de la graisse abdominale dépend surtout de la baisse générale de la masse grasse.",
            "Au moins un jour de récupération est prévu entre deux séances intenses du même groupe musculaire."
        ]

        // Détermine les blocs de séances selon le nombre de jours (haut / bas / complet).
        // On garde toujours un équilibre global.
        let upper: [MuscleGroup] = [.chest, .back, .shoulders, .arms]
        let lower: [MuscleGroup] = [.legs, .glutes, .core]
        let full: [MuscleGroup]  = [.chest, .back, .legs, .core]

        // Priorise les groupes issus des objectifs, sans jamais tout y consacrer.
        let goalMuscles = goals.flatMap { Self.muscles(for: $0) }
        func prioritized(_ base: [MuscleGroup]) -> [MuscleGroup] {
            // Place d'abord les groupes issus des objectifs, puis le reste, sans doublon.
            let boosted = goalMuscles.filter { base.contains($0) }
            var seen = Set<MuscleGroup>()
            var ordered: [MuscleGroup] = []
            for m in boosted + base where !seen.contains(m) {
                seen.insert(m); ordered.append(m)
            }
            return ordered
        }

        var sessions: [GeneratedWorkoutDay] = []
        switch clampedDays {
        case 1:
            sessions = [buildSession(title: "Séance complète", targets: prioritized(full), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library)]
        case 2:
            sessions = [
                buildSession(title: "Complet A", targets: prioritized(full), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library),
                buildSession(title: "Complet B", targets: prioritized([.back, .legs, .shoulders, .core]), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library)
            ]
        case 3:
            sessions = [
                buildSession(title: "Haut du corps", targets: prioritized(upper), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library),
                buildSession(title: "Bas du corps", targets: prioritized(lower), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library),
                buildSession(title: "Complet", targets: prioritized(full), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library)
            ]
        case 4:
            sessions = [
                buildSession(title: "Haut du corps", targets: prioritized(upper), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library),
                buildSession(title: "Bas du corps", targets: prioritized(lower), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library),
                buildSession(title: "Haut du corps", targets: prioritized([.back, .chest, .shoulders]), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library),
                buildSession(title: "Bas du corps", targets: prioritized([.legs, .glutes, .core]), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library)
            ]
        default: // 5 ou 6
            sessions = [
                buildSession(title: "Poussée (pecs/épaules/bras)", targets: prioritized([.chest, .shoulders, .arms]), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library),
                buildSession(title: "Tirage (dos/posture/bras)", targets: prioritized([.back, .shoulders, .arms]), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library),
                buildSession(title: "Bas du corps", targets: prioritized(lower), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library),
                buildSession(title: "Haut du corps", targets: prioritized(upper), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library),
                buildSession(title: "Complet + gainage", targets: prioritized([.legs, .core, .back]), level: level, setting: setting, sessionMinutes: sessionMinutes, library: library)
            ]
            if clampedDays == 5 { sessions = Array(sessions.prefix(5)) }
        }

        // Place les séances sur 7 jours en intercalant des jours de récupération.
        let week = Self.distribute(sessions: sessions, restDay: restDay(), overDays: 7)
        if clampedDays >= 5 {
            notes.append("Ce volume élevé demande un sommeil et une récupération suffisants. Prévois une semaine plus légère si la fatigue s'accumule.")
        }

        return GeneratedWeeklyPlan(days: week, level: level, notes: notes)
    }

    // MARK: - Utilitaires

    /// Groupes musculaires associés à un objectif.
    static func muscles(for goal: TrainingGoal) -> [MuscleGroup] {
        switch goal {
        case .loseFat:        return [.fullBody, .cardio]
        case .chest:          return [.chest]
        case .back, .posture: return [.back, .shoulders]
        case .shoulders:      return [.shoulders]
        case .arms:           return [.arms]
        case .abs:            return [.core]
        case .legs:           return [.legs, .glutes]
        case .mobility:       return [.mobility]
        case .generalFitness: return [.fullBody]
        }
    }

    /// Répartit N séances sur `overDays` jours en intercalant la récupération.
    static func distribute(sessions: [GeneratedWorkoutDay],
                           restDay: GeneratedWorkoutDay,
                           overDays: Int) -> [GeneratedWorkoutDay] {
        guard !sessions.isEmpty else { return Array(repeating: restDay, count: overDays) }
        var week: [GeneratedWorkoutDay] = []
        let n = sessions.count
        // Espacement idéal entre séances.
        let gap = max(1, overDays / n)
        var idx = 0
        var placed = 0
        while week.count < overDays {
            if placed < n && (week.count % gap == 0 || overDays - week.count <= n - placed) {
                week.append(sessions[idx])
                idx += 1
                placed += 1
            } else {
                week.append(restDay)
            }
        }
        return Array(week.prefix(overDays))
    }
}

// Permet de comparer les niveaux (beginner < intermediate < advanced).
extension TrainingLevel {
    var rawValueOrder: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 1
        case .advanced: return 2
        }
    }
}
