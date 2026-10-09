import SwiftUI
import SwiftData

/// Ajout d'un aliment : recherche, saisie manuelle, ou depuis un scan.
/// L'utilisateur peut toujours vérifier et corriger les valeurs avant d'enregistrer.
struct AddFoodView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let mealType: MealType
    var date: Date = Date()
    var prefilled: FoodProductInfo? = nil

    @State private var query = ""
    @State private var results: [FoodProductInfo] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    // Édition de l'aliment sélectionné (valeurs pour 100 g + quantité).
    @State private var editing: FoodProductInfo?
    @State private var grams: Double = 100

    var body: some View {
        NavigationStack {
            Group {
                if let editing {
                    editor(for: editing)
                } else {
                    searchList
                }
            }
            .navigationTitle("Ajouter un aliment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } }
            }
            .onAppear {
                if let prefilled { self.editing = prefilled; self.grams = prefilled.defaultServingGrams }
            }
        }
    }

    private var searchList: some View {
        List {
            Section {
                HStack {
                    TextField("Rechercher un aliment", text: $query)
                        .onSubmit { Task { await search() } }
                    Button { Task { await search() } } label: { Image(systemName: "magnifyingglass") }
                }
                Button {
                    editing = FoodProductInfo(name: query.isEmpty ? "Nouvel aliment" : query,
                                              facts: NutritionFacts(), source: .manual)
                    grams = 100
                } label: { Label("Saisie manuelle", systemImage: "square.and.pencil") }
            }

            if isSearching { ProgressView() }
            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.orange)
            }

            Section("Résultats") {
                if results.isEmpty && !isSearching {
                    Text("Lance une recherche ou saisis un aliment.").font(.subheadline).foregroundStyle(.secondary)
                }
                ForEach(results, id: \.name) { info in
                    Button {
                        editing = info; grams = info.defaultServingGrams
                    } label: {
                        VStack(alignment: .leading) {
                            Text(info.name)
                            Text("\(Int(info.facts.caloriesKcal)) kcal / 100 g" + (info.brand.map { " · \($0)" } ?? ""))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func editor(for info: FoodProductInfo) -> some View {
        let scaled = info.facts.scaled(toGrams: grams)
        return Form {
            Section("Aliment") {
                TextField("Nom", text: Binding(get: { info.name }, set: { editing?.name = $0 }))
                TextField("Marque", text: Binding(get: { info.brand ?? "" }, set: { editing?.brand = $0 }))
                if info.source == .openFoodFacts {
                    Label("Source : Open Food Facts (à vérifier)", systemImage: "info.circle")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Quantité") {
                HStack {
                    Text("Poids (g)")
                    Spacer()
                    TextField("g", value: $grams, format: .number).keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing).frame(width: 90)
                }
                Text("Soit \(Int(scaled.caloriesKcal)) kcal").font(.headline)
            }
            Section("Valeurs pour 100 g (vérifie et corrige)") {
                factField("Calories (kcal)", \.caloriesKcal)
                factField("Protéines (g)", \.proteinG)
                factField("Glucides (g)", \.carbG)
                factField("dont sucres (g)", \.sugarG)
                factField("Lipides (g)", \.fatG)
                factField("dont saturés (g)", \.saturatedFatG)
                factField("Fibres (g)", \.fiberG)
                factField("Sel (g)", \.saltG)
            }
            Section {
                Button {
                    save(info: editing ?? info, grams: grams)
                } label: { Label("Enregistrer dans \(mealType.rawValue)", systemImage: "checkmark.circle.fill") }
                Button(role: .cancel) { editing = nil } label: { Text("Retour à la recherche") }
            }
        }
    }

    private func factField(_ title: String, _ key: WritableKeyPath<NutritionFacts, Double>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", value: Binding(
                get: { editing?.facts[keyPath: key] ?? 0 },
                set: { editing?.facts[keyPath: key] = $0 }
            ), format: .number)
            .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 90)
        }
    }

    private func search() async {
        errorMessage = nil
        isSearching = true
        defer { isSearching = false }
        do {
            results = try await env.food.search(query: query)
            if results.isEmpty { errorMessage = "Aucun résultat. Tu peux saisir l'aliment manuellement." }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Recherche indisponible."
        }
    }

    private func save(info: FoodProductInfo, grams: Double) {
        let scaled = info.facts.scaled(toGrams: grams)
        let entry = MealEntry(date: date, mealType: mealType, productName: info.name,
                              brand: info.brand?.isEmpty == true ? nil : info.brand, barcode: info.barcode,
                              quantity: grams, unit: .gram, grams: grams, facts: scaled, source: info.source)
        context.insert(entry)

        // Met en cache le produit localement (recherche future plus rapide).
        let product = FoodProduct(name: info.name, brand: info.brand, barcode: info.barcode,
                                  facts: info.facts, defaultServingGrams: info.defaultServingGrams, source: info.source)
        context.insert(product)
        try? context.save()
        dismiss()
    }
}

#Preview {
    AddFoodView(mealType: .lunch)
        .environmentObject(AppEnvironment.preview())
        .modelContainer(for: [MealEntry.self, FoodProduct.self], inMemory: true)
}
