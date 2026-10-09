import SwiftUI
import SwiftData

/// Enregistrement rapide du poids (avec écriture facultative dans Apple Santé).
struct QuickWeightSheet: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [AppSettings]

    @State private var kg: Double = 80
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Poids") {
                    HStack {
                        Text("Poids (kg)")
                        Spacer()
                        TextField("kg", value: $kg, format: .number).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 100)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section {
                    Text("Une seule pesée varie beaucoup. C'est la tendance sur plusieurs jours qui compte.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Enregistrer mon poids")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Enregistrer") { save() } }
            }
        }
    }

    private func save() {
        context.insert(WeightEntry(date: date, kg: kg))
        try? context.save()
        if settings.first?.healthKitEnabled == true {
            Task { try? await env.health.writeWeight(kg: kg, date: date) }
        }
        dismiss()
    }
}

/// Enregistrement rapide du tour de taille.
struct QuickWaistSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var cm: Double = 90
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Tour de taille") {
                    HStack {
                        Text("Tour de taille (cm)")
                        Spacer()
                        TextField("cm", value: $cm, format: .number).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(width: 100)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Tour de taille")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        context.insert(WaistEntry(date: date, cm: cm)); try? context.save(); dismiss()
                    }
                }
            }
        }
    }
}
