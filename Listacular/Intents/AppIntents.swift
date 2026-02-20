import AppIntents

struct CreateListIntent: AppIntent {
    static let title: LocalizedStringResource = "Create List"
    static let description: IntentDescription = "Create a new list in Listacular"
    static let openAppWhenRun = true

    @Parameter(title: "List Name")
    var name: String

    @MainActor
    func perform() async throws -> some IntentResult {
        let store = DocumentStore()
        _ = store.createDocument(title: name)
        return .result()
    }
}

struct AddItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Item"
    static let description: IntentDescription = "Add an item to a list"
    static let openAppWhenRun = false

    @Parameter(title: "Item Text")
    var text: String

    @Parameter(title: "List Name")
    var listName: String

    @MainActor
    func perform() async throws -> some IntentResult {
        let store = DocumentStore()
        if let doc = store.documents.first(where: { $0.title.lowercased() == listName.lowercased() }) {
            let item = store.addItem(to: doc)
            if let idx = doc.items.firstIndex(where: { $0.id == item.id }) {
                doc.items[idx].text = text
            }
        }
        return .result()
    }
}

struct ListacularShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateListIntent(),
            phrases: ["Create a list in \(.applicationName)"],
            shortTitle: "Create List",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: AddItemIntent(),
            phrases: ["Add item to \(.applicationName)"],
            shortTitle: "Add Item",
            systemImageName: "plus"
        )
    }
}
