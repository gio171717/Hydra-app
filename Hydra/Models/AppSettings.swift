import Foundation

struct AppSettings: Codable, Equatable {
    /// Obiettivo giornaliero in litri.
    var goalLiters: Double = 2.0
    var remindersEnabled: Bool = false
    /// Inizio e fine della fascia dei promemoria, in minuti dalla mezzanotte.
    var startMinutes: Int = 8 * 60
    var endMinutes: Int = 22 * 60
    var intervalMinutes: Int = 90
    /// Capienza personalizzata dei contenitori (chiave: `ContainerKind.rawValue`).
    var containerMl: [String: Int] = [:]
    var hasOnboarded: Bool = false

    static let goalRange: ClosedRange<Double> = 0.5...6.0
    static let intervalOptions = [30, 45, 60, 90, 120, 180]

    var goalMl: Int { Int((goalLiters * 1000).rounded()) }

    func ml(for kind: ContainerKind) -> Int {
        containerMl[kind.rawValue] ?? kind.defaultMl
    }

    init() {}

    // Decodifica tollerante: le chiavi mancanti (versioni future/precedenti) usano i valori di default.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings()
        goalLiters = try c.decodeIfPresent(Double.self, forKey: .goalLiters) ?? d.goalLiters
        remindersEnabled = try c.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? d.remindersEnabled
        startMinutes = try c.decodeIfPresent(Int.self, forKey: .startMinutes) ?? d.startMinutes
        endMinutes = try c.decodeIfPresent(Int.self, forKey: .endMinutes) ?? d.endMinutes
        intervalMinutes = try c.decodeIfPresent(Int.self, forKey: .intervalMinutes) ?? d.intervalMinutes
        containerMl = try c.decodeIfPresent([String: Int].self, forKey: .containerMl) ?? d.containerMl
        hasOnboarded = try c.decodeIfPresent(Bool.self, forKey: .hasOnboarded) ?? d.hasOnboarded
    }
}
