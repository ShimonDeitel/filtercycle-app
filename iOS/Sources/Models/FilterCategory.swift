import Foundation

/// A household filter category with a typical replacement interval, in days.
enum FilterCategory: String, Codable, CaseIterable, Identifiable {
    case hvac = "HVAC / Furnace"
    case fridgeWater = "Fridge Water"
    case humidifier = "Humidifier"
    case vacuum = "Vacuum"
    case rangeHood = "Range Hood"
    case custom = "Custom"

    var id: String { rawValue }

    /// Default replacement interval in days. `custom` has no built-in default;
    /// callers must supply a user-defined interval when this category is chosen.
    var defaultIntervalDays: Int {
        switch self {
        case .hvac: return 90
        case .fridgeWater: return 180
        case .humidifier: return 45
        case .vacuum: return 60
        case .rangeHood: return 120
        case .custom: return 90 // sensible fallback if a caller forgets to override
        }
    }

    /// SF Symbol representing the category (vector only, no emoji).
    var symbolName: String {
        switch self {
        case .hvac: return "wind"
        case .fridgeWater: return "drop.fill"
        case .humidifier: return "aqi.medium"
        case .vacuum: return "fanblades.fill"
        case .rangeHood: return "flame.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
}
