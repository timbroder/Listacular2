import Foundation
import SwiftUI

/// Central store managing all documents. Coordinates with StorageService for persistence.
@MainActor @Observable
final class DocumentStore {
    var documents: [ListDocument] = []
    var folders: [Folder] = []
    var selectedDocumentID: UUID?

    private let storage = StorageService()

    var selectedDocument: ListDocument? {
        guard let id = selectedDocumentID else { return nil }
        return documents.first { $0.id == id }
    }

    // MARK: - Persistence

    func loadFromDisk() async {
        do {
            let files = try await storage.loadDocuments()
            documents = files.map { file in
                let name = (file.fileName as NSString).deletingPathExtension
                let ext = (file.fileName as NSString).pathExtension.lowercased()
                let format = FileFormat.allCases.first { $0.fileExtension == ext } ?? .plainText
                let items = Self.deserializePublic(file.content, format: format)
                return ListDocument(
                    title: name,
                    items: items,
                    fileFormat: format,
                    modifiedAt: file.modifiedAt
                )
            }
            documents.sort { $0.modifiedAt > $1.modifiedAt }
        } catch {
            print("Failed to load documents: \(error)")
        }
    }

    func saveToDisk(_ document: ListDocument) async {
        let content = Self.serializePublic(document.items, format: document.fileFormat)
        let fileName = "\(document.title).\(document.fileFormat.fileExtension)"
        do {
            try await storage.save(fileName: fileName, content: content)
        } catch {
            print("Failed to save document: \(error)")
        }
    }

    // MARK: - Document CRUD

    @discardableResult
    func createDocument(title: String = "Untitled", fileFormat: FileFormat = .plainText) -> ListDocument {
        let doc = ListDocument(title: title, fileFormat: fileFormat)
        documents.append(doc)
        selectedDocumentID = doc.id
        Task { await saveToDisk(doc) }
        return doc
    }

    func deleteDocument(_ document: ListDocument) {
        let fileName = "\(document.title).\(document.fileFormat.fileExtension)"
        documents.removeAll { $0.id == document.id }
        if selectedDocumentID == document.id {
            selectedDocumentID = documents.first?.id
        }
        Task { try? await storage.delete(fileName: fileName) }
    }

    func renameDocument(_ document: ListDocument, to newTitle: String) {
        let oldFileName = "\(document.title).\(document.fileFormat.fileExtension)"
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != document.title else { return }
        document.title = trimmed
        document.modifiedAt = .now
        let newFileName = "\(trimmed).\(document.fileFormat.fileExtension)"
        Task { try? await storage.rename(from: oldFileName, to: newFileName) }
    }

    // MARK: - Item CRUD

    @discardableResult
    func addItem(to document: ListDocument, after index: Int? = nil, itemType: ItemType = .checkbox, indentLevel: Int = 0) -> ListItem {
        let item = ListItem(itemType: itemType, indentLevel: indentLevel)
        if let index, index < document.items.count {
            document.items.insert(item, at: index + 1)
        } else {
            document.items.append(item)
        }
        document.modifiedAt = .now
        Task { await saveToDisk(document) }
        return item
    }

    func deleteItem(_ item: ListItem, from document: ListDocument) {
        document.items.removeAll { $0.id == item.id }
        document.modifiedAt = .now
        Task { await saveToDisk(document) }
    }

    func toggleComplete(_ item: ListItem, in document: ListDocument) {
        guard let idx = document.items.firstIndex(where: { $0.id == item.id }) else { return }
        document.items[idx].isCompleted.toggle()
        document.modifiedAt = .now
        Task { await saveToDisk(document) }
    }

    func moveItems(in document: ListDocument, from source: IndexSet, to destination: Int) {
        document.items.move(fromOffsets: source, toOffset: destination)
        document.modifiedAt = .now
        Task { await saveToDisk(document) }
    }

    // MARK: - Due Dates

    func setDueDate(_ date: Date?, for item: ListItem, in document: ListDocument) {
        guard let idx = document.items.firstIndex(where: { $0.id == item.id }) else { return }
        document.items[idx].dueDate = date
        document.modifiedAt = .now
        Task {
            await saveToDisk(document)
            if date != nil {
                await NotificationService.scheduleDueDate(for: document.items[idx], in: document.title)
            } else {
                NotificationService.cancelNotification(for: item.id)
            }
        }
    }

    // MARK: - Bulk Actions

    func removeCompleted(from document: ListDocument) {
        let completedIDs = document.items.filter(\.isCompleted).map(\.id)
        completedIDs.forEach { NotificationService.cancelNotification(for: $0) }
        document.items.removeAll(where: \.isCompleted)
        document.modifiedAt = .now
        Task { await saveToDisk(document) }
    }

    // MARK: - Multi-line Paste

    func pasteItems(text: String, into document: ListDocument, at index: Int? = nil, itemType: ItemType = .checkbox) {
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let newItems = lines.map { line in
            ListItem(text: line, itemType: itemType)
        }
        if let index, index < document.items.count {
            document.items.insert(contentsOf: newItems, at: index + 1)
        } else {
            document.items.append(contentsOf: newItems)
        }
        document.modifiedAt = .now
        Task { await saveToDisk(document) }
    }

    // MARK: - Search

    func searchDocuments(query: String) -> [(document: ListDocument, matchingItems: [ListItem])] {
        guard !query.isEmpty else { return [] }
        let lowered = query.lowercased()
        return documents.compactMap { doc in
            let matches = doc.items.filter { $0.text.lowercased().contains(lowered) }
            let titleMatch = doc.title.lowercased().contains(lowered)
            if !matches.isEmpty || titleMatch {
                return (doc, matches)
            }
            return nil
        }
    }

    // MARK: - Tag Filtering

    func allTags() -> [String] {
        let tags = documents.flatMap { doc in
            doc.items.flatMap(\.extractedTags)
        }
        return Array(Set(tags)).sorted()
    }

    func filterByTag(_ tag: String) -> [(document: ListDocument, matchingItems: [ListItem])] {
        let lowered = tag.lowercased()
        return documents.compactMap { doc in
            let matches = doc.items.filter { item in
                item.extractedTags.contains(where: { $0.lowercased() == lowered })
            }
            guard !matches.isEmpty else { return nil }
            return (doc, matches)
        }
    }

    // MARK: - URL Scheme

    func handleURL(_ url: URL) {
        guard url.scheme == "listacular" else { return }
        switch url.host {
        case "new":
            let title = url.queryValue(for: "title") ?? "Untitled"
            let text = url.queryValue(for: "text")
            let doc = createDocument(title: title)
            if let text {
                pasteItems(text: text, into: doc)
            }
        case "add":
            let listName = url.queryValue(for: "list") ?? ""
            let text = url.queryValue(for: "text") ?? ""
            if let doc = documents.first(where: { $0.title.lowercased() == listName.lowercased() }) {
                _ = addItem(to: doc)
                if let lastIdx = doc.items.indices.last {
                    doc.items[lastIdx].text = text
                }
            }
        default:
            break
        }
    }

    // MARK: - Format-aware serialization

    static func serializePublic(_ items: [ListItem], format: FileFormat) -> String {
        switch format {
        case .plainText: PlainTextSerializer.serialize(items: items)
        case .taskPaper: TaskPaperSerializer.serialize(items: items)
        case .markdown: MarkdownSerializer.serialize(items: items)
        }
    }

    static func deserializePublic(_ text: String, format: FileFormat) -> [ListItem] {
        switch format {
        case .plainText: PlainTextSerializer.deserialize(text)
        case .taskPaper: TaskPaperSerializer.deserialize(text)
        case .markdown: MarkdownSerializer.deserialize(text)
        }
    }
}
