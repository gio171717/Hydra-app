import Foundation

/// Una singola bevuta registrata.
struct DrinkEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var ml: Int
    var date: Date
    /// Contenitore usato, `nil` se la quantità è stata inserita a mano.
    var kind: ContainerKind?

    var sourceName: String { kind?.name ?? "Quantità manuale" }
}

/// Totale bevuto in un giorno, usato nello storico.
struct DailyTotal: Identifiable, Hashable {
    var day: Date
    var ml: Int
    var id: Date { day }
}
