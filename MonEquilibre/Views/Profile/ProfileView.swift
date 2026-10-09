import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.modelContext) private var context

    @Query private var profiles: [UserProfile]
    @Query private var goals: [UserGoal]
    @Query private var settingsList: [AppSettings]
    @Query private var targets: [DailyNutritionTarget]

    @State private var showObjectiveConfirm = false
    @State private var pendingEstimate: NutritionEstimate?
    @State private var showDeleteConfirm = false

    // Accesseurs NON mutants : ils ne créent jamais d'objet pendant le rendu.
    // Les entités sont garanties par `ensureEntities()` dans `.task`.
    @State private var fallbackProfile = UserProfile()
    @State private var fallbackGoal = UserGoal()
    @State private var fallbackSettings = AppSettings()

    private var profile: UserProfile { profiles.first ?? fallbackProfile }
    private var goal: UserGoal { goals.first ?? fallbackGoal }
    private var settings: AppSettings { settingsList.first ?? fallbackSettings }

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                bodySection
                goalSection
                safetySection
                objectiveSection
                preferencesSection
                healthSection
                notificationsSection
                dataSection
                aboutSection
            }
            .navigationTitle("Profil")
            .task { ensureEntities() }
            .alert("Confirmer le nouvel objectif", isPresented: $showObjectiveConfirm, presenting: pendingEstimate) { est in
                Button("Confirmer") { applyEstimate(est) }
                Button("Annuler", role: .cancel) {}
            } message: { est in
                Text("Objectif proposé : \(est.targetRange.low)–\(est.targetRange.high) kcal / jour. C'est une estimation, tu peux la revoir à tout moment.")
            }
        }
    }

    // MARK: Sections

    private var identitySection: some View {
        Section("Identité") {
            TextField("Prénom ou pseudonyme", text: bind(\.displayName))
            DatePicker("Date de naissance",
                       selection: Binding(get: { profile.birthDate ?? Date() }, set: { profile.birthDate = $0; save() }),
                       displayedComponents: .date)
            if let age = profile.ageYears { Text("Âge : \(age) ans").foregroundStyle(.secondary) }
        }
    }

    private var bodySection: some View {
        Section("Corps") {
            numberRow("Taille (cm)", Binding(get: { profile.heightCm ?? 0 }, set: { profile.heightCm = $0; save() }))
            Picker("Sexe (pour le calcul)", selection: Binding(get: { profile.calculationSex }, set: { profile.calculationSex = $0; save() })) {
                Text("Homme").tag(CalculationSex.male)
                Text("Femme").tag(CalculationSex.female)
            }
            Text("Utilisé uniquement pour estimer le métabolisme.").font(.caption).foregroundStyle(.secondary)
            Picker("Activité quotidienne", selection: Binding(get: { profile.activityLevel }, set: { profile.activityLevel = $0; save() })) {
                Text("Sédentaire").tag(ActivityLevel.sedentary)
                Text("Légère").tag(ActivityLevel.light)
                Text("Modérée").tag(ActivityLevel.moderate)
                Text("Active").tag(ActivityLevel.active)
                Text("Très active").tag(ActivityLevel.veryActive)
            }
        }
    }

    private var goalSection: some View {
        Section("Objectif") {
            Picker("Objectif principal", selection: Binding(get: { goal.primaryGoal }, set: { goal.primaryGoal = $0; save() })) {
                Text("Perdre de la masse grasse").tag(PrimaryGoal.loseFat)
                Text("Maintien").tag(PrimaryGoal.maintain)
                Text("Recomposition").tag(PrimaryGoal.recomposition)
            }
            Picker("Rythme", selection: Binding(get: { goal.pace }, set: { goal.pace = $0; save() })) {
                Text("Prudent (~0,25 kg/sem)").tag(PaceLevel.gentle)
                Text("Modéré (~0,45 kg/sem)").tag(PaceLevel.moderate)
                Text("Soutenu (~0,60 kg/sem)").tag(PaceLevel.steady)
            }
            numberRow("Poids cible (kg, facultatif)", Binding(get: { goal.targetWeightKg ?? 0 }, set: { goal.targetWeightKg = $0 == 0 ? nil : $0; save() }))
        }
    }

    private var safetySection: some View {
        Section {
            ForEach(HealthSafetyFlag.allCases, id: \.self) { flag in
                Toggle(flagLabel(flag), isOn: Binding(
                    get: { profile.safetyFlags.contains(flag) },
                    set: { on in
                        var f = Set(profile.safetyFlags)
                        if on { f.insert(flag) } else { f.remove(flag) }
                        profile.safetyFlags = Array(f); save()
                    }))
            }
            if profile.blocksAutomaticDeficit {
                SafetyBanner(text: "Compte tenu de ta situation, aucun déficit calorique automatique n'est généré. Demande un avis professionnel avant de fixer un objectif.",
                             systemImage: "cross.case")
                .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
            }
        } header: {
            Text("Sécurité santé")
        } footer: {
            Text("Ces informations restent sur ton appareil et servent à te protéger.")
        }
    }

    private var objectiveSection: some View {
        Section("Objectif calorique estimé") {
            if let t = todayTarget {
                Text("\(t.caloriesLow)–\(t.caloriesHigh) kcal / jour").font(.headline)
                Text("Protéines \(t.proteinGrams) g · Glucides \(t.carbGrams) g · Lipides \(t.fatGrams) g")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Button {
                computeObjective()
            } label: { Label("Recalculer mon objectif", systemImage: "function") }
            .disabled(profile.heightCm == nil || profile.ageYears == nil)
            Text("Les résultats sont des estimations. Tu vois et confirmes toujours un changement.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var preferencesSection: some View {
        Section("Préférences") {
            Picker("Unités", selection: Binding(get: { settings.unitSystem }, set: { settings.unitSystem = $0; save() })) {
                Text("Métrique (kg, cm, ml)").tag(UnitSystem.metric)
                Text("Impérial").tag(UnitSystem.imperial)
            }
            Picker("Langue", selection: Binding(get: { settings.language }, set: { settings.language = $0; save() })) {
                Text("Système").tag(AppLanguage.system)
                Text("Français").tag(AppLanguage.french)
                Text("Polski").tag(AppLanguage.polish)
            }
            Text("Le changement de langue s'applique au redémarrage de l'application.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var healthSection: some View {
        Section("Apple Santé") {
            Toggle("Activer Apple Santé", isOn: Binding(
                get: { settings.healthKitEnabled },
                set: { on in
                    settings.healthKitEnabled = on; save()
                    if on { Task { try? await env.health.requestReadAuthorization() } }
                }))
            Text("Lecture : poids, taille, pas, calories actives, distance. Écriture facultative : poids, eau. L'app fonctionne aussi sans Apple Santé.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var notificationsSection: some View {
        Section("Notifications (facultatives)") {
            notifToggle("Rappel des repas", \.notifyLogMeals, .logMeals, 12, 30)
            notifToggle("Boire de l'eau", \.notifyDrinkWater, .drinkWater, 15, 0)
            notifToggle("Se peser", \.notifyWeighIn, .weighIn, 7, 30)
            notifToggle("Séance du jour", \.notifyWorkout, .workout, 18, 0)
            notifToggle("Programme de la semaine", \.notifyWeeklyPlan, .weeklyPlan, 9, 0)
            notifToggle("Pause active", \.notifyActiveBreak, .activeBreak, 16, 0)
            notifToggle("Bilan hebdomadaire", \.notifyWeeklyReview, .weeklyReview, 19, 0)
        }
    }

    private var dataSection: some View {
        Section("Données") {
            Button { DemoData.seed(into: context) } label: { Label("Charger les données de démonstration", systemImage: "wand.and.stars") }
            NavigationLink { WeeklyReviewView() } label: { Label("Bilan hebdomadaire", systemImage: "calendar.badge.clock") }
            Button(role: .destructive) { showDeleteConfirm = true } label: { Label("Supprimer toutes mes données", systemImage: "trash") }
                .confirmationDialog("Cette action est définitive.", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                    Button("Tout supprimer", role: .destructive) { DemoData.clearAll(context: context) }
                }
        }
    }

    private var aboutSection: some View {
        Section("À propos") {
            LabeledContent("Version", value: appVersion)
            SafetyBanner(text: "Mon Équilibre fournit des estimations générales et ne remplace pas un médecin, un diététicien ou un kinésithérapeute.")
                .listRowInsets(EdgeInsets()).listRowBackground(Color.clear)
            Text("Confidentialité : tes données restent stockées localement sur ton appareil. Aucune donnée de santé n'est envoyée automatiquement vers un serveur.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Helpers

    private var todayTarget: DailyNutritionTarget? {
        targets.first { Calendar.current.isDateInToday($0.date) } ?? targets.sorted { $0.date > $1.date }.first
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return v
    }

    private func computeObjective() {
        guard let height = profile.heightCm, let age = profile.ageYears else { return }
        // Situation de sécurité : pas de déficit automatique → objectif de maintien.
        let effectiveGoal: PrimaryGoal = profile.blocksAutomaticDeficit ? .maintain : goal.primaryGoal
        Task {
            let active = try? await env.health.todaySnapshot().activeEnergyKcal
            let weight = latestWeight() ?? 80
            let est = env.nutrition.estimate(weightKg: weight, heightCm: height, ageYears: age,
                                             sex: profile.calculationSex, activity: profile.activityLevel,
                                             goal: effectiveGoal, pace: goal.pace, activeEnergyKcal: active)
            await MainActor.run { pendingEstimate = est; showObjectiveConfirm = true }
        }
    }

    private func latestWeight() -> Double? {
        (try? context.fetch(FetchDescriptor<WeightEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])))?.first?.kg
    }

    private func applyEstimate(_ est: NutritionEstimate) {
        let today = Calendar.current.startOfDay(for: Date())
        // Remplace l'objectif du jour s'il existe.
        for t in targets where Calendar.current.isDate(t.date, inSameDayAs: today) { context.delete(t) }
        context.insert(DailyNutritionTarget(date: today, range: est.targetRange,
                                            proteinGrams: est.proteinGrams, carbGrams: est.carbGrams,
                                            fatGrams: est.fatGrams, fiberGramsMin: est.fiberGramsMin,
                                            isConfirmedByUser: true))
        goal.acknowledgedEstimateDisclaimer = true
        save()
    }

    private func notifToggle(_ title: String, _ key: ReferenceWritableKeyPath<AppSettings, Bool>, _ kind: ReminderKind, _ h: Int, _ m: Int) -> some View {
        Toggle(title, isOn: Binding(
            get: { settings[keyPath: key] },
            set: { on in
                settings[keyPath: key] = on; save()
                Task {
                    if on {
                        _ = await env.notifications.requestAuthorization()
                        await env.notifications.schedule(kind, hour: h, minute: m)
                    } else {
                        await env.notifications.cancel(kind)
                    }
                }
            }))
    }

    private func bind(_ key: ReferenceWritableKeyPath<UserProfile, String>) -> Binding<String> {
        Binding(get: { profile[keyPath: key] }, set: { profile[keyPath: key] = $0; save() })
    }

    private func numberRow(_ title: String, _ value: Binding<Double>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", value: value, format: .number).keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing).frame(width: 90)
        }
    }

    private func flagLabel(_ f: HealthSafetyFlag) -> String {
        switch f {
        case .under18: return "J'ai moins de 18 ans"
        case .pregnantOrBreastfeeding: return "Enceinte ou allaitante"
        case .eatingDisorderHistory: return "Antécédent de trouble alimentaire"
        case .chronicIllness: return "Maladie chronique importante"
        case .weightAffectingMedication: return "Traitement influençant le poids/appétit"
        case .veryLowWeight: return "Poids très faible"
        case .recentUnintendedWeightLoss: return "Perte de poids récente involontaire"
        case .injuryOrPain: return "Blessure ou douleur importante"
        case .heartCondition: return "Maladie cardiaque"
        case .medicalExerciseContraindication: return "Contre-indication médicale à l'exercice"
        }
    }

    private func save() {
        profile.updatedAt = Date()
        try? context.save()
    }

    /// Garantit qu'un profil, un objectif et des réglages existent (exécuté une fois).
    private func ensureEntities() {
        if profiles.isEmpty { context.insert(UserProfile()) }
        if goals.isEmpty { context.insert(UserGoal()) }
        if settingsList.isEmpty { context.insert(AppSettings()) }
        try? context.save()
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppEnvironment.preview())
        .modelContainer(for: [UserProfile.self, UserGoal.self, AppSettings.self, DailyNutritionTarget.self, WeightEntry.self], inMemory: true)
}
