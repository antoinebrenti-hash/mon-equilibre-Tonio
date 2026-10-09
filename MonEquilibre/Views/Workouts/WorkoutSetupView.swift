import SwiftUI
import SwiftData

/// Configuration puis génération d'un programme hebdomadaire équilibré.
struct WorkoutSetupView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selectedGoals: Set<TrainingGoal> = [.generalFitness]
    @State private var level: TrainingLevel = .beginner
    @State private var setting: TrainingSetting = .homeNoEquipment
    @State private var daysPerWeek = 3
    @State private var sessionMinutes = 45

    var body: some View {
        NavigationStack {
            Form {
                Section("Objectifs") {
                    ForEach(TrainingGoal.allCases, id: \.self) { goal in
                        Toggle(goalLabel(goal), isOn: Binding(
                            get: { selectedGoals.contains(goal) },
                            set: { on in if on { selectedGoals.insert(goal) } else { selectedGoals.remove(goal) } }
                        ))
                    }
                }
                Section("Niveau") {
                    Picker("Niveau", selection: $level) {
                        Text("Débutant").tag(TrainingLevel.beginner)
                        Text("Intermédiaire").tag(TrainingLevel.intermediate)
                        Text("Avancé").tag(TrainingLevel.advanced)
                    }.pickerStyle(.segmented)
                }
                Section("Lieu et matériel") {
                    Picker("Lieu", selection: $setting) {
                        Text("Maison, sans matériel").tag(TrainingSetting.homeNoEquipment)
                        Text("Maison, élastiques/haltères").tag(TrainingSetting.homeMinimalEquipment)
                        Text("Salle de sport").tag(TrainingSetting.gym)
                    }
                }
                Section("Disponibilité") {
                    Stepper("Jours par semaine : \(daysPerWeek)", value: $daysPerWeek, in: 1...6)
                    Stepper("Durée par séance : \(sessionMinutes) min", value: $sessionMinutes, in: 15...90, step: 5)
                }
                Section {
                    Text("Même avec un objectif ciblé (pectoraux, dos…), le programme reste global et équilibré, avec au moins un jour de récupération entre deux séances intenses du même groupe.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Nouveau programme")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Générer") { generate() } }
            }
        }
    }

    private func goalLabel(_ g: TrainingGoal) -> String {
        switch g {
        case .loseFat: return "Perdre de la masse grasse"
        case .chest: return "Développer les pectoraux"
        case .back: return "Renforcer le dos"
        case .posture: return "Améliorer la posture"
        case .shoulders: return "Renforcer les épaules"
        case .arms: return "Développer les bras"
        case .abs: return "Renforcer les abdominaux"
        case .legs: return "Renforcer les jambes"
        case .mobility: return "Améliorer la mobilité"
        case .generalFitness: return "Condition physique générale"
        }
    }

    private func generate() {
        let goals = Array(selectedGoals.isEmpty ? [.generalFitness] : selectedGoals)
        let generated = env.planner.generateWeeklyPlan(
            goals: goals, level: level, setting: setting,
            daysPerWeek: daysPerWeek, sessionMinutes: sessionMinutes,
            library: env.exerciseLibrary)

        // Désactive les anciens plans.
        if let existing = try? context.fetch(FetchDescriptor<WorkoutPlan>()) {
            existing.forEach { $0.isActive = false }
        }

        let plan = WorkoutPlan(name: "Programme \(daysPerWeek) j/sem",
                               level: level, setting: setting, goals: goals,
                               daysPerWeek: daysPerWeek, sessionMinutes: sessionMinutes,
                               isActive: true, notes: generated.notes)

        for (index, gDay) in generated.days.enumerated() {
            let day = WorkoutDay(weekdayIndex: index, title: gDay.title, isRestDay: gDay.isRestDay)
            for (order, spec) in gDay.exercises.enumerated() {
                let name = env.exerciseLibrary.first { $0.id == spec.exerciseID }?.name ?? spec.exerciseID
                day.plannedExercises.append(PlannedExercise(
                    exerciseID: spec.exerciseID, exerciseName: name, block: spec.block,
                    sets: spec.sets, reps: spec.reps, restSeconds: spec.restSeconds, orderIndex: order))
            }
            plan.days.append(day)
        }

        context.insert(plan)
        try? context.save()
        dismiss()
    }
}

#Preview {
    WorkoutSetupView()
        .environmentObject(AppEnvironment.preview())
        .modelContainer(for: [WorkoutPlan.self, WorkoutDay.self, PlannedExercise.self], inMemory: true)
}
