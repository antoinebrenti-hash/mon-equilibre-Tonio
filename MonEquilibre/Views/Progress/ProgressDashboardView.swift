import SwiftUI
import SwiftData
import Charts

struct ProgressDashboardView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.modelContext) private var context

    @Query(sort: \WeightEntry.date) private var weights: [WeightEntry]
    @Query(sort: \WaistEntry.date) private var waists: [WaistEntry]
    @Query(sort: \MealEntry.date) private var meals: [MealEntry]

    @State private var range: ChartRange = .month
    @State private var showWeight = false
    @State private var showWaist = false
    @State private var exportText: String?

    private func filtered<T>(_ items: [T], date: (T) -> Date) -> [T] {
        guard let days = range.days, let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return items }
        return items.filter { date($0) >= cutoff }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    RangePicker(selection: $range)
                    weightChart
                    waistChart
                    caloriesChart
                    regularityCard
                    exportCard
                }
                .padding()
            }
            .navigationTitle("Progrès")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showWeight = true } label: { Image(systemName: "scalemass") }
                    Button { showWaist = true } label: { Image(systemName: "figure") }
                }
            }
            .sheet(isPresented: $showWeight) { QuickWeightSheet() }
            .sheet(isPresented: $showWaist) { QuickWaistSheet() }
        }
    }

    private var weightChart: some View {
        let pts = filtered(weights) { $0.date }.map(\.point)
        let smoothed = env.weightTrend.movingAverage(pts)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Poids").font(.headline)
            if pts.isEmpty {
                EmptyStateView(systemImage: "scalemass", title: "Aucune pesée",
                               message: "Enregistre ton poids pour suivre la tendance.")
            } else {
                Chart {
                    ForEach(pts, id: \.date) { p in
                        PointMark(x: .value("Date", p.date), y: .value("kg", p.kg))
                            .foregroundStyle(.purple.opacity(0.35))
                    }
                    ForEach(smoothed, id: \.date) { p in
                        LineMark(x: .value("Date", p.date), y: .value("Tendance", p.kg))
                            .foregroundStyle(.purple).interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                Text("La ligne est la moyenne mobile : elle réduit l'effet de l'eau, du sel et de la digestion. Une seule pesée ne dit rien.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var waistChart: some View {
        let items = filtered(waists) { $0.date }
        return VStack(alignment: .leading, spacing: 8) {
            Text("Tour de taille").font(.headline)
            if items.isEmpty {
                Text("Aucune mesure enregistrée.").font(.subheadline).foregroundStyle(.secondary)
            } else {
                Chart(items) { w in
                    LineMark(x: .value("Date", w.date), y: .value("cm", w.cm))
                        .foregroundStyle(.teal)
                    PointMark(x: .value("Date", w.date), y: .value("cm", w.cm)).foregroundStyle(.teal)
                }.frame(height: 160)
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var caloriesChart: some View {
        // Calories consommées par jour sur la période.
        let items = filtered(meals) { $0.date }
        let byDay = Dictionary(grouping: items) { Calendar.current.startOfDay(for: $0.date) }
            .map { (day: $0.key, kcal: $0.value.reduce(0.0) { $0 + $1.facts.caloriesKcal }) }
            .sorted { $0.day < $1.day }
        return VStack(alignment: .leading, spacing: 8) {
            Text("Calories consommées").font(.headline)
            if byDay.isEmpty {
                Text("Pas encore de repas enregistrés.").font(.subheadline).foregroundStyle(.secondary)
            } else {
                Chart(byDay, id: \.day) { d in
                    BarMark(x: .value("Jour", d.day, unit: .day), y: .value("kcal", d.kcal))
                        .foregroundStyle(.green)
                }.frame(height: 160)
            }
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var regularityCard: some View {
        let items = filtered(meals) { $0.date }
        let days = Set(items.map { Calendar.current.startOfDay(for: $0.date) }).count
        let span = range.days ?? max(1, days)
        return HStack {
            StatCard(title: "Jours suivis", value: "\(days)", systemImage: "checkmark.circle", tint: .green)
            StatCard(title: "Régularité", value: "\(Int(Double(days) / Double(max(1, span)) * 100)) %",
                     subtitle: "repas enregistrés", systemImage: "calendar", tint: .blue)
        }
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exporter mes données").font(.headline)
            HStack {
                ShareLink(item: env.export.weightCSV(weights), preview: SharePreview("poids.csv")) {
                    Label("Poids (CSV)", systemImage: "square.and.arrow.up")
                }
                Spacer()
                ShareLink(item: env.export.mealsCSV(meals), preview: SharePreview("repas.csv")) {
                    Label("Repas (CSV)", systemImage: "square.and.arrow.up")
                }
            }.font(.subheadline)
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ProgressDashboardView()
        .environmentObject(AppEnvironment.preview())
        .modelContainer(for: [WeightEntry.self, WaistEntry.self, MealEntry.self], inMemory: true)
}
