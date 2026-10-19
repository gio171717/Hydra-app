import Foundation
import UserNotifications

/// Pianifica i promemoria locali per bere.
///
/// Per ogni giorno i promemoria cadono a intervalli regolari nella fascia scelta.
/// La quantità suggerita è la parte di acqua che manca all'obiettivo divisa per i
/// promemoria rimasti: se ne salti uno, i successivi chiedono un po' di più.
/// Ogni volta che registri una bevuta la pianificazione viene ricalcolata.
enum ReminderScheduler {
    struct Slot: Hashable {
        var date: Date
        var ml: Int
        var remainingMl: Int
    }

    static let categoryID = "HYDRA_REMINDER"
    static let addActionPrefix = "add."
    private static let requestPrefix = "hydra.reminder."
    /// iOS conserva al massimo 64 notifiche in attesa per app.
    private static let maxPending = 60
    static let maxDays = 7

    // MARK: - Calcolo

    static func slotTimes(on day: Date, settings: AppSettings, calendar: Calendar = .current) -> [Date] {
        guard settings.intervalMinutes > 0, settings.endMinutes > settings.startMinutes else { return [] }
        return stride(from: settings.startMinutes, through: settings.endMinutes, by: settings.intervalMinutes)
            .compactMap { calendar.date(bySettingHour: $0 / 60, minute: $0 % 60, second: 0, of: day) }
    }

    static func plan(settings: AppSettings, consumedToday: Int, now: Date = .now, days: Int = maxDays) -> [Slot] {
        let cal = Calendar.current
        let goal = settings.goalMl
        var result: [Slot] = []

        for offset in 0..<max(1, days) {
            guard let day = cal.date(byAdding: .day, value: offset, to: now) else { continue }
            let remaining = offset == 0 ? goal - consumedToday : goal
            guard remaining > 0 else { continue }
            let times = slotTimes(on: day, settings: settings).filter { $0 > now.addingTimeInterval(30) }
            for (index, time) in times.enumerated() {
                let left = times.count - index
                let portion = min(remaining, roundToStep(Double(remaining) / Double(left)))
                result.append(Slot(date: time, ml: portion, remainingMl: remaining))
            }
            if result.count >= maxPending { break }
        }
        return Array(result.prefix(maxPending))
    }

    /// Arrotonda a multipli di 50 ml (minimo 50).
    static func roundToStep(_ value: Double, step: Double = 50) -> Int {
        max(Int(step), Int((value / step).rounded()) * Int(step))
    }

    // MARK: - Notifiche

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    /// Pulsanti mostrati tenendo premuta la notifica.
    static func registerCategories(settings: AppSettings) {
        let kinds: [ContainerKind] = [.plasticCup, .glass, .smallBottle]
        let actions = kinds.map { kind in
            UNNotificationAction(
                identifier: addActionPrefix + kind.rawValue,
                title: "+ \(kind.name) (\(Fmt.amount(settings.ml(for: kind))))",
                options: []
            )
        }
        let category = UNNotificationCategory(identifier: categoryID, actions: actions, intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func reschedule(settings: AppSettings, consumedToday: Int) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix(requestPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)

        guard settings.remindersEnabled else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        let cal = Calendar.current
        for slot in plan(settings: settings, consumedToday: consumedToday) {
            let content = UNMutableNotificationContent()
            content.title = "È ora di bere 💧"
            content.body = "Bevi circa \(Fmt.amount(slot.ml)). Ti mancano \(Fmt.amount(slot.remainingMl)) "
                + "per arrivare a \(Fmt.liters(settings.goalMl))."
            content.sound = .default
            content.categoryIdentifier = categoryID
            content.threadIdentifier = "hydra"

            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: slot.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let id = requestPrefix + String(Int(slot.date.timeIntervalSince1970))
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    /// Notifica di prova dopo 5 secondi.
    static func sendTest(settings: AppSettings, consumedToday: Int) async {
        guard await requestAuthorization() else { return }
        let remaining = max(0, settings.goalMl - consumedToday)
        let content = UNMutableNotificationContent()
        content.title = "È ora di bere 💧"
        content.body = remaining > 0
            ? "Questa è una prova. Ti mancano \(Fmt.amount(remaining)) per arrivare a \(Fmt.liters(settings.goalMl))."
            : "Questa è una prova. Hai già raggiunto l'obiettivo di oggi!"
        content.sound = .default
        content.categoryIdentifier = categoryID
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        try? await UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: "hydra.test", content: content, trigger: trigger))
    }
}
