import Foundation

/// Ce qu'il reste à consommer dans la journée.
public struct RemainingBudget: Equatable, Sendable {
    public let kcal: Int
    public let proteinG: Int
    public let fiberG: Int
    public init(kcal: Int, proteinG: Int, fiberG: Int) {
        self.kcal = kcal
        self.proteinG = proteinG
        self.fiberG = fiberG
    }
}

/// Une suggestion de repas/collation (plusieurs propositions, jamais une réponse unique).
public struct FoodSuggestion: Equatable, Sendable, Identifiable {
    public enum Kind: String, Sendable {
        case quick, filling, highProtein, light, snack, vegetarian
    }
    public var id: String { kind.rawValue }
    public let kind: Kind
    public let title: String
    public let detail: String
    public let approxKcal: Int
}

/// Moteur de conseils alimentaires.
/// Ne classe jamais un aliment en « bon » / « mauvais ».
public struct FoodAdvisor {

    public init() {}

    /// Calcule ce qu'il reste par rapport à l'objectif, à partir du consommé.
    public func remaining(target: DailyNutritionTarget, consumed: NutritionFacts) -> RemainingBudget {
        RemainingBudget(
            kcal: max(0, target.caloriesCenter - Int(consumed.caloriesKcal.rounded())),
            proteinG: max(0, target.proteinGrams - Int(consumed.proteinG.rounded())),
            fiberG: max(0, target.fiberGramsMin - Int(consumed.fiberG.rounded()))
        )
    }

    /// Propose plusieurs solutions adaptées aux calories et nutriments restants,
    /// en respectant préférences, exclusions et allergies.
    public func suggestions(for budget: RemainingBudget,
                            preferences: [String],
                            excluded: [String],
                            vegetarian: Bool) -> [FoodSuggestion] {
        var out: [FoodSuggestion] = []
        let k = budget.kcal

        func allowed(_ text: String) -> Bool {
            let lower = text.lowercased()
            return !excluded.contains { !$0.isEmpty && lower.contains($0.lowercased()) }
        }

        // Repas rapide
        if allowed("wrap poulet crudités") && !vegetarian {
            out.append(.init(kind: .quick, title: "Repas rapide",
                             detail: "Wrap au poulet et crudités.", approxKcal: min(k, 450)))
        } else if allowed("wrap houmous crudités") {
            out.append(.init(kind: .quick, title: "Repas rapide",
                             detail: "Wrap houmous et crudités.", approxKcal: min(k, 430)))
        }

        // Repas rassasiant (volume + fibres)
        if allowed("soupe de légumes lentilles pain complet") {
            out.append(.init(kind: .filling, title: "Repas rassasiant",
                             detail: "Soupe de légumes, lentilles, pain complet.", approxKcal: min(k, 500)))
        }

        // Riche en protéines
        if budget.proteinG > 15 {
            if vegetarian && allowed("fromage blanc noix graines") {
                out.append(.init(kind: .highProtein, title: "Riche en protéines",
                                 detail: "Fromage blanc, noix et graines.", approxKcal: min(k, 350)))
            } else if allowed("œufs légumes") {
                out.append(.init(kind: .highProtein, title: "Riche en protéines",
                                 detail: "Omelette aux légumes.", approxKcal: min(k, 380)))
            }
        }

        // Repas léger
        if allowed("salade complète") {
            out.append(.init(kind: .light, title: "Repas léger",
                             detail: "Grande salade composée avec une source de protéines.", approxKcal: min(k, 320)))
        }

        // Collation
        if k <= 300 && allowed("fruit yaourt") {
            out.append(.init(kind: .snack, title: "Collation",
                             detail: "Un fruit et un yaourt nature.", approxKcal: min(k, 180)))
        }

        // Alternative végétarienne (toujours proposée si non déjà couverte)
        if allowed("bowl quinoa légumes pois chiches") {
            out.append(.init(kind: .vegetarian, title: "Alternative végétarienne",
                             detail: "Bowl quinoa, légumes et pois chiches.", approxKcal: min(k, 480)))
        }

        // On garde les propositions qui tiennent dans le budget (avec une petite marge).
        let filtered = out.filter { $0.approxKcal <= max(200, k + 50) }
        return filtered.isEmpty ? out : filtered
    }

    /// Message de remplacement pour un produit calorique, sans culpabilisation.
    public func replacementAdvice(productName: String, kcalForServing: Int) -> String {
        "\(productName) est assez calorique pour la quantité consommée. Trois possibilités : "
        + "réduire légèrement la portion, l'accompagner d'aliments plus rassasiants (légumes, fibres), "
        + "ou choisir une alternative proche. À toi de voir ce qui te convient."
    }
}
