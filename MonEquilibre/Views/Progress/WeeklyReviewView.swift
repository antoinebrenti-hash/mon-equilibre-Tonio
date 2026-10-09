import SwiftUI
import SwiftData

struct WeeklyReviewView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Query(sort: \WeightEntry.date) private var weights: [WeightEntry]
    @Query(sort: \WaistEntry.date) private var waists: [WaistEntry]
    @Query private var meals: [MealEntry]
    @Query private var sessions: [WorkoutSession]

    private var result: WeeklyReviewResult {
        let cal = Calendar.current
        guard let weekAgo = cal.date(byAdding: .day, value: -7, to: Date()) else {
            return env.weeklyReview.evaluate(.init(daysWithMealData: 0, avgCaloriesKcal: nil, weightSlopeKgPerWeek: nil, waistDeltaCm: nil, plannedSessions: 0, completedSessions: 0, avgSteps: nil))
        }
        let weekMeals = meals.filter { $0.date >= weekAgo }
        let daysWithData = Set(weekMeals.map { cal.startOfDay(for: $0.date) }).count
        let avgKcal: Double? = daysWithData > 0
            ? weekMeals.reduce(0.0) { $0 + $1.facts.caloriesKcal } / Double(daysWithData)
            : nil
        let recentWeights = weights.filter { $0.date >= weekAgo }.map(\.point)
        let slope: Double? = recentWeights.count >= 2 ? env.weightTrend.slopeKgPerWeek(recentWeights) : nil
        let waistDelta: Double? = {
            let w = waists.filter { $0.date >= weekAgo }
            guard let first = w.first?.cm, let last = w.last?.cm, w.count >= 2 else { return nil }
            return last - first
        }()
        let completed = sessions.filter { $0.date >= weekAgo }.count

        return env.weeklyReview.evaluate(.init(
            daysWithMealData: daysWithData, avgCaloriesKcal: avgKcal,
            weightSlopeKgPerWeek: slope, waistDeltaCm: waistDelta,
            plannedSessions: 3, completedSessions: completed, avgSteps: nil))
    }

    var body: some View {
        let r = result
        List {
            Section {
                Text(r.headline).font(.title3).bold()
                Text(verdictLabel(r.verdict)).font(.subheadline).foregroundStyle(.secondary)
            }
            Section("Points positifs") {
                ForEach(r.positives, id: \.self) { Label($0, systemImage: "checkmark.circle").foregroundStyle(.green) }
            }
            Section("Ta priorité pour la semaine") {
                Text(r.singlePriority).font(.headline)
            }
            Section {
                SafetyBanner(text: "Ce bilan est indicatif et ne constitue pas un diagnostic médical.")
                    .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Bilan de la semaine")
    }

    private func verdictLabel(_ v: WeeklyTrendVerdict) -> String {
        switch v {
        case .notEnoughData: return "Manque de données pour conclure."
        case .likelyMaintaining: return "Maintien probable."
        case .likelyProgressing: return "Progression probable."
        case .possiblyTooFast: return "Baisse peut-être trop rapide."
        case .possibleOvertraining: return "Fatigue ou entraînement excessif possible."
        }
    }
}

#Preview {
    NavigationStack { WeeklyReviewView() }
        .environmentObject(AppEnvironment.preview())
        .modelContainer(for: [WeightEntry.self, WaistEntry.self, MealEntry.self, WorkoutSession.self], inMemory: true)
}
