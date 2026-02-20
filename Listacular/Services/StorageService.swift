import Foundation

/// File-based local storage for documents.
/// Each document is stored as a plain text file in the app's documents directory,
/// using the format matching what will later sync with Dropbox.
actor StorageService {
    private let baseDirectory: URL

    init(baseDirectory: URL? = nil) {
        if let baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            self.baseDirectory = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appending(path: "Listacular", directoryHint: .isDirectory)
        }
    }

    /// Ensure the storage directory exists.
    func ensureDirectory() throws {
        try FileManager.default.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true
        )
    }

    /// Load all documents from disk.
    func loadDocuments() throws -> [(fileName: String, content: String, modifiedAt: Date)] {
        try ensureDirectory()

        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        let supportedExtensions = Set(FileFormat.allCases.map(\.fileExtension))

        return try contents.compactMap { url in
            guard supportedExtensions.contains(url.pathExtension.lowercased()) else { return nil }
            let text = try String(contentsOf: url, encoding: .utf8)
            let attrs = try fm.attributesOfItem(atPath: url.path())
            let modified = attrs[.modificationDate] as? Date ?? .now
            return (url.lastPathComponent, text, modified)
        }
    }

    /// Save a document to disk.
    func save(fileName: String, content: String) throws {
        try ensureDirectory()
        let url = baseDirectory.appending(path: fileName)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Delete a document from disk.
    func delete(fileName: String) throws {
        let url = baseDirectory.appending(path: fileName)
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path()) {
            try fm.removeItem(at: url)
        }
    }

    /// Rename a document file.
    func rename(from oldName: String, to newName: String) throws {
        let oldURL = baseDirectory.appending(path: oldName)
        let newURL = baseDirectory.appending(path: newName)
        try FileManager.default.moveItem(at: oldURL, to: newURL)
    }
}
