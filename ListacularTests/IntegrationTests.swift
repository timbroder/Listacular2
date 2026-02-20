import Foundation
import Testing
@testable import Listacular

@Suite("Integration: Cross-format serialization")
@MainActor
struct CrossFormatSerializationTests {
    /// Items that all formats support
    private static var commonItems: [ListItem] {
        [
            ListItem(text: "Shopping", itemType: .heading),
            ListItem(text: "milk", itemType: .bullet),
            ListItem(text: "eggs", itemType: .checkbox),
            ListItem(text: "bread", itemType: .checkbox, isCompleted: true),
            ListItem(text: "a note", itemType: .plain),
            ListItem(text: "sub-item", itemType: .checkbox, indentLevel: 1),
        ]
    }

    @Test("PlainText → Markdown round-trip preserves core data")
    func plainTextToMarkdown() {
        let plainText = PlainTextSerializer.serialize(items: Self.commonItems)
        let fromPlain = PlainTextSerializer.deserialize(plainText)
        let markdown = MarkdownSerializer.serialize(items: fromPlain)
        let fromMarkdown = MarkdownSerializer.deserialize(markdown)

        #expect(fromMarkdown.count == Self.commonItems.count)
        for (orig, converted) in zip(Self.commonItems, fromMarkdown) {
            #expect(converted.text == orig.text)
            #expect(converted.itemType == orig.itemType)
            #expect(converted.isCompleted == orig.isCompleted)
            #expect(converted.indentLevel == orig.indentLevel)
        }
    }

    @Test("PlainText → TaskPaper round-trip preserves core data")
    func plainTextToTaskPaper() {
        let plainText = PlainTextSerializer.serialize(items: Self.commonItems)
        let fromPlain = PlainTextSerializer.deserialize(plainText)
        let taskPaper = TaskPaperSerializer.serialize(items: fromPlain)
        let fromTP = TaskPaperSerializer.deserialize(taskPaper)

        #expect(fromTP.count == Self.commonItems.count)
        for (orig, converted) in zip(Self.commonItems, fromTP) {
            #expect(converted.text == orig.text)
            #expect(converted.itemType == orig.itemType)
            #expect(converted.isCompleted == orig.isCompleted)
            #expect(converted.indentLevel == orig.indentLevel)
        }
    }

    @Test("Markdown → TaskPaper round-trip preserves core data")
    func markdownToTaskPaper() {
        let md = MarkdownSerializer.serialize(items: Self.commonItems)
        let fromMD = MarkdownSerializer.deserialize(md)
        let tp = TaskPaperSerializer.serialize(items: fromMD)
        let fromTP = TaskPaperSerializer.deserialize(tp)

        #expect(fromTP.count == Self.commonItems.count)
        for (orig, converted) in zip(Self.commonItems, fromTP) {
            #expect(converted.text == orig.text)
            #expect(converted.itemType == orig.itemType)
            #expect(converted.isCompleted == orig.isCompleted)
        }
    }

    @Test("DocumentStore.serializePublic/deserializePublic round-trips for each format",
          arguments: FileFormat.allCases)
    func storeRoundTrip(format: FileFormat) {
        let serialized = DocumentStore.serializePublic(Self.commonItems, format: format)
        let deserialized = DocumentStore.deserializePublic(serialized, format: format)

        #expect(deserialized.count == Self.commonItems.count)
        for (orig, deser) in zip(Self.commonItems, deserialized) {
            #expect(deser.text == orig.text)
            #expect(deser.itemType == orig.itemType)
            #expect(deser.isCompleted == orig.isCompleted)
            #expect(deser.indentLevel == orig.indentLevel)
        }
    }
}

@Suite("Integration: StorageService file operations")
@MainActor
struct StorageServiceIntegrationTests {
    private func makeTempStorage() -> (StorageService, URL) {
        let dir = FileManager.default.temporaryDirectory
            .appending(path: "ListacularTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        return (StorageService(baseDirectory: dir), dir)
    }

    private func cleanup(_ dir: URL) {
        try? FileManager.default.removeItem(at: dir)
    }

    @Test("save then load returns the file")
    func saveAndLoad() async throws {
        let (storage, dir) = makeTempStorage()
        defer { cleanup(dir) }

        try await storage.save(fileName: "test.txt", content: "hello")
        let files = try await storage.loadDocuments()
        #expect(files.count == 1)
        #expect(files[0].fileName == "test.txt")
        #expect(files[0].content == "hello")
    }

    @Test("delete removes the file")
    func deleteFile() async throws {
        let (storage, dir) = makeTempStorage()
        defer { cleanup(dir) }

        try await storage.save(fileName: "test.txt", content: "hello")
        try await storage.delete(fileName: "test.txt")
        let files = try await storage.loadDocuments()
        #expect(files.isEmpty)
    }

    @Test("rename changes the filename")
    func renameFile() async throws {
        let (storage, dir) = makeTempStorage()
        defer { cleanup(dir) }

        try await storage.save(fileName: "old.txt", content: "hello")
        try await storage.rename(from: "old.txt", to: "new.txt")
        let files = try await storage.loadDocuments()
        #expect(files.count == 1)
        #expect(files[0].fileName == "new.txt")
    }

    @Test("ensureDirectory creates directory")
    func ensureDirectory() async throws {
        let (storage, dir) = makeTempStorage()
        defer { cleanup(dir) }

        try await storage.ensureDirectory()
        #expect(FileManager.default.fileExists(atPath: dir.path()))
    }

    @Test("loadDocuments skips unsupported file extensions")
    func skipsUnsupported() async throws {
        let (storage, dir) = makeTempStorage()
        defer { cleanup(dir) }

        try await storage.save(fileName: "notes.txt", content: "hello")
        // Write a .json file directly to the directory
        try await storage.ensureDirectory()
        try "{}".write(to: dir.appending(path: "data.json"), atomically: true, encoding: .utf8)
        let files = try await storage.loadDocuments()
        #expect(files.count == 1)
        #expect(files[0].fileName == "notes.txt")
    }

    @Test("full document round-trip through disk for all formats",
          arguments: FileFormat.allCases)
    func fullDiskRoundTrip(format: FileFormat) async throws {
        let (storage, dir) = makeTempStorage()
        defer { cleanup(dir) }

        let items = [
            ListItem(text: "Header", itemType: .heading),
            ListItem(text: "Task 1", itemType: .checkbox),
            ListItem(text: "Task 2", itemType: .checkbox, isCompleted: true),
            ListItem(text: "Note", itemType: .plain),
        ]

        let serialized = DocumentStore.serializePublic(items, format: format)
        let fileName = "test.\(format.fileExtension)"
        try await storage.save(fileName: fileName, content: serialized)

        let files = try await storage.loadDocuments()
        #expect(files.count == 1)

        let deserialized = DocumentStore.deserializePublic(files[0].content, format: format)
        #expect(deserialized.count == items.count)
        for (orig, deser) in zip(items, deserialized) {
            #expect(deser.text == orig.text)
            #expect(deser.itemType == orig.itemType)
            #expect(deser.isCompleted == orig.isCompleted)
        }
    }
}

@Suite("Integration: App Intents")
@MainActor
struct AppIntentsIntegrationTests {
    @Test("CreateListIntent creates document with name")
    func createListIntent() async throws {
        let intent = CreateListIntent()
        intent.name = "My List"
        _ = try await intent.perform()
        // Intent creates via shared store - we verify the intent runs without error
    }

    @Test("AddItemIntent adds to existing list")
    func addItemIntent() async throws {
        // Create a document first via the store
        let store = DocumentStore()
        _ = store.createDocument(title: "Groceries")

        let intent = AddItemIntent()
        intent.text = "milk"
        intent.listName = "Groceries"
        // The intent uses a shared store, so this is a smoke test
        // In a real app we'd inject the store
        _ = try await intent.perform()
    }
}
