import Foundation

enum Fmt {
    static let locale = Locale(identifier: "it_IT")

    /// 1500 -> "1,5 L"
    static func liters(_ ml: Int) -> String {
        let value = Double(ml) / 1000
        return value.formatted(.number.precision(.fractionLength(0...2)).locale(locale)) + " L"
    }

    /// 1500 -> "1.500"
    static func number(_ ml: Int) -> String {
        ml.formatted(.number.locale(locale))
    }

    /// Sotto il litro in ml, sopra in litri: 250 -> "250 ml", 1500 -> "1,5 L"
    static func amount(_ ml: Int) -> String {
        ml >= 1000 ? liters(ml) : "\(ml) ml"
    }

    static func time(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute().locale(locale))
    }

    static func minutesOfDay(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    static func interval(_ minutes: Int) -> String {
        switch minutes {
        case ..<60: return "\(minutes) min"
        case 60: return "1 ora"
        default:
            let h = minutes / 60, m = minutes % 60
            return m == 0 ? "\(h) ore" : "\(h) h \(m) min"
        }
    }
}
