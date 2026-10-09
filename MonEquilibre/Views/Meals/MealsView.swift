import SwiftUI
import SwiftData

struct MealsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MealEntry.date, order: .reverse) private var meals: [MealEntry]
    @State private var addingType: MealType?
    @State private var selectedDate = Date()

    private var cal: Calendar { .current }
    private func meals(for type: MealType) -> [MealEntry] {
        meals.filter { cal.isDate($0.date, inSameDayAs: selectedDate) && $0.mealType == type }
    }

    var body: some View {
        NavigationStack {
            List {
                DatePicker("Jour", selection: $selectedDate, displayedComponents: .date)
                    .listRowBackground(Color.clear)

                ForEach(MealType.allCases) { type in
                    Section {
                        let items = meals(for: type)
                        if items.isEmpty {
                            Text("Aucun aliment").font(.subheadline).foregroundStyle(.secondary)
                        } else {
                            ForEach(items) { FoodRow(entry: $0) }
                                .onDelete { idx in delete(items, idx) }
                        }
                        Button {
                            addingType = type
                        } label: {
                            Label("Ajouter à \(label(type))", systemImage: "plus.circle")
                        }
                    } header: {
                        HStack {
                            Text(label(type))
                            Spacer()
                            Text("\(Int(meals(for: type).reduce(0) { $0 + $1.facts.caloriesKcal })) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Repas")
            .sheet(item: $addingType) { type in AddFoodView(mealType: type, date: selectedDate) }
        }
    }

    private func label(_ t: MealType) -> String {
        switch t {
        case .breakfast: return "Petit-déjeuner"
        case .lunch: return "Déjeuner"
        case .dinner: return "Dîner"
        case .snack: return "Collations"
        }
    }

    private func delete(_ items: [MealEntry], _ offsets: IndexSet) {
        offsets.map { items[$0] }.forEach(context.delete)
        try? context.save()
    }
}

/// Ligne d'aliment réutilisable.
struct FoodRow: View {
    let entry: MealEntry
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.productName).font(.body)
                Text("\(Int(entry.grams)) g" + (entry.brand.map { " · \($0)" } ?? ""))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.facts.caloriesKcal)) kcal").font(.subheadline).bold()
                Text("P \(Int(entry.facts.proteinG)) · G \(Int(entry.facts.carbG)) · L \(Int(entry.facts.fatG))")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    MealsView()
        .environmentObject(AppEnvironment.preview())
        .modelContainer(for: [MealEntry.self], inMemory: true)
}
