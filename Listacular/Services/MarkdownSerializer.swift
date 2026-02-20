import Foundation

/// Serializes/deserializes items in Markdown format.
/// Markdown format:
/// - `# ` headers → plain text
/// - `- [ ] ` / `- [x] ` → checkbox
/// - `- ` / `* ` → bullet
/// - Indentation via spaces (2 or 4 per level)
/// - **bold**, *italic* preserved in text
enum MarkdownSerializer {
    static func serialize(items: [ListItem]) -> String {
        items.map { item in
            let indent = String(repeating: "  ", count: item.indentLevel)
            let line: String
            switch item.itemType {
            case .checkbox:
                let check = item.isCompleted ? "[x]" : "[ ]"
                line = "- \(check) \(item.text)"
            case .bullet:
                line = "- \(item.text)"
            case .heading:
                line = "## \(item.text)"
            case .plain:
                line = item.text
            }
            return "\(indent)\(line)"
        }.joined(separator: "\n")
    }

    static func deserialize(_ text: String) -> [ListItem] {
        guard !text.isEmpty else { return [] }
        return text.components(separatedBy: "\n").compactMap { line -> ListItem? in
            guard !line.isEmpty else { return nil }

            // Count leading spaces for indent (2 or 4 spaces per level)
            let spacePrefixCount = line.prefix(while: { $0 == " " }).count
            let tabPrefixCount = line.prefix(while: { $0 == "\t" }).count
            let indentLevel: Int
            if tabPrefixCount > 0 {
                indentLevel = tabPrefixCount
            } else {
                indentLevel = spacePrefixCount / 2
            }
            var content = line.trimmingCharacters(in: .whitespaces)

            // Check for checkbox pattern: - [ ] or - [x]
            if content.hasPrefix("- [x] ") || content.hasPrefix("- [X] ") {
                content = String(content.dropFirst(6))
                return ListItem(text: content, itemType: .checkbox, isCompleted: true, indentLevel: indentLevel)
            }
            if content.hasPrefix("- [ ] ") {
                content = String(content.dropFirst(6))
                return ListItem(text: content, itemType: .checkbox, isCompleted: false, indentLevel: indentLevel)
            }

            // Bullet: - or *
            if content.hasPrefix("- ") {
                content = String(content.dropFirst(2))
                return ListItem(text: content, itemType: .bullet, indentLevel: indentLevel)
            }
            if content.hasPrefix("* ") {
                content = String(content.dropFirst(2))
                return ListItem(text: content, itemType: .bullet, indentLevel: indentLevel)
            }

            // Header → heading type
            if content.hasPrefix("#") {
                content = content.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
                return ListItem(text: content, itemType: .heading, indentLevel: indentLevel)
            }

            return ListItem(text: content, itemType: .plain, indentLevel: indentLevel)
        }
    }
}
