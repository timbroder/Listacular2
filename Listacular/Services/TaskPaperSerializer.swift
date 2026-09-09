import Foundation

/// Serializes/deserializes items in TaskPaper format.
/// TaskPaper format:
/// - Projects end with `:`
/// - Tasks start with `- `
/// - Notes have no prefix
/// - `@done` tag marks completion
/// - Tab indentation for hierarchy
enum TaskPaperSerializer {
    static func serialize(items: [ListItem]) -> String {
        items.map { item in
            let indent = String(repeating: "\t", count: item.indentLevel)
            let line: String
            switch item.itemType {
            case .checkbox:
                let done = item.isCompleted ? " @done" : ""
                line = "- \(item.text)\(done)"
            case .bullet:
                line = "* \(item.text)"
            case .heading:
                line = "\(item.text):"
            case .plain:
                line = item.text
            }
            return "\(indent)\(line)"
        }.joined(separator: "\n")
    }

    static func deserialize(_ text: String) -> [ListItem] {
        guard !text.isEmpty else { return [] }
        return text.components(separatedBy: "\n").compactMap { line in
            guard !line.isEmpty else { return nil }

            let indentLevel = line.prefix(while: { $0 == "\t" }).count
            var content = String(line.dropFirst(indentLevel))

            let itemType: ItemType
            if content.hasPrefix("- ") {
                itemType = .checkbox
                content = String(content.dropFirst(2))
            } else if content.hasPrefix("* ") {
                itemType = .bullet
                content = String(content.dropFirst(2))
            } else if content.hasSuffix(":") && !content.contains("@") {
                // TaskPaper project header — treat as heading
                itemType = .heading
                content = String(content.dropLast())
            } else {
                itemType = .plain
            }

            let isCompleted: Bool
            if content.contains(" @done") {
                isCompleted = true
                content = content.replacingOccurrences(of: " @done", with: "")
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
