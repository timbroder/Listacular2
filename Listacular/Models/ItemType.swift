import Foundation

/// The types of line items, matching Listacular's original behavior.
enum ItemType: String, Codable, Sendable, CaseIterable {
    case heading
    case plain
    case bullet
    case checkbox

    var displayName: String {
        switch self {
        case .heading: "Heading"
        case .plain: "Plain Text"
        case .bullet: "Bullet"
        case .checkbox: "Checkbox"
        }
    }
}
