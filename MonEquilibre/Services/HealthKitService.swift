import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

/// Instantané des données de santé utiles à l'app.
public struct HealthSnapshot: Equatable, Sendable {
    public var steps: Int?
    public var activeEnergyKcal: Double?
    public var latestWeightKg: Double?
    public var heightCm: Double?
    public var distanceMeters: Double?

    public init(steps: Int? = nil, activeEnergyKcal: Double? = nil,
                latestWeightKg: Double? = nil, heightCm: Double? = nil,
                distanceMeters: Double? = nil) {
        self.steps = steps
        self.activeEnergyKcal = activeEnergyKcal
        self.latestWeightKg = latestWeightKg
        self.heightCm = heightCm
        self.distanceMeters = distanceMeters
    }
}

/// Abstraction de l'accès aux données de santé.
/// Permet d'utiliser une implémentation réelle (HealthKit) ou un mock (simulateur, tests).
public protocol HealthDataProviding {
    var isAvailable: Bool { get }
    /// Demande d'autorisation *séparée* des lectures nécessaires.
    func requestReadAuthorization() async throws
    func todaySnapshot() async throws -> HealthSnapshot
    /// Écriture facultative (poids, énergie alimentaire, eau, entraînements réalisés).
    func writeWeight(kg: Double, date: Date) async throws
    func writeWater(ml: Int, date: Date) async throws
}

/// Erreurs santé exposées à l'utilisateur de façon compréhensible.
public enum HealthError: LocalizedError {
    case unavailable
    case authorizationDenied

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Apple Santé n'est pas disponible sur cet appareil. L'application fonctionne quand même."
        case .authorizationDenied:
            return "L'accès à Apple Santé a été refusé. Tu peux le modifier dans Réglages > Santé."
        }
    }
}

#if canImport(HealthKit)
/// Implémentation réelle basée sur HealthKit.
public final class HealthKitService: HealthDataProviding {
    private let store = HKHealthStore()

    public init() {}

    public var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// On ne demande QUE ce dont l'app a besoin. Chaque type est justifié dans l'UI.
    private var readTypes: Set<HKObjectType> {
        var set: Set<HKObjectType> = []
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) { set.insert(steps) }
        if let active = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { set.insert(active) }
        if let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass) { set.insert(weight) }
        if let height = HKQuantityType.quantityType(forIdentifier: .height) { set.insert(height) }
        if let dist = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) { set.insert(dist) }
        return set
    }

    private var writeTypes: Set<HKSampleType> {
        var set: Set<HKSampleType> = []
        if let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass) { set.insert(weight) }
        if let water = HKQuantityType.quantityType(forIdentifier: .dietaryWater) { set.insert(water) }
        return set
    }

    public func requestReadAuthorization() async throws {
        guard isAvailable else { throw HealthError.unavailable }
        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
    }

    public func todaySnapshot() async throws -> HealthSnapshot {
        guard isAvailable else { throw HealthError.unavailable }
        async let steps = sumToday(.stepCount, unit: .count())
        async let active = sumToday(.activeEnergyBurned, unit: .kilocalorie())
        async let dist = sumToday(.distanceWalkingRunning, unit: .meter())
        async let weight = latest(.bodyMass, unit: .gramUnit(with: .kilo))
        async let height = latest(.height, unit: .meterUnit(with: .centi))
        return HealthSnapshot(
            steps: (try? await steps).map { Int($0) },
            activeEnergyKcal: try? await active,
            latestWeightKg: try? await weight,
            heightCm: try? await height,
            distanceMeters: try? await dist
        )
    }

    public func writeWeight(kg: Double, date: Date) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        let q = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: type, quantity: q, start: date, end: date)
        try await store.save(sample)
    }

    public func writeWater(ml: Int, date: Date) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        let q = HKQuantity(unit: .literUnit(with: .milli), doubleValue: Double(ml))
        let sample = HKQuantitySample(type: type, quantity: q, start: date, end: date)
        try await store.save(sample)
    }

    // MARK: - Requêtes internes

    private func sumToday(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        return try await withCheckedThrowingContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, stats, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(q)
        }
    }

    private func latest(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async throws -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error { cont.resume(throwing: error); return }
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                cont.resume(returning: value)
            }
            store.execute(q)
        }
    }
}
#endif

/// Mock pour le simulateur et les tests. Retourne des données plausibles.
public final class MockHealthKitService: HealthDataProviding {
    public var isAvailable: Bool
    public var snapshot: HealthSnapshot

    public init(isAvailable: Bool = true,
                snapshot: HealthSnapshot = HealthSnapshot(steps: 6500, activeEnergyKcal: 420,
                                                          latestWeightKg: 82.4, heightCm: 178,
                                                          distanceMeters: 4300)) {
        self.isAvailable = isAvailable
        self.snapshot = snapshot
    }

    public func requestReadAuthorization() async throws {
        if !isAvailable { throw HealthError.unavailable }
    }
    public func todaySnapshot() async throws -> HealthSnapshot { snapshot }
    public func writeWeight(kg: Double, date: Date) async throws {}
    public func writeWater(ml: Int, date: Date) async throws {}
}
