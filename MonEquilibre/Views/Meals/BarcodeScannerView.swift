import SwiftUI
#if canImport(VisionKit)
import VisionKit
#endif

/// Scanner de codes-barres basé sur VisionKit (DataScannerViewController).
/// Après le scan : recherche du produit, affichage, confirmation, correction possible.
struct BarcodeScannerView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let mealType: MealType

    @State private var scannedCode: String?
    @State private var lookupResult: FoodProductInfo?
    @State private var isLooking = false
    @State private var errorMessage: String?
    @State private var showManual = false

    var body: some View {
        NavigationStack {
            ZStack {
                #if canImport(VisionKit)
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerRepresentable(scannedCode: $scannedCode)
                        .ignoresSafeArea()
                } else {
                    scannerUnavailable
                }
                #else
                scannerUnavailable
                #endif

                VStack {
                    Spacer()
                    statusBar
                }
            }
            .navigationTitle("Scanner")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } } }
            .onChange(of: scannedCode) { _, code in
                if let code { Task { await lookup(code) } }
            }
            .sheet(item: $lookupResult) { info in
                AddFoodView(mealType: mealType, prefilled: info)
            }
            .sheet(isPresented: $showManual) {
                AddFoodView(mealType: mealType,
                            prefilled: FoodProductInfo(name: "Nouvel aliment", barcode: scannedCode,
                                                       facts: NutritionFacts(), source: .manual))
            }
        }
    }

    private var scannerUnavailable: some View {
        EmptyStateView(systemImage: "camera.metering.unknown",
                       title: "Caméra non disponible",
                       message: "Le scan n'est pas possible ici (simulateur ou autorisation refusée). Utilise la saisie manuelle.")
        .padding()
    }

    private var statusBar: some View {
        VStack(spacing: 8) {
            if isLooking { ProgressView("Recherche du produit…") }
            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.white)
                Button("Saisir manuellement") { showManual = true }.buttonStyle(.borderedProminent)
            }
            Button("Saisie manuelle") { showManual = true }
                .buttonStyle(.bordered).tint(.white)
        }
        .padding().background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    private func lookup(_ code: String) async {
        errorMessage = nil
        isLooking = true
        defer { isLooking = false }
        do {
            if let info = try await env.food.lookup(barcode: code) {
                lookupResult = info
            } else {
                errorMessage = "Produit introuvable."
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Produit introuvable."
        }
    }
}

#if canImport(VisionKit)
/// Pont UIKit → SwiftUI pour DataScannerViewController.
struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String?

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: DataScannerRepresentable
        init(_ parent: DataScannerRepresentable) { self.parent = parent }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                if case let .barcode(barcode) = item, let value = barcode.payloadStringValue {
                    parent.scannedCode = value
                    dataScanner.stopScanning()
                    break
                }
            }
        }
    }
}
#endif
