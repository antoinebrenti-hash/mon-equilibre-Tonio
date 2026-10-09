import Foundation

/// Abstraction de l'export des données (CSV et JSON).
public protocol DataExporting {
    func weightCSV(_ entries: [WeightEntry]) -> String
    func mealsCSV(_ entries: [MealEntry]) -> String
    func fullJSON(weights: [WeightEntry], waists: [WaistEntry], meals: [MealEntry]) throws -> Data
}

public struct DataExportService: DataExporting {
    public init() {}

    private let iso = ISO8601DateFormatter()

    /// Échappe un champ CSV (guillemets et séparateurs).
    private func csvField(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }

    public func weightCSV(_ entries: [WeightEntry]) -> String {
        var lines = ["date,kg,source"]
        for e in entries.sorted(by: { $0.date < $1.date }) {
            lines.append("\(iso.string(from: e.date)),\(e.kg),\(e.fromHealthKit ? "healthkit" : "manuel")")
        }
        return lines.joined(separator: "\n")
    }

    public func mealsCSV(_ entries: [MealEntry]) -> String {
        var lines = ["date,repas,aliment,marque,grammes,kcal,proteines_g,glucides_g,lipides_g,fibres_g"]
        for e in entries.sorted(by: { $0.date < $1.date }) {
            let f = e.facts
            let row = [
                iso.string(from: e.date),
                e.mealType.rawValue,
                csvField(e.productName),
                csvField(e.brand ?? ""),
                String(format: "%.0f", e.grams),
                String(format: "%.0f", f.caloriesKcal),
                String(format: "%.1f", f.proteinG),
                String(format: "%.1f", f.carbG),
                String(format: "%.1f", f.fatG),
                String(format: "%.1f", f.fiberG)
            ].joined(separator: ",")
            lines.append(row)
        }
        return lines.joined(separator: "\n")
    }

    public func fullJSON(weights: [WeightEntry], waists: [WaistEntry], meals: [MealEntry]) throws -> Data {
        struct Export: Encodable {
            struct W: Encodable { let date: Date; let kg: Double }
            struct Waist: Encodable { let date: Date; let cm: Double }
            struct M: Encodable { let date: Date; let type: String; let name: String; let kcal: Double }
            let weights: [W]
            let waists: [Waist]
            let meals: [M]
        }
        let export = Export(
            weights: weights.map { .init(date: $0.date, kg: $0.kg) },
            waists: waists.map { .init(date: $0.date, cm: $0.cm) },
            meals: meals.map { .init(date: $0.date, type: $0.mealType.rawValue, name: $0.productName, kcal: $0.facts.caloriesKcal) }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(export)
    }
}
