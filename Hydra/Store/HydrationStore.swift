import Foundation
import Observation

/// Stato dell'app: bevute registrate e impostazioni, salvati in UserDefaults.
@Observable
final class HydrationStore {
    static let shared = HydrationStore()

    private(set) var entries: [DrinkEntry] = []

    var settings: AppSettings {
        didSet {
            guard settings != oldValue else { return }
            save(settings, key: Self.settingsKey)
            if settings.containerMl != oldValue.containerMl {
                ReminderScheduler.registerCategories(settings: settings)
            }
            rescheduleReminders()
        }
    }

    /// Giorno di riferimento per "oggi"; aggiornato quando l'app torna in primo piano.
    private(set) var today: Date = .now

    private static let entriesKey = "hydra.entries.v1"
    private static let settingsKey = "hydra.settings.v1"
    private static let historyDays = 120

    @ObservationIgnored private var rescheduleTask: Task<Void, Never>?

    init() {
        settings = Self.load(AppSettings.self, key: Self.settingsKey) ?? AppSettings()
        entries = Self.load([DrinkEntry].self, key: Self.entriesKey) ?? []
    }

    // MARK: - Valori derivati

    var todayEntries: [DrinkEntry] {
        let cal = Calendar.current
        return entries
            .filter { cal.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.date > $1.date }
    }

    var todayTotal: Int { todayEntries.reduce(0) { $0 + $1.ml } }
    var goalMl: Int { settings.goalMl }
    var remainingMl: Int { max(0, goalMl - todayTotal) }
    var progress: Double { goalMl > 0 ? Double(todayTotal) / Double(goalMl) : 0 }
    var goalReached: Bool { todayTotal >= goalMl }

    /// Prossimo promemoria previsto per oggi, se attivo.
    var nextReminder: ReminderScheduler.Slot? {
        guard settings.remindersEnabled else { return nil }
        return ReminderScheduler.plan(settings: settings, consumedToday: todayTotal, days: 1).first
    }

    func dailyTotals(days: Int) -> [DailyTotal] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: today)
        var totals: [Date: Int] = [:]
        for entry in entries {
            totals[cal.startOfDay(for: entry.date), default: 0] += entry.ml
        }
        return (0..<days).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: start) else { return nil }
            return DailyTotal(day: day, ml: totals[day] ?? 0)
        }
    }

    // MARK: - Azioni

    @discardableResult
    func add(ml: Int, kind: ContainerKind?, date: Date = .now) -> DrinkEntry? {
        guard ml > 0 else { return nil }
        if !Calendar.current.isDate(today, inSameDayAs: date) { today = date }
        let entry = DrinkEntry(ml: ml, date: date, kind: kind)
        entries.append(entry)
        saveEntries()
        rescheduleReminders()
        return entry
    }

    @discardableResult
    func add(_ kind: ContainerKind, fraction: Double = 1) -> DrinkEntry? {
        let ml = Int((Double(settings.ml(for: kind)) * fraction).rounded())
        return add(ml: ml, kind: kind)
    }

    func delete(_ entry: DrinkEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
        rescheduleReminders()
    }

    func resetToday() {
        let cal = Calendar.current
        entries.removeAll { cal.isDate($0.date, inSameDayAs: today) }
        saveEntries()
        rescheduleReminders()
    }

    /// Da chiamare quando l'app torna attiva: aggiorna il giorno corrente,
    /// elimina lo storico troppo vecchio e ripianifica i promemoria.
    func refresh() {
        today = .now
        let cal = Calendar.current
        if let limit = cal.date(byAdding: .day, value: -Self.historyDays, to: cal.startOfDay(for: today)) {
            let before = entries.count
            entries.removeAll { $0.date < limit }
            if entries.count != before { saveEntries() }
        }
        rescheduleReminders()
    }

    /// Gestisce i pulsanti rapidi delle notifiche ("+ Bicchiere", ...).
    func handleNotificationAction(_ identifier: String, completion: @escaping () -> Void) {
        guard identifier.hasPrefix(ReminderScheduler.addActionPrefix),
              let kind = ContainerKind(rawValue: String(identifier.dropFirst(ReminderScheduler.addActionPrefix.count)))
        else {
            completion()
            return
        }
        today = .now
        let entry = DrinkEntry(ml: settings.ml(for: kind), date: .now, kind: kind)
        entries.append(entry)
        saveEntries()
        rescheduleTask?.cancel()
        let settings = settings
        let total = todayTotal
        Task {
            await ReminderScheduler.reschedule(settings: settings, consumedToday: total)
            completion()
        }
    }

    /// Ripianifica le notifiche con un piccolo ritardo, così più modifiche ravvicinate
    /// (es. trascinando lo slider dell'obiettivo) producono un solo aggiornamento.
    func rescheduleReminders() {
        rescheduleTask?.cancel()
        let settings = settings
        let total = todayTotal
        rescheduleTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await ReminderScheduler.reschedule(settings: settings, consumedToday: total)
        }
    }

    // MARK: - Persistenza

    private func saveEntries() { save(entries, key: Self.entriesKey) }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
