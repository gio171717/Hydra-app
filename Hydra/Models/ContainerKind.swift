import Foundation

/// Contenitori standard tra cui scegliere per registrare velocemente una bevuta.
/// La capienza di ognuno è modificabile dalle impostazioni.
enum ContainerKind: String, Codable, CaseIterable, Identifiable {
    case plasticCup
    case glass
    case smallBottle
    case bottle
    case largeBottle

    var id: String { rawValue }

    var name: String {
        switch self {
        case .plasticCup: "Bicchiere di plastica"
        case .glass: "Bicchiere di vetro"
        case .smallBottle: "Bottiglietta di plastica"
        case .bottle: "Bottiglia"
        case .largeBottle: "Bottiglia grande"
        }
    }

    /// Nome breve per le tessere della griglia.
    var shortName: String {
        switch self {
        case .plasticCup: "Plastica"
        case .glass: "Vetro"
        case .smallBottle: "Bottiglietta"
        case .bottle: "Bottiglia"
        case .largeBottle: "Bottiglia"
        }
    }

    var defaultMl: Int {
        switch self {
        case .plasticCup: 200
        case .glass: 250
        case .smallBottle: 500
        case .bottle: 1000
        case .largeBottle: 1500
        }
    }
}
