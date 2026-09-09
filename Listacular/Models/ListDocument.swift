import Foundation

/// Represents a single list, note, or outline document.
/// Maps to a single file on disk (e.g., `Shopping.txt`).
@MainActor @Observable
final class ListDocument: Identifiable {
    let id: UUID
    var title: String
    var items: [ListItem]
    var fileFormat: FileFormat
    let createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "Untitled",
        items: [ListItem] = [],
        fileFormat: FileFormat = .plainText,
        createdAt: Date = .now,
        modifiedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.items = items
        self.fileFormat = fileFormat
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
