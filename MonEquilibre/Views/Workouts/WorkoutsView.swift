import SwiftUI
import SwiftData

struct WorkoutsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    @State private var showSetup = false

    private var activePlan: WorkoutPlan? { plans.first { $0.isActive } ?? plans.first }
    private let weekdayNames = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]

    var body: some View {
        NavigationStack {
            Group {
                if let plan = activePlan {
                    planList(plan)
                } else {
                    EmptyStateView(systemImage: "figure.strengthtraining.traditional",
                                   title: "Aucun programme",
                                   message: "Crée un programme adapté à tes objectifs et à ton matériel.")
                    .padding()
                }
            }
            .navigationTitle("Exercices")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSetup = true } label: { Label("Nouveau", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $showSetup) { WorkoutSetupView() }
        }
    }

    private func planList(_ plan: WorkoutPlan) -> some View {
        List {
            Section {
                ForEach(plan.notes, id: \.self) { note in
                    SafetyBanner(text: note).listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
                }
            }
            Section(plan.name) {
                ForEach(plan.days.sorted { $0.weekdayIndex < $1.weekdayIndex }) { day in
                    NavigationLink {
                        WorkoutDayDetailView(day: day)
                    } label: {
                        HStack {
                            Text(weekdayNames[safe: day.weekdayIndex] ?? "—").font(.caption).bold()
                                .frame(width: 38)
                            VStack(alignment: .leading) {
                                Text(day.title)
                                if !day.isRestDay {
                                    Text("\(day.plannedExercises.count) exercices").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if day.isRestDay { Image(systemName: "bed.double").foregroundStyle(.secondary) }
                        }
                    }
                }
            }
            Section {
                SafetyBanner(text: "Arrête immédiatement en cas de douleur aiguë, douleur thoracique, malaise, vertige ou essoufflement anormal, et demande un avis médical.",
                             systemImage: "exclamationmark.triangle")
                .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
            }
        }
    }
}

/// Détail d'une journée : liste des exercices avec leurs consignes.
struct WorkoutDayDetailView: View {
    @EnvironmentObject private var env: AppEnvironment
    let day: WorkoutDay

    private func exercise(_ id: String) -> Exercise? { env.exerciseLibrary.first { $0.id == id } }

    var body: some View {
        List {
            if day.isRestDay {
                Text("Journée de récupération. Mobilité douce et marche possibles.")
            }
            ForEach(day.plannedExercises.sorted { $0.orderIndex < $1.orderIndex }) { pe in
                NavigationLink {
                    if let ex = exercise(pe.exerciseID) { ExerciseDetailView(exercise: ex, planned: pe) }
                } label: {
                    HStack {
                        Image(systemName: exercise(pe.exerciseID)?.sfSymbol ?? "figure.strengthtraining.traditional")
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text(pe.exerciseName)
                            Text(blockLabel(pe.block) + " · \(pe.sets) × \(pe.reps)" + (pe.restSeconds > 0 ? " · repos \(pe.restSeconds)s" : ""))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(day.title)
    }

    private func blockLabel(_ b: BlockType) -> String {
        switch b {
        case .warmup: return "Échauffement"
        case .main: return "Principal"
        case .accessory: return "Complémentaire"
        case .cooldown: return "Retour au calme"
        case .mobility: return "Mobilité"
        }
    }
}

/// Détail d'un exercice de la bibliothèque.
struct ExerciseDetailView: View {
    let exercise: Exercise
    var planned: PlannedExercise?

    var body: some View {
        List {
            Section {
                Label(exercise.name, systemImage: exercise.sfSymbol).font(.headline)
                Text("Muscles principaux : " + exercise.primaryMuscles.map(\.rawValue).joined(separator: ", "))
                    .font(.caption).foregroundStyle(.secondary)
                if !exercise.secondaryMuscles.isEmpty {
                    Text("Secondaires : " + exercise.secondaryMuscles.map(\.rawValue).joined(separator: ", "))
                        .font(.caption).foregroundStyle(.secondary)
                }
                if !exercise.requiredEquipment.isEmpty {
                    Text("Matériel : " + exercise.requiredEquipment.joined(separator: ", ")).font(.caption)
                }
            }
            if let planned {
                Section("Prescription") {
                    Text("\(planned.sets) séries × \(planned.reps)")
                    if planned.restSeconds > 0 { Text("Repos : \(planned.restSeconds) s") }
                }
            }
            if !exercise.instructions.isEmpty {
                Section("Consignes d'exécution") {
                    ForEach(exercise.instructions, id: \.self) { Text("• \($0)") }
                }
            }
            if !exercise.commonMistakes.isEmpty {
                Section("Erreurs fréquentes") {
                    ForEach(exercise.commonMistakes, id: \.self) { Text("• \($0)") }
                }
            }
            Section("Variantes") {
                if let e = exercise.easierVariant { Label(e, systemImage: "arrow.down.circle") }
                if let h = exercise.harderVariant { Label(h, systemImage: "arrow.up.circle") }
            }
            if let warning = exercise.warning {
                Section { SafetyBanner(text: warning, systemImage: "exclamationmark.triangle").listRowInsets(EdgeInsets()) }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}

#Preview {
    WorkoutsView()
        .environmentObject(AppEnvironment.preview())
        .modelContainer(for: [WorkoutPlan.self, WorkoutDay.self, PlannedExercise.self], inMemory: true)
}
