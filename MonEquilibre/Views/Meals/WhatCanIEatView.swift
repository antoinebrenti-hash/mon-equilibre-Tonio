import SwiftUI
import SwiftData

/// Écran « Que puis-je encore manger aujourd'hui ? »
/// Propose plusieurs solutions adaptées aux calories et nutriments restants.
struct WhatCanIEatView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Query private var meals: [MealEntry]
    @Query private var targets: [DailyNutritionTarget]
    @Query private var profiles: [UserProfile]

    private var cal: Calendar { .current }
    private var todayMeals: [MealEntry] { meals.filter { cal.isDateInToday($0.date) } }
    private var target: DailyNutritionTarget? {
        targets.first { cal.isDateInToday($0.date) } ?? targets.sorted { $0.date > $1.date }.first
    }

    private var consumed: NutritionFacts {
        todayMeals.reduce(NutritionFacts()) { acc, m in
            NutritionFacts(caloriesKcal: acc.caloriesKcal + m.facts.caloriesKcal,
                           proteinG: acc.proteinG + m.facts.proteinG,
                           carbG: acc.carbG + m.facts.carbG, fatG: acc.fatG + m.facts.fatG,
                           fiberG: acc.fiberG + m.facts.fiberG)
        }
    }

    var body: some View {
        List {
            if let target {
                let budget = env.advisor.remaining(target: target, consumed: consumed)
                Section {
                    HStack {
                        StatCard(title: "Calories restantes", value: "\(budget.kcal)", systemImage: "flame", tint: .green)
                        StatCard(title: "Protéines restantes", value: "\(budget.proteinG) g", systemImage: "bolt", tint: .blue)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                Section("Quelques idées adaptées") {
                    let vegetarian = (profiles.first?.dietaryPreferences ?? []).contains { $0.lowercased().contains("végétar") }
                    let suggestions = env.advisor.suggestions(
                        for: budget,
                        preferences: profiles.first?.dietaryPreferences ?? [],
                        excluded: (profiles.first?.excludedFoods ?? []) + (profiles.first?.allergies ?? []),
                        vegetarian: vegetarian)
                    ForEach(suggestions) { s in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.title).font(.headline)
                            Text(s.detail).font(.subheadline).foregroundStyle(.secondary)
                            Text("≈ \(s.approxKcal) kcal").font(.caption).foregroundStyle(.tertiary)
                        }.padding(.vertical, 2)
                    }
                }
                Section {
                    SafetyBanner(text: "Ce ne sont que des pistes, pas une réponse unique. Choisis ce qui te fait plaisir et te convient.")
                        .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                }
            } else {
                EmptyStateView(systemImage: "lightbulb",
                               title: "Objectif non défini",
                               message: "Renseigne ton profil pour estimer ce qu'il te reste à consommer.")
            }
        }
        .navigationTitle("Que manger ?")
    }
}

#Preview {
    NavigationStack { WhatCanIEatView() }
        .environmentObject(AppEnvironment.preview())
        .modelContainer(for: [MealEntry.self, DailyNutritionTarget.self, UserProfile.self], inMemory: true)
}
