import Foundation

/// Bibliothèque d'exercices de référence (donnée statique, non persistée).
/// Chaque exercice reste équilibré et accompagné de consignes de sécurité.
public enum ExerciseLibrary {

    public static let all: [Exercise] = chest + backPosture + shoulders + arms + legs + core + mobility + cardio

    // MARK: Pectoraux
    static let chest: [Exercise] = [
        Exercise(id: "pushup_wall", name: "Pompes contre un mur",
                 primaryMuscles: [.chest], secondaryMuscles: [.shoulders, .arms],
                 allowedSettings: [.homeNoEquipment, .homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["Mains au mur, largeur d'épaules.", "Corps gainé, descends la poitrine vers le mur.", "Pousse pour revenir."],
                 commonMistakes: ["Cambrer le bas du dos.", "Décoller les talons excessivement."],
                 easierVariant: "Se rapprocher du mur.", harderVariant: "Pompes inclinées sur une table.",
                 sfSymbol: "figure.strengthtraining.functional"),
        Exercise(id: "pushup_incline", name: "Pompes inclinées",
                 primaryMuscles: [.chest], secondaryMuscles: [.shoulders, .arms, .core],
                 allowedSettings: [.homeNoEquipment, .gym], level: .beginner,
                 instructions: ["Mains sur un support stable (table, banc).", "Gaine le tronc.", "Descends contrôlé, pousse."],
                 commonMistakes: ["Coudes trop écartés."], easierVariant: "Support plus haut.", harderVariant: "Pompes classiques au sol."),
        Exercise(id: "pushup_standard", name: "Pompes classiques",
                 primaryMuscles: [.chest], secondaryMuscles: [.shoulders, .arms, .core],
                 allowedSettings: [.homeNoEquipment, .gym], level: .intermediate,
                 instructions: ["Corps aligné, mains largeur d'épaules.", "Descends jusqu'à ~90° aux coudes.", "Pousse en gainant."],
                 commonMistakes: ["Bassin qui s'affaisse.", "Amplitude partielle."],
                 easierVariant: "Pompes sur les genoux.", harderVariant: "Pompes pieds surélevés."),
        Exercise(id: "db_bench", name: "Développé couché avec haltères",
                 primaryMuscles: [.chest], secondaryMuscles: [.shoulders, .arms],
                 requiredEquipment: ["haltères", "banc"], allowedSettings: [.homeMinimalEquipment, .gym], level: .intermediate,
                 instructions: ["Allongé sur le banc, haltères au niveau de la poitrine.", "Pousse vers le haut sans verrouiller brutalement.", "Redescends contrôlé."],
                 commonMistakes: ["Décoller la tête ou les fesses du banc."], easierVariant: "Charges plus légères.", harderVariant: "Développé incliné."),
        Exercise(id: "db_incline", name: "Développé incliné avec haltères",
                 primaryMuscles: [.chest], secondaryMuscles: [.shoulders, .arms],
                 requiredEquipment: ["haltères", "banc inclinable"], allowedSettings: [.homeMinimalEquipment, .gym], level: .intermediate,
                 instructions: ["Banc à ~30°.", "Pousse les haltères au-dessus du haut de la poitrine."],
                 commonMistakes: ["Inclinaison trop forte (sollicite trop les épaules)."], easierVariant: "Développé à plat.", harderVariant: "Tempo plus lent."),
        Exercise(id: "db_fly", name: "Écartés avec haltères ou poulie",
                 primaryMuscles: [.chest], secondaryMuscles: [.shoulders],
                 requiredEquipment: ["haltères ou poulie", "banc"], allowedSettings: [.homeMinimalEquipment, .gym], level: .intermediate,
                 instructions: ["Bras légèrement fléchis, ouvre en arc de cercle.", "Ramène sans choquer les haltères."],
                 commonMistakes: ["Coudes trop tendus."], warning: "Charge modérée pour protéger l'épaule.", easierVariant: "Amplitude réduite.", harderVariant: "Tempo contrôlé 3 s."),
        Exercise(id: "chest_press_machine", name: "Chest press (machine)",
                 primaryMuscles: [.chest], secondaryMuscles: [.shoulders, .arms],
                 requiredEquipment: ["machine"], allowedSettings: [.gym], level: .beginner,
                 instructions: ["Règle le siège, poignées au niveau de la poitrine.", "Pousse sans verrouiller les coudes."],
                 commonMistakes: ["Amplitude trop courte."], easierVariant: "Charge plus légère.", harderVariant: "Unilatéral.")
    ]

    // MARK: Dos & posture
    static let backPosture: [Exercise] = [
        Exercise(id: "row_horizontal", name: "Tirage horizontal",
                 primaryMuscles: [.back], secondaryMuscles: [.arms, .shoulders],
                 requiredEquipment: ["élastique ou poulie basse"], allowedSettings: [.homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["Tire les coudes vers l'arrière, serre les omoplates.", "Contrôle le retour."],
                 commonMistakes: ["Arrondir le dos."], easierVariant: "Moins de tension.", harderVariant: "Tempo plus lent.",
                 sfSymbol: "figure.rower"),
        Exercise(id: "db_row", name: "Rowing avec haltère",
                 primaryMuscles: [.back], secondaryMuscles: [.arms],
                 requiredEquipment: ["haltère", "appui"], allowedSettings: [.homeMinimalEquipment, .gym], level: .intermediate,
                 instructions: ["Un genou et une main en appui.", "Tire l'haltère vers la hanche, coude près du corps."],
                 commonMistakes: ["Tourner le buste.", "Tirer avec le bras seulement."], easierVariant: "Charge plus légère.", harderVariant: "Pause en haut."),
        Exercise(id: "lat_pulldown", name: "Tirage vertical",
                 primaryMuscles: [.back], secondaryMuscles: [.arms],
                 requiredEquipment: ["poulie haute"], allowedSettings: [.gym], level: .beginner,
                 instructions: ["Tire la barre vers le haut de la poitrine.", "Descends les omoplates."],
                 commonMistakes: ["Se pencher trop en arrière."], easierVariant: "Charge modérée.", harderVariant: "Prise serrée."),
        Exercise(id: "face_pull", name: "Face pull",
                 primaryMuscles: [.shoulders, .back], secondaryMuscles: [.back],
                 requiredEquipment: ["élastique ou poulie"], allowedSettings: [.homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["Tire vers le visage, coudes hauts.", "Ouvre les épaules, serre les omoplates."],
                 commonMistakes: ["Charge trop lourde."], easierVariant: "Moins de tension.", harderVariant: "Pause 2 s.",
                 sfSymbol: "figure.strengthtraining.functional"),
        Exercise(id: "reverse_fly", name: "Reverse fly (oiseau)",
                 primaryMuscles: [.shoulders], secondaryMuscles: [.back],
                 requiredEquipment: ["haltères légers ou élastique"], allowedSettings: [.homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["Buste incliné, ouvre les bras sur les côtés.", "Serre les omoplates."],
                 commonMistakes: ["Monter les épaules vers les oreilles."], easierVariant: "Sans charge.", harderVariant: "Tempo lent."),
        Exercise(id: "bird_dog", name: "Bird-dog",
                 primaryMuscles: [.core, .back], secondaryMuscles: [.glutes],
                 allowedSettings: [.homeNoEquipment, .homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["À quatre pattes, tends bras et jambe opposés.", "Gaine, garde le bassin stable."],
                 commonMistakes: ["Cambrer le bas du dos."], easierVariant: "Bras seul ou jambe seule.", harderVariant: "Pause 3 s."),
        Exercise(id: "thoracic_ext", name: "Extensions thoraciques contrôlées",
                 primaryMuscles: [.mobility, .back], secondaryMuscles: [],
                 allowedSettings: [.homeNoEquipment, .gym], level: .beginner,
                 instructions: ["Assis ou sur un rouleau, ouvre le haut du dos en douceur."],
                 commonMistakes: ["Forcer sur le bas du dos."], warning: "Mouvement doux, sans à-coups.", sfSymbol: "figure.flexibility"),
        Exercise(id: "shoulder_mobility", name: "Mobilité des épaules",
                 primaryMuscles: [.mobility, .shoulders], secondaryMuscles: [],
                 requiredEquipment: ["élastique ou bâton"], allowedSettings: [.homeNoEquipment, .homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["Passe le bâton/élastique au-dessus de la tête, bras tendus.", "Amplitude progressive."],
                 commonMistakes: ["Prise trop serrée."], sfSymbol: "figure.flexibility"),
        Exercise(id: "plank", name: "Gainage adapté (planche)",
                 primaryMuscles: [.core], secondaryMuscles: [.shoulders, .back],
                 allowedSettings: [.homeNoEquipment, .homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["Appui avant-bras, corps aligné.", "Gaine sans bloquer la respiration."],
                 commonMistakes: ["Bassin trop haut ou trop bas."], easierVariant: "Planche sur les genoux.", harderVariant: "Planche avec levée de jambe."),
        Exercise(id: "trunk_stab", name: "Stabilisation du tronc (dead bug)",
                 primaryMuscles: [.core], secondaryMuscles: [],
                 allowedSettings: [.homeNoEquipment, .gym], level: .beginner,
                 instructions: ["Sur le dos, descends bras et jambe opposés.", "Garde le bas du dos au sol."],
                 commonMistakes: ["Décoller le bas du dos."], easierVariant: "Jambes seules.", harderVariant: "Amplitude complète lente.")
    ]

    // MARK: Épaules
    static let shoulders: [Exercise] = [
        Exercise(id: "db_shoulder_press", name: "Développé épaules haltères",
                 primaryMuscles: [.shoulders], secondaryMuscles: [.arms],
                 requiredEquipment: ["haltères"], allowedSettings: [.homeMinimalEquipment, .gym], level: .intermediate,
                 instructions: ["Pousse les haltères au-dessus de la tête.", "Gaine le tronc, ne cambre pas."],
                 commonMistakes: ["Cambrer le bas du dos."], easierVariant: "Assis avec dossier.", harderVariant: "Debout unilatéral."),
        Exercise(id: "lateral_raise", name: "Élévations latérales",
                 primaryMuscles: [.shoulders], secondaryMuscles: [],
                 requiredEquipment: ["haltères légers"], allowedSettings: [.homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["Monte les bras sur les côtés jusqu'à l'horizontale."],
                 commonMistakes: ["Balancer le corps."], easierVariant: "Sans charge.", harderVariant: "Tempo lent.")
    ]

    // MARK: Bras
    static let arms: [Exercise] = [
        Exercise(id: "db_curl", name: "Curl biceps haltères",
                 primaryMuscles: [.arms], secondaryMuscles: [],
                 requiredEquipment: ["haltères"], allowedSettings: [.homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["Fléchis les coudes, monte les haltères.", "Contrôle la descente."],
                 commonMistakes: ["Balancer le dos."], easierVariant: "Charge légère.", harderVariant: "Tempo 3 s."),
        Exercise(id: "triceps_dip_bench", name: "Dips sur banc (triceps)",
                 primaryMuscles: [.arms], secondaryMuscles: [.chest, .shoulders],
                 requiredEquipment: ["banc/chaise"], allowedSettings: [.homeNoEquipment, .gym], level: .beginner,
                 instructions: ["Mains sur le banc, descends les coudes vers l'arrière."],
                 commonMistakes: ["Épaules qui remontent."], warning: "Amplitude modérée si l'épaule est sensible.", easierVariant: "Pieds proches.", harderVariant: "Pieds éloignés.")
    ]

    // MARK: Jambes & fessiers
    static let legs: [Exercise] = [
        Exercise(id: "bodyweight_squat", name: "Squat au poids du corps",
                 primaryMuscles: [.legs, .glutes], secondaryMuscles: [.core],
                 allowedSettings: [.homeNoEquipment, .homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["Descends les hanches vers l'arrière, genoux dans l'axe des pieds."],
                 commonMistakes: ["Genoux qui rentrent.", "Talons qui décollent."], easierVariant: "S'aider d'un appui.", harderVariant: "Squat sauté (si sans douleur)."),
        Exercise(id: "lunge", name: "Fentes",
                 primaryMuscles: [.legs, .glutes], secondaryMuscles: [.core],
                 allowedSettings: [.homeNoEquipment, .homeMinimalEquipment, .gym], level: .intermediate,
                 instructions: ["Grand pas en avant, descends le genou arrière.", "Reste stable."],
                 commonMistakes: ["Genou avant qui dépasse trop."], easierVariant: "Amplitude réduite.", harderVariant: "Fentes avec haltères."),
        Exercise(id: "hip_thrust", name: "Hip thrust (fessiers)",
                 primaryMuscles: [.glutes], secondaryMuscles: [.legs, .core],
                 requiredEquipment: ["banc (optionnel)"], allowedSettings: [.homeNoEquipment, .homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["Épaules en appui, monte le bassin, serre les fessiers."],
                 commonMistakes: ["Cambrer au lieu de serrer les fessiers."], easierVariant: "Pont fessier au sol.", harderVariant: "Avec charge sur les hanches."),
        Exercise(id: "calf_raise", name: "Extensions mollets",
                 primaryMuscles: [.legs], secondaryMuscles: [],
                 allowedSettings: [.homeNoEquipment, .homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["Monte sur la pointe des pieds, contrôle la descente."],
                 commonMistakes: ["Amplitude trop courte."], easierVariant: "Deux jambes.", harderVariant: "Une jambe.")
    ]

    // MARK: Abdominaux / ceinture
    static let core: [Exercise] = [
        Exercise(id: "side_plank", name: "Planche latérale",
                 primaryMuscles: [.core], secondaryMuscles: [.shoulders],
                 allowedSettings: [.homeNoEquipment, .gym], level: .intermediate,
                 instructions: ["Appui sur un avant-bras, corps aligné.", "Gaine les obliques."],
                 commonMistakes: ["Bassin qui tombe."], easierVariant: "Genoux au sol.", harderVariant: "Lever la jambe."),
        Exercise(id: "leg_raise", name: "Relevés de jambes",
                 primaryMuscles: [.core], secondaryMuscles: [],
                 allowedSettings: [.homeNoEquipment, .gym], level: .intermediate,
                 instructions: ["Sur le dos, monte les jambes tendues, garde le bas du dos plaqué."],
                 commonMistakes: ["Décoller le bas du dos."], easierVariant: "Genoux fléchis.", harderVariant: "Jambes tendues lentes.")
    ]

    // MARK: Mobilité
    static let mobility: [Exercise] = [
        Exercise(id: "mobility_flow", name: "Routine de mobilité",
                 primaryMuscles: [.mobility], secondaryMuscles: [],
                 allowedSettings: [.homeNoEquipment, .homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["Enchaîne hanches, épaules et colonne en douceur.", "Respire, sans forcer."],
                 commonMistakes: ["Aller trop vite."], sfSymbol: "figure.flexibility"),
        Exercise(id: "cat_cow", name: "Chat-vache (mobilité dos)",
                 primaryMuscles: [.mobility, .back], secondaryMuscles: [.core],
                 allowedSettings: [.homeNoEquipment, .gym], level: .beginner,
                 instructions: ["À quatre pattes, alterne dos rond et dos creux en douceur."],
                 commonMistakes: ["Mouvement brusque."], sfSymbol: "figure.flexibility")
    ]

    // MARK: Cardio
    static let cardio: [Exercise] = [
        Exercise(id: "brisk_walk", name: "Marche rapide",
                 primaryMuscles: [.cardio], secondaryMuscles: [.legs],
                 allowedSettings: [.homeNoEquipment, .homeMinimalEquipment, .gym], level: .beginner,
                 instructions: ["Marche soutenue, respiration régulière."],
                 commonMistakes: ["Allure trop faible pour l'objectif visé."], sfSymbol: "figure.walk"),
        Exercise(id: "low_impact_cardio", name: "Cardio léger sur place",
                 primaryMuscles: [.cardio], secondaryMuscles: [.legs],
                 allowedSettings: [.homeNoEquipment, .gym], level: .beginner,
                 instructions: ["Montées de genoux modérées, talons-fesses, pas chassés."],
                 commonMistakes: ["Impacts trop forts si articulations sensibles."],
                 warning: "Arrête en cas de douleur, d'essoufflement anormal ou de vertige.", sfSymbol: "figure.run")
    ]
}
