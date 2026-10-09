import Foundation

/// Un point de pesée simplifié pour les calculs (découplé du modèle SwiftData).
public struct WeightPoint: Equatable, Sendable {
    public let date: Date
    public let kg: Double
    public init(date: Date, kg: Double) {
        self.date = date
        self.kg = kg
    }
}

/// Résultat d'une analyse de tendance de poids.
public struct WeightTrendResult: Equatable, Sendable {
    public let smoothed: [WeightPoint]   // moyenne mobile
    public let slopeKgPerWeek: Double    // tendance (régression linéaire)
    public let latestSmoothedKg: Double?
}

/// Analyse de tendance du poids.
/// Une seule pesée ne dit rien : on lisse pour réduire l'effet de l'eau, du sel,
/// des horaires de repas et de la digestion.
public struct WeightTrend {

    public init() {}

    /// Moyenne mobile trailing sur une fenêtre en jours (par défaut 7).
    public func movingAverage(_ points: [WeightPoint], windowDays: Int = 7) -> [WeightPoint] {
        guard !points.isEmpty else { return [] }
        let sorted = points.sorted { $0.date < $1.date }
        let cal = Calendar.current
        var result: [WeightPoint] = []

        for (i, p) in sorted.enumerated() {
            guard let windowStart = cal.date(byAdding: .day, value: -(windowDays - 1), to: p.date) else {
                result.append(p); continue
            }
            // Moyenne de toutes les pesées dans la fenêtre [windowStart ... p.date].
            var sum = 0.0
            var count = 0
            var j = i
            while j >= 0 && sorted[j].date >= windowStart {
                sum += sorted[j].kg
                count += 1
                j -= 1
            }
            let avg = count > 0 ? sum / Double(count) : p.kg
            result.append(WeightPoint(date: p.date, kg: avg))
        }
        return result
    }

    /// Pente de la tendance en kg/semaine, via une régression linéaire simple (moindres carrés).
    public func slopeKgPerWeek(_ points: [WeightPoint]) -> Double {
        guard points.count >= 2 else { return 0 }
        let sorted = points.sorted { $0.date < $1.date }
        guard let t0 = sorted.first?.date else { return 0 }

        // x en jours depuis le premier point.
        let xs = sorted.map { $0.date.timeIntervalSince(t0) / 86400.0 }
        let ys = sorted.map { $0.kg }
        let n = Double(xs.count)
        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumX2 = xs.map { $0 * $0 }.reduce(0, +)
        let denom = n * sumX2 - sumX * sumX
        guard denom != 0 else { return 0 }
        let slopePerDay = (n * sumXY - sumX * sumY) / denom
        return slopePerDay * 7.0
    }

    public func analyze(_ points: [WeightPoint], windowDays: Int = 7) -> WeightTrendResult {
        let smoothed = movingAverage(points, windowDays: windowDays)
        let slope = slopeKgPerWeek(smoothed.isEmpty ? points : smoothed)
        return WeightTrendResult(
            smoothed: smoothed,
            slopeKgPerWeek: slope,
            latestSmoothedKg: smoothed.last?.kg
        )
    }
}

/// Recalibrage progressif des calories de maintien à partir des données réelles.
/// Ne modifie jamais l'objectif brutalement : l'utilisateur doit confirmer.
public struct MaintenanceRecalibrator {

    public struct Input {
        public let avgDailyIntakeKcal: Double
        public let weightTrendSlopeKgPerWeek: Double  // < 0 = perte
        public let currentMaintenanceEstimate: Double
        public let daysOfData: Int
        public init(avgDailyIntakeKcal: Double,
                    weightTrendSlopeKgPerWeek: Double,
                    currentMaintenanceEstimate: Double,
                    daysOfData: Int) {
            self.avgDailyIntakeKcal = avgDailyIntakeKcal
            self.weightTrendSlopeKgPerWeek = weightTrendSlopeKgPerWeek
            self.currentMaintenanceEstimate = currentMaintenanceEstimate
            self.daysOfData = daysOfData
        }
    }

    public struct Suggestion: Equatable {
        public let hasEnoughData: Bool
        public let suggestedMaintenance: Int
        public let deltaFromCurrent: Int
        public let requiresUserConfirmation: Bool
    }

    /// Il faut au moins 14 jours de données suffisamment complètes.
    public static let minimumDays = 14
    /// Ajustement plafonné (jamais plus de ±150 kcal en une fois).
    public static let maxAdjustment = 150.0

    public init() {}

    public func suggest(_ input: Input) -> Suggestion {
        guard input.daysOfData >= Self.minimumDays else {
            return Suggestion(hasEnoughData: false,
                              suggestedMaintenance: Int(input.currentMaintenanceEstimate.rounded()),
                              deltaFromCurrent: 0,
                              requiresUserConfirmation: false)
        }

        // Variation de poids observée en kcal/jour :
        // pente(kg/sem) * 7700 kcal/kg / 7 jours.
        let observedDailyEnergyBalance = input.weightTrendSlopeKgPerWeek * 7700.0 / 7.0
        // Maintien réel estimé = apport moyen - déséquilibre observé.
        // (si on perd du poids, le déséquilibre est négatif → maintien > apport).
        let empiricalMaintenance = input.avgDailyIntakeKcal - observedDailyEnergyBalance

        // On rapproche prudemment l'estimation actuelle de l'estimation empirique,
        // par pas plafonnés.
        let rawDelta = empiricalMaintenance - input.currentMaintenanceEstimate
        let cappedDelta = max(-Self.maxAdjustment, min(Self.maxAdjustment, rawDelta))
        let newMaintenance = input.currentMaintenanceEstimate + cappedDelta

        return Suggestion(
            hasEnoughData: true,
            suggestedMaintenance: Int(newMaintenance.rounded()),
            deltaFromCurrent: Int(cappedDelta.rounded()),
            requiresUserConfirmation: true
        )
    }
}
