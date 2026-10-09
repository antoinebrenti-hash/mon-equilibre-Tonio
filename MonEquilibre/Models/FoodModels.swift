import Foundation
import SwiftData

/// Valeurs nutritionnelles pour 100 g / 100 ml (référence stable).
public struct NutritionFacts: Codable, Equatable, Sendable {
    public var caloriesKcal: Double
    public var proteinG: Double
    public var carbG: Double
    public var sugarG: Double
    public var fatG: Double
    public var saturatedFatG: Double
    public var fiberG: Double
    public var saltG: Double

    public init(caloriesKcal: Double = 0, proteinG: Double = 0, carbG: Double = 0,
                sugarG: Double = 0, fatG: Double = 0, saturatedFatG: Double = 0,
                fiberG: Double = 0, saltG: Double = 0) {
        self.caloriesKcal = caloriesKcal
        self.proteinG = proteinG
        self.carbG = carbG
        self.sugarG = sugarG
        self.fatG = fatG
        self.saturatedFatG = saturatedFatG
        self.fiberG = fiberG
        self.saltG = saltG
    }

    /// Met à l'échelle les valeurs (données pour 100 g) selon un poids réel en grammes.
    public func scaled(toGrams grams: Double) -> NutritionFacts {
        let f = grams / 100.0
        return NutritionFacts(caloriesKcal: caloriesKcal * f, proteinG: proteinG * f,
                              carbG: carbG * f, sugarG: sugarG * f, fatG: fatG * f,
                              saturatedFatG: saturatedFatG * f, fiberG: fiberG * f, saltG: saltG * f)
    }
}

/// Un produit alimentaire (mis en cache localement après recherche/scan).
@Model
public final class FoodProduct {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var brand: String?
    public var barcode: String?
    public var facts: NutritionFacts        // pour 100 g / 100 ml
    public var defaultServingGrams: Double  // portion habituelle
    public var sourceRaw: String            // ProductSource
    public var recommendationRaw: String    // FoodCategory (indicatif)
    public var photoData: Data?             // photo facultative
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(),
                name: String,
                brand: String? = nil,
                barcode: String? = nil,
                facts: NutritionFacts = NutritionFacts(),
                defaultServingGrams: Double = 100,
                source: ProductSource = .manual,
                recommendation: FoodCategory = .normal,
                photoData: Data? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.facts = facts
        self.defaultServingGrams = defaultServingGrams
        self.sourceRaw = source.rawValue
        self.recommendationRaw = recommendation.rawValue
        self.photoData = photoData
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    public var source: ProductSource {
        get { ProductSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
    public var recommendation: FoodCategory {
        get { FoodCategory(rawValue: recommendationRaw) ?? .normal }
        set { recommendationRaw = newValue.rawValue }
    }
}

/// Une entrée de repas (un aliment consommé à un moment donné).
@Model
public final class MealEntry {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var mealTypeRaw: String          // MealType
    public var productName: String          // dénormalisé (l'aliment peut être supprimé)
    public var brand: String?
    public var barcode: String?
    public var quantity: Double             // quantité saisie
    public var unitRaw: String              // ServingUnit
    public var grams: Double                // poids effectif en grammes
    public var facts: NutritionFacts        // valeurs déjà mises à l'échelle pour ce repas
    public var sourceRaw: String            // ProductSource
    public var createdAt: Date

    public init(id: UUID = UUID(),
                date: Date = Date(),
                mealType: MealType,
                productName: String,
                brand: String? = nil,
                barcode: String? = nil,
                quantity: Double,
                unit: ServingUnit = .gram,
                grams: Double,
                facts: NutritionFacts,
                source: ProductSource = .manual) {
        self.id = id
        self.date = date
        self.mealTypeRaw = mealType.rawValue
        self.productName = productName
        self.brand = brand
        self.barcode = barcode
        self.quantity = quantity
        self.unitRaw = unit.rawValue
        self.grams = grams
        self.facts = facts
        self.sourceRaw = source.rawValue
        self.createdAt = Date()
    }

    public var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .snack }
        set { mealTypeRaw = newValue.rawValue }
    }
    public var unit: ServingUnit {
        get { ServingUnit(rawValue: unitRaw) ?? .gram }
        set { unitRaw = newValue.rawValue }
    }
}

/// Une recette enregistrée.
@Model
public final class Recipe {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var servings: Int
    @Relationship(deleteRule: .cascade) public var ingredients: [RecipeIngredient]
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), name: String, servings: Int = 1, ingredients: [RecipeIngredient] = []) {
        self.id = id
        self.name = name
        self.servings = max(1, servings)
        self.ingredients = ingredients
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Valeurs nutritionnelles totales de la recette.
    public var totalFacts: NutritionFacts {
        ingredients.reduce(NutritionFacts()) { acc, ing in
            let f = ing.facts.scaled(toGrams: ing.grams)
            return NutritionFacts(
                caloriesKcal: acc.caloriesKcal + f.caloriesKcal,
                proteinG: acc.proteinG + f.proteinG,
                carbG: acc.carbG + f.carbG,
                sugarG: acc.sugarG + f.sugarG,
                fatG: acc.fatG + f.fatG,
                saturatedFatG: acc.saturatedFatG + f.saturatedFatG,
                fiberG: acc.fiberG + f.fiberG,
                saltG: acc.saltG + f.saltG)
        }
    }

    /// Valeurs par portion.
    public var perServingFacts: NutritionFacts {
        let total = totalFacts
        let s = Double(max(1, servings))
        return NutritionFacts(caloriesKcal: total.caloriesKcal / s, proteinG: total.proteinG / s,
                              carbG: total.carbG / s, sugarG: total.sugarG / s, fatG: total.fatG / s,
                              saturatedFatG: total.saturatedFatG / s, fiberG: total.fiberG / s, saltG: total.saltG / s)
    }
}

/// Un ingrédient de recette (valeurs pour 100 g + poids utilisé).
@Model
public final class RecipeIngredient {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var grams: Double
    public var facts: NutritionFacts   // pour 100 g
    public var createdAt: Date

    public init(id: UUID = UUID(), name: String, grams: Double, facts: NutritionFacts) {
        self.id = id
        self.name = name
        self.grams = grams
        self.facts = facts
        self.createdAt = Date()
    }
}
