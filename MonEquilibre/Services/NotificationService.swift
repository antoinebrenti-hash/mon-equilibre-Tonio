import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

/// Identifiants stables des rappels (activables/désactivables individuellement).
public enum ReminderKind: String, CaseIterable, Sendable {
    case logMeals, drinkWater, weighIn, workout, weeklyPlan, activeBreak, weeklyReview

    /// Message neutre, jamais culpabilisant.
    public var body: String {
        switch self {
        case .logMeals:     return "Un petit moment pour noter tes repas si tu le souhaites."
        case .drinkWater:   return "Pense à boire un verre d'eau."
        case .weighIn:      return "Tu peux te peser aujourd'hui si tu veux suivre ta tendance."
        case .workout:      return "Ta séance du jour est prête quand tu l'es."
        case .weeklyPlan:   return "Envie de préparer ton programme de la semaine ?"
        case .activeBreak:  return "Une petite pause active pourrait faire du bien."
        case .weeklyReview: return "Ton bilan de la semaine est disponible."
        }
    }
}

public protocol NotificationScheduling {
    func requestAuthorization() async -> Bool
    func schedule(_ kind: ReminderKind, hour: Int, minute: Int) async
    func cancel(_ kind: ReminderKind) async
    func cancelAll() async
}

#if canImport(UserNotifications)
public final class NotificationService: NotificationScheduling {
    private let center = UNUserNotificationCenter.current()
    public init() {}

    public func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    public func schedule(_ kind: ReminderKind, hour: Int, minute: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Mon Équilibre"
        content.body = kind.body
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: kind.rawValue, content: content, trigger: trigger)
        try? await center.add(request)
    }

    public func cancel(_ kind: ReminderKind) async {
        center.removePendingNotificationRequests(withIdentifiers: [kind.rawValue])
    }

    public func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }
}
#endif

/// Mock pour tests / simulateur.
public final class MockNotificationService: NotificationScheduling {
    public private(set) var scheduled: Set<ReminderKind> = []
    public init() {}
    public func requestAuthorization() async -> Bool { true }
    public func schedule(_ kind: ReminderKind, hour: Int, minute: Int) async { scheduled.insert(kind) }
    public func cancel(_ kind: ReminderKind) async { scheduled.remove(kind) }
    public func cancelAll() async { scheduled.removeAll() }
}
