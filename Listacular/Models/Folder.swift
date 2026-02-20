import Foundation

/// Represents a folder for organizing documents.
/// Maps to a directory on disk within the Listacular storage.
@MainActor @Observable
final class Folder: Identifiable {
    let id: UUID
    var name: String
    var subfolders: [Folder]
    var documentIDs: [UUID]

    init(
        id: UUID = UUID(),
        name: String,
        subfolders: [Folder] = [],
        documentIDs: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.subfolders = subfolders
        self.documentIDs = documentIDs
    }
}
