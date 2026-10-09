import SwiftUI

/// Carte de statistique réutilisable.
struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var systemImage: String = "circle"
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption).foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
            Text(value).font(.title2).bold().foregroundStyle(tint)
            if let subtitle {
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

/// Jauge circulaire pour les calories / macros.
struct RingGauge: View {
    let progress: Double         // 0...1 (peut dépasser 1)
    let label: String
    let centerText: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(tint.opacity(0.15), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: min(1, max(0, progress)))
                    .stroke(tint, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                Text(centerText).font(.title3).bold().monospacedDigit()
            }
            .frame(width: 120, height: 120)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) : \(centerText)")
    }
}

/// Barre de macronutriment.
struct MacroBar: View {
    let name: String
    let current: Int
    let target: Int
    var tint: Color = .accentColor

    private var fraction: Double { target > 0 ? min(1, Double(current) / Double(target)) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name).font(.caption)
                Spacer()
                Text("\(current) / \(target) g").font(.caption).monospacedDigit().foregroundStyle(.secondary)
            }
            ProgressView(value: fraction).tint(tint)
        }
    }
}

/// Message de sécurité / avertissement, ton neutre.
struct SafetyBanner: View {
    let text: String
    var systemImage: String = "info.circle"
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage).foregroundStyle(.blue)
            Text(text).font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Bouton d'ajout rapide.
struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage).font(.title3)
                Text(title).font(.caption2)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel(title)
    }
}

/// État vide générique.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    var message: String? = nil
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage).font(.largeTitle).foregroundStyle(.secondary)
            Text(title).font(.headline)
            if let message { Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center) }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }
}

/// Sélecteur de période pour les graphiques.
enum ChartRange: String, CaseIterable, Identifiable {
    case week = "7 j", month = "30 j", quarter = "3 m", half = "6 m", year = "1 an", all = "Tout"
    var id: String { rawValue }
    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .half: return 180
        case .year: return 365
        case .all: return nil
        }
    }
}

struct RangePicker: View {
    @Binding var selection: ChartRange
    var body: some View {
        Picker("Période", selection: $selection) {
            ForEach(ChartRange.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
    }
}
