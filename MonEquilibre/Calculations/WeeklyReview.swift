import Foundation

/// Entrées pour le bilan hebdomadaire.
public struct WeeklyReviewInput: Sendable {
    public let daysWithMealData: Int
    public let avgCaloriesKcal: Double?
    public let weightSlopeKgPerWeek: Double?
    public let waistDeltaCm: Double?
    public let plannedSessions: Int
    public let completedSessions: Int
    public let avgSteps: Int?

    public init(daysWithMealData: Int, avgCaloriesKcal: Double?, weightSlopeKgPerWeek: Double?,
                waistDeltaCm: Double?, plannedSessions: Int, completedSessions: Int, avgSteps: Int?) {
        self.daysWithMealData = daysWithMealData
        self.avgCaloriesKcal = avgCaloriesKcal
        self.weightSlopeKgPerWeek = weightSlopeKgPerWeek
        self.waistDeltaCm = waistDeltaCm
        self.plannedSessions = plannedSessions
        self.completedSessions = completedSessions
        self.avgSteps = avgSteps
    }
}

/// Interprétation prudente de la semaine (jamais un diagnostic médical).
public enum WeeklyTrendVerdict: String, Sendable {
    case notEnoughData          // manque de données
    case likelyMaintaining      // maintien probable
    case likelyProgressing      // progression probable
    case possiblyTooFast        // baisse trop rapide possible
    case possibleOvertraining   // fatigue / entraînement excessif possible
}

public struct WeeklyReviewResult: Sendable {
    public let verdict: WeeklyTrendVerdict
    public let positives: [String]
    public let singlePriority: String   // UNE seule priorité simple pour la semaine
    public let headline: String
}

/// Générateur du bilan hebdomadaire.
public struct WeeklyReview {

    public init() {}

    public func evaluate(_ input: WeeklyReviewInput) -> WeeklyReviewResult {
        // Manque de données : on ne conclut pas.
        if input.daysWithMealData < 4 || input.weightSlopeKgPerWeek == nil {
            return WeeklyReviewResult(
                verdict: .notEnoughData,
                positives: positives(input),
                singlePriority: "Enregistre tes repas 4 à 5 jours cette semaine : ça suffit pour voir une tendance.",
                headline: "Encore un peu de données et le bilan sera plus fiable."
            )
        }

        let slope = input.weightSlopeKgPerWeek ?? 0
        var verdict: WeeklyTrendVerdict
        var priority: String

        if slope <= -1.0 {
            verdict = .possiblyTooFast
            priority = "La baisse est rapide. Remonte un peu les calories cette semaine pour préserver ta santé et tes muscles."
        } else if slope < -0.15 {
            verdict = .likelyProgressing
            priority = "Continue comme ça : garde la régularité des repas et des séances."
        } else if slope <= 0.15 {
            verdict = .likelyMaintaining
            priority = "Tu es proche du maintien. Un léger ajustement des portions peut relancer la tendance si tu le souhaites."
        } else {
            verdict = .likelyMaintaining
            priority = "Le poids remonte légèrement. Observe la moyenne sur 2–3 semaines avant de changer quoi que ce soit."
        }

        // Signal de fatigue / surentraînement possible.
        if input.completedSessions > input.plannedSessions && input.plannedSessions > 0 {
            verdict = .possibleOvertraining
            priority = "Tu as fait plus de séances que prévu. Prévois de la récupération pour éviter la fatigue."
        }

        return WeeklyReviewResult(
            verdict: verdict,
            positives: positives(input),
            singlePriority: priority,
            headline: headline(for: verdict)
        )
    }

    private func positives(_ input: WeeklyReviewInput) -> [String] {
        var p: [String] = []
        if input.completedSessions > 0 { p.append("\(input.completedSessions) séance(s) réalisée(s).") }
        if input.daysWithMealData >= 4 { p.append("Suivi des repas régulier (\(input.daysWithMealData) jours).") }
        if let steps = input.avgSteps, steps >= 6000 { p.append("Bon niveau d'activité (\(steps) pas/jour en moyenne).") }
        if let waist = input.waistDeltaCm, waist < 0 { p.append("Tour de taille en légère baisse.") }
        if p.isEmpty { p.append("Tu es là et tu suis ta progression : c'est déjà l'essentiel.") }
        return p
    }

    private func headline(for verdict: WeeklyTrendVerdict) -> String {
        switch verdict {
        case .notEnoughData:        return "Bilan indicatif : encore un peu de données à réunir."
        case .likelyMaintaining:    return "Semaine plutôt stable."
        case .likelyProgressing:    return "Progression probable, sur la bonne voie."
        case .possiblyTooFast:      return "Baisse rapide : mieux vaut ralentir."
        case .possibleOvertraining: return "Pense à récupérer."
        }
    }
}
