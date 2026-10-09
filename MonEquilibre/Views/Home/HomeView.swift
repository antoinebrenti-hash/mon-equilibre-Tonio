import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.modelContext) private var context

    @Query(sort: \MealEntry.date) private var meals: [MealEntry]
    @Query(sort: \WeightEntry.date) private var weights: [WeightEntry]
    @Query private var waters: [WaterEntry]
    @Query private var targets: [DailyNutritionTarget]

    @State private var snapshot: HealthSnapshot?
    @State private var showAddMeal = false
    @State private var showScanner = false
    @State private var showWeightEntry = false

    private var cal: Calendar { .current }
    private var todayMeals: [MealEntry] { meals.filter { cal.isDateInToday($0.date) } }
    private var todayWaterMl: Int { waters.filter { cal.isDateInToday($0.date) }.reduce(0) { $0 + $1.milliliters } }

    private var todayTarget: DailyNutritionTarget? {
        targets.first { cal.isDateInToday($0.date) } ?? targets.sorted { $0.date > $1.date }.first
    }

    private var consumed: NutritionFacts {
        todayMeals.reduce(NutritionFacts()) { acc, m in
            NutritionFacts(caloriesKcal: acc.caloriesKcal + m.facts.caloriesKcal,
                           proteinG: acc.proteinG + m.facts.proteinG,
                           carbG: acc.carbG + m.facts.carbG,
                           sugarG: acc.sugarG + m.facts.sugarG,
                           fatG: acc.fatG + m.facts.fatG,
                           saturatedFatG: acc.saturatedFatG + m.facts.saturatedFatG,
                           fiberG: acc.fiberG + m.facts.fiberG,
                           saltG: acc.saltG + m.facts.saltG)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    caloriesCard
                    macrosCard
                    quickActions
                    healthCard
                    weightCard
                    disclaimer
                }
                .padding()
            }
            .navigationTitle("Accueil")
            .task { snapshot = try? await env.health.todaySnapshot() }
            .sheet(isPresented: $showAddMeal) { AddFoodView(mealType: .snack) }
            .sheet(isPresented: $showScanner) { BarcodeScannerView(mealType: .snack) }
            .sheet(isPresented: $showWeightEntry) { QuickWeightSheet() }
        }
    }

    private var caloriesCard: some View {
        let target = todayTarget
        let center = target?.caloriesCenter ?? 2000
        let eaten = Int(consumed.caloriesKcal.rounded())
        let remaining = center - eaten
        let progress = center > 0 ? Double(eaten) / Double(center) : 0
        return VStack(spacing: 12) {
            RingGauge(progress: progress, label: "Calories consommées",
                      centerText: "\(eaten)", tint: progress > 1.05 ? .orange : .green)
            if let target {
                Text("Objectif : \(target.caloriesLow)–\(target.caloriesHigh) kcal")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text(remaining >= 0 ? "Il te reste ~\(remaining) kcal" : "Dépassement d'environ \(-remaining) kcal")
                    .font(.subheadline).bold()
                if progress > 1.05 {
                    SafetyBanner(text: "Une journée ne détermine pas ta progression. Observe surtout la moyenne de la semaine.")
                }
            } else {
                Text("Renseigne ton profil pour estimer ton objectif calorique.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding().frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var macrosCard: some View {
        let t = todayTarget
        return VStack(alignment: .leading, spacing: 10) {
            Text("Macronutriments").font(.headline)
            MacroBar(name: "Protéines", current: Int(consumed.proteinG), target: t?.proteinGrams ?? 120, tint: .blue)
            MacroBar(name: "Glucides", current: Int(consumed.carbG), target: t?.carbGrams ?? 220, tint: .orange)
            MacroBar(name: "Lipides", current: Int(consumed.fatG), target: t?.fatGrams ?? 65, tint: .yellow)
            MacroBar(name: "Fibres", current: Int(consumed.fiberG), target: t?.fiberGramsMin ?? 30, tint: .green)
            HStack {
                Label("\(todayWaterMl) ml d'eau", systemImage: "drop.fill").foregroundStyle(.teal)
                Spacer()
                Text("Objectif \(t?.waterTargetMl ?? 2000) ml").font(.caption).foregroundStyle(.secondary)
            }.font(.subheadline)
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var quickActions: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
            QuickActionButton(title: "Repas", systemImage: "plus.circle") { showAddMeal = true }
            QuickActionButton(title: "Scanner", systemImage: "barcode.viewfinder") { showScanner = true }
            QuickActionButton(title: "Eau", systemImage: "drop") { addWater(250) }
            QuickActionButton(title: "Poids", systemImage: "scalemass") { showWeightEntry = true }
            NavigationLink { WorkoutsView() } label: {
                VStack(spacing: 6) { Image(systemName: "figure.run"); Text("Séance").font(.caption2) }
                    .frame(maxWidth: .infinity, minHeight: 64)
            }.buttonStyle(.bordered)
            NavigationLink { WhatCanIEatView() } label: {
                VStack(spacing: 6) { Image(systemName: "lightbulb"); Text("Que manger ?").font(.caption2) }
                    .frame(maxWidth: .infinity, minHeight: 64)
            }.buttonStyle(.bordered)
        }
    }

    private var healthCard: some View {
        HStack {
            StatCard(title: "Pas", value: snapshot?.steps.map(String.init) ?? "—",
                     systemImage: "figure.walk", tint: .green)
            StatCard(title: "Calories actives", value: snapshot?.activeEnergyKcal.map { "\(Int($0))" } ?? "—",
                     subtitle: "Apple Santé", systemImage: "flame.fill", tint: .orange)
        }
    }

    private var weightCard: some View {
        let recent = weights.suffix(14).map(\.point)
        let trend = env.weightTrend.analyze(Array(recent))
        return HStack {
            StatCard(title: "Poids actuel",
                     value: weights.last.map { String(format: "%.1f kg", $0.kg) } ?? "—",
                     systemImage: "scalemass", tint: .purple)
            StatCard(title: "Tendance / sem.",
                     value: String(format: "%+.2f kg", trend.slopeKgPerWeek),
                     subtitle: "moyenne lissée", systemImage: "chart.line.uptrend.xyaxis",
                     tint: trend.slopeKgPerWeek <= 0 ? .green : .orange)
        }
    }

    private var disclaimer: some View {
        SafetyBanner(text: "Les objectifs et estimations sont indicatifs. Cette application ne remplace pas un médecin, un diététicien ou un kinésithérapeute.",
                     systemImage: "cross.case")
    }

    private func addWater(_ ml: Int) {
        context.insert(WaterEntry(milliliters: ml))
        try? context.save()
    }
}

#Preview {
    HomeView()
        .environmentObject(AppEnvironment.preview())
        .modelContainer(for: [MealEntry.self, WeightEntry.self, WaterEntry.self, DailyNutritionTarget.self], inMemory: true)
}
