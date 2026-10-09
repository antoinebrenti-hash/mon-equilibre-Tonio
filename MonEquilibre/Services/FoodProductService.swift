import Foundation

/// Résultat d'une recherche de produit (indépendant du modèle SwiftData).
public struct FoodProductInfo: Equatable, Sendable, Identifiable {
    public let id = UUID()
    public var name: String
    public var brand: String?
    public var barcode: String?
    public var facts: NutritionFacts        // pour 100 g / 100 ml
    public var defaultServingGrams: Double
    public var source: ProductSource
    public var imageURL: URL?

    public init(name: String, brand: String? = nil, barcode: String? = nil,
                facts: NutritionFacts, defaultServingGrams: Double = 100,
                source: ProductSource, imageURL: URL? = nil) {
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.facts = facts
        self.defaultServingGrams = defaultServingGrams
        self.source = source
        self.imageURL = imageURL
    }
}

/// Abstraction de la recherche de produits.
public protocol FoodProductProviding {
    func lookup(barcode: String) async throws -> FoodProductInfo?
    func search(query: String) async throws -> [FoodProductInfo]
}

public enum FoodLookupError: LocalizedError {
    case notFound
    case network
    case decoding

    public var errorDescription: String? {
        switch self {
        case .notFound: return "Produit introuvable. Tu peux le saisir manuellement."
        case .network:  return "Pas de connexion. Réessaie plus tard ou saisis les valeurs à la main."
        case .decoding: return "Les données du produit sont incomplètes. Vérifie et corrige avant d'enregistrer."
        }
    }
}

/// Implémentation Open Food Facts (source **facultative**).
/// Les données collaboratives peuvent être absentes ou incorrectes : l'app doit
/// toujours laisser l'utilisateur vérifier et corriger avant d'enregistrer.
public final class OpenFoodFactsService: FoodProductProviding {
    private let session: URLSession
    private let baseV2 = "https://world.openfoodfacts.org/api/v2"
    private let searchURL = "https://world.openfoodfacts.org/cgi/search.pl"

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func lookup(barcode: String) async throws -> FoodProductInfo? {
        guard let url = URL(string: "\(baseV2)/product/\(barcode).json") else { throw FoodLookupError.network }
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw FoodLookupError.network
            }
            let decoded = try JSONDecoder().decode(OFFProductResponse.self, from: data)
            guard decoded.status == 1, let p = decoded.product else { throw FoodLookupError.notFound }
            return p.toInfo(barcode: barcode)
        } catch let e as FoodLookupError {
            throw e
        } catch is DecodingError {
            throw FoodLookupError.decoding
        } catch {
            throw FoodLookupError.network
        }
    }

    public func search(query: String) async throws -> [FoodProductInfo] {
        var comps = URLComponents(string: searchURL)
        comps?.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "20")
        ]
        guard let url = comps?.url else { throw FoodLookupError.network }
        do {
            let (data, _) = try await session.data(from: url)
            let decoded = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
            return (decoded.products ?? []).compactMap { $0.toInfo(barcode: $0.code) }
        } catch is DecodingError {
            throw FoodLookupError.decoding
        } catch {
            throw FoodLookupError.network
        }
    }
}

/// Mock pour tests / simulateur (aucun réseau).
public final class MockFoodProductService: FoodProductProviding {
    public var byBarcode: [String: FoodProductInfo]
    public var searchResults: [FoodProductInfo]

    public init(byBarcode: [String: FoodProductInfo] = [:], searchResults: [FoodProductInfo] = []) {
        self.byBarcode = byBarcode
        self.searchResults = searchResults
    }

    public func lookup(barcode: String) async throws -> FoodProductInfo? {
        guard let info = byBarcode[barcode] else { throw FoodLookupError.notFound }
        return info
    }
    public func search(query: String) async throws -> [FoodProductInfo] {
        searchResults.filter { $0.name.localizedCaseInsensitiveContains(query) || query.isEmpty }
    }
}

// MARK: - Décodage Open Food Facts (tolérant aux champs manquants)

struct OFFProductResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

struct OFFSearchResponse: Decodable {
    let products: [OFFProduct]?
}

struct OFFProduct: Decodable {
    let code: String?
    let product_name: String?
    let brands: String?
    let image_url: URL?
    let serving_quantity: OFFNumber?
    let nutriments: OFFNutriments?

    func toInfo(barcode: String?) -> FoodProductInfo? {
        let name = product_name?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let name, !name.isEmpty else { return nil }
        let n = nutriments
        let facts = NutritionFacts(
            caloriesKcal: n?.energyKcal100g ?? 0,
            proteinG: n?.proteins_100g?.value ?? 0,
            carbG: n?.carbohydrates_100g?.value ?? 0,
            sugarG: n?.sugars_100g?.value ?? 0,
            fatG: n?.fat_100g?.value ?? 0,
            saturatedFatG: n?.saturatedFat100g ?? 0,
            fiberG: n?.fiber_100g?.value ?? 0,
            saltG: n?.salt_100g?.value ?? 0
        )
        let serving = serving_quantity?.value ?? 100
        return FoodProductInfo(
            name: name,
            brand: brands?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces),
            barcode: barcode,
            facts: facts,
            defaultServingGrams: serving > 0 ? serving : 100,
            source: .openFoodFacts,
            imageURL: image_url
        )
    }
}

struct OFFNutriments: Decodable {
    let proteins_100g: OFFNumber?
    let carbohydrates_100g: OFFNumber?
    let sugars_100g: OFFNumber?
    let fat_100g: OFFNumber?
    let fiber_100g: OFFNumber?
    let salt_100g: OFFNumber?
    let energy_kcal_100g: OFFNumber?
    let energy_100g: OFFNumber?
    let saturated_fat_100g: OFFNumber?

    enum CodingKeys: String, CodingKey {
        case proteins_100g = "proteins_100g"
        case carbohydrates_100g = "carbohydrates_100g"
        case sugars_100g = "sugars_100g"
        case fat_100g = "fat_100g"
        case fiber_100g = "fiber_100g"
        case salt_100g = "salt_100g"
        case energy_kcal_100g = "energy-kcal_100g"
        case energy_100g = "energy_100g"
        case saturated_fat_100g = "saturated-fat_100g"
    }

    /// kcal pour 100 g : privilégie le champ kcal, sinon convertit les kJ.
    var energyKcal100g: Double {
        if let k = energy_kcal_100g?.value { return k }
        if let kj = energy_100g?.value { return kj / 4.184 }
        return 0
    }
    var saturatedFat100g: Double { saturated_fat_100g?.value ?? 0 }
}

/// Open Food Facts renvoie parfois les nombres sous forme de String : on tolère les deux.
struct OFFNumber: Decodable {
    let value: Double?
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let d = try? c.decode(Double.self) { value = d }
        else if let s = try? c.decode(String.self) { value = Double(s.replacingOccurrences(of: ",", with: ".")) }
        else { value = nil }
    }
}
