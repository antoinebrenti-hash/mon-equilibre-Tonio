import Foundation
import SwiftData

/// Pesée.
@Model
public final class WeightEntry {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var kg: Double
    public var fromHealthKit: Bool
    public var createdAt: Date

    public init(id: UUID = UUID(), date: Date = Date(), kg: Double, fromHealthKit: Bool = false) {
        self.id = id
        self.date = date
        self.kg = kg
        self.fromHealthKit = fromHealthKit
        self.createdAt = Date()
    }

    /// Conversion vers le type de calcul pur (découplage SwiftData / logique).
    public var point: WeightPoint { WeightPoint(date: date, kg: kg) }
}

/// Tour de taille.
@Model
public final class WaistEntry {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var cm: Double
    public var createdAt: Date

    public init(id: UUID = UUID(), date: Date = Date(), cm: Double) {
        self.id = id
        self.date = date
        self.cm = cm
        self.createdAt = Date()
    }
}

/// Entrée d'eau (en millilitres).
@Model
public final class WaterEntry {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var milliliters: Int
    public var createdAt: Date

    public init(id: UUID = UUID(), date: Date = Date(), milliliters: Int) {
        self.id = id
        self.date = date
        self.milliliters = milliliters
        self.createdAt = Date()
    }
}

/// Mesure corporelle facultative (bras, cuisse, etc.).
@Model
public final class BodyMeasurement {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var label: String
    public var cm: Double
    public var createdAt: Date

    public init(id: UUID = UUID(), date: Date = Date(), label: String, cm: Double) {
        self.id = id
        self.date = date
        self.label = label
        self.cm = cm
        self.createdAt = Date()
    }
}

/// Photo de progression facultative (stockée localement).
@Model
public final class ProgressPhoto {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    @Attribute(.externalStorage) public var imageData: Data
    public var note: String?
    public var createdAt: Date

    public init(id: UUID = UUID(), date: Date = Date(), imageData: Data, note: String? = nil) {
        self.id = id
        self.date = date
        self.imageData = imageData
        self.note = note
        self.createdAt = Date()
    }
}
