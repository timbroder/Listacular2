import Foundation

/// Priority levels for tasks.
enum Priority: Int, Codable, Sendable, CaseIterable, Comparable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3

    var displayName: String {
        switch self {
        case .none: "None"
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    var symbol: String {
        switch self {
        case .none: ""
        case .low: "!"
        case .medium: "!!"
        case .high: "!!!"
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A single line item within a list document.
/// Uses a flat structure with `indentLevel` rather than nested children,
/// matching the plain text file format where tabs control indentation.
struct ListItem: Identifiable, Codable, Sendable {
    var id: UUID
    var text: String
    var itemType: ItemType
    var isCompleted: Bool
    var indentLevel: Int
    var dueDate: Date?
    var priority: Priority
    var tags: [String]

    init(
        id: UUID = UUID(),
        text: String = "",
        itemType: ItemType = .checkbox,
        isCompleted: Bool = false,
        indentLevel: Int = 0,
        dueDate: Date? = nil,
        priority: Priority = .none,
        tags: [String] = []
    ) {
        self.id = id
        self.text = text
        self.itemType = itemType
        self.isCompleted = isCompleted
        self.indentLevel = indentLevel
        self.dueDate = dueDate
        self.priority = priority
        self.tags = tags
    }

    /// Extract @tags from the item text.
    var extractedTags: [String] {
        let pattern = #"@(\w+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let tagRange = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[tagRange])
        }
    }
}
