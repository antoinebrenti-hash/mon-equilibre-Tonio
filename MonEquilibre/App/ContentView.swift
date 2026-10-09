import SwiftUI
import SwiftData

/// Barre de navigation inférieure à cinq onglets.
struct ContentView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Query private var settings: [AppSettings]
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Accueil", systemImage: "house.fill") }

            MealsView()
                .tabItem { Label("Repas", systemImage: "fork.knife") }

            ProgressDashboardView()
                .tabItem { Label("Progrès", systemImage: "chart.line.uptrend.xyaxis") }

            WorkoutsView()
                .tabItem { Label("Exercices", systemImage: "figure.strengthtraining.traditional") }

            ProfileView()
                .tabItem { Label("Profil", systemImage: "person.crop.circle") }
        }
        .task { await ensureSettings() }
    }

    /// S'assure qu'un objet AppSettings existe au premier lancement.
    private func ensureSettings() async {
        if settings.isEmpty {
            context.insert(AppSettings())
            try? context.save()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppEnvironment.preview())
        .modelContainer(for: [AppSettings.self, UserProfile.self], inMemory: true)
}
