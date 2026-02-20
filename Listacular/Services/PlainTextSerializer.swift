import Foundation

/// Serializes and deserializes ListItems to/from plain text format.
/// Each line is an item, with tab characters for indentation and prefixes for type:
/// - No prefix: plain text
/// - `* `: bullet point
/// - `- `: checkbox (unchecked)
/// - `- item @done`: checkbox (checked)
enum PlainTextSerializer {
    static func serialize(items: [ListItem]) -> String {
        items.map { item in
            let indent = String(repeating: "\t", count: item.indentLevel)
            let prefix: String
            switch item.itemType {
            case .plain:
                prefix = ""
            case .bullet:
                prefix = "* "
            case .checkbox:
                prefix = "- "
            }
            let suffix = (item.itemType == .checkbox && item.isCompleted) ? " @done" : ""
            return "\(indent)\(prefix)\(item.text)\(suffix)"
        }.joined(separator: "\n")
    }

    static func deserialize(_ text: String) -> [ListItem] {
        guard !text.isEmpty else { return [] }
        return text.components(separatedBy: "\n").compactMap { line in
            guard !line.allSatisfy(\.isWhitespace) || !line.isEmpty else { return nil }

            // Count leading tabs for indent level
            let indentLevel = line.prefix(while: { $0 == "\t" }).count
            var content = String(line.dropFirst(indentLevel))

            // Determine item type from prefix
            let itemType: ItemType
            if content.hasPrefix("- ") {
                itemType = .checkbox
                content = String(content.dropFirst(2))
            } else if content.hasPrefix("* ") {
                itemType = .bullet
                content = String(content.dropFirst(2))
            } else {
                itemType = .plain
            }

            // Check for @done tag
            let isCompleted: Bool
            if itemType == .checkbox && content.hasSuffix(" @done") {
                isCompleted = true
                content = String(content.dropLast(6))
            } else {
                isCompleted = false
            }

            return ListItem(
                text: content,
                itemType: itemType,
                isCompleted: isCompleted,
                indentLevel: indentLevel
            )
        }
    }
}
