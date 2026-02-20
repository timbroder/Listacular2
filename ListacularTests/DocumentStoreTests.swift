import Foundation
import Testing
@testable import Listacular

@Suite("DocumentStore")
@MainActor
struct DocumentStoreTests {
    // MARK: - Document CRUD

    @Test("createDocument adds document and selects it")
    func createDocument() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        #expect(store.documents.count == 1)
        #expect(store.selectedDocumentID == doc.id)
        #expect(doc.title == "Test")
    }

    @Test("createDocument with format")
    func createDocumentWithFormat() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Notes", fileFormat: .markdown)
        #expect(doc.fileFormat == .markdown)
    }

    @Test("deleteDocument removes document")
    func deleteDocument() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        store.deleteDocument(doc)
        #expect(store.documents.isEmpty)
    }

    @Test("deleteDocument clears selection when deleting selected")
    func deleteSelectedDocument() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        #expect(store.selectedDocumentID == doc.id)
        store.deleteDocument(doc)
        #expect(store.selectedDocumentID == nil)
    }

    @Test("deleteDocument selects first remaining document")
    func deleteSelectsFirst() {
        let store = DocumentStore()
        let doc1 = store.createDocument(title: "First")
        let doc2 = store.createDocument(title: "Second")
        // doc2 is selected after creation
        #expect(store.selectedDocumentID == doc2.id)
        store.deleteDocument(doc2)
        #expect(store.selectedDocumentID == doc1.id)
    }

    @Test("renameDocument updates title")
    func renameDocument() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Old")
        store.renameDocument(doc, to: "New")
        #expect(doc.title == "New")
    }

    @Test("renameDocument ignores empty name")
    func renameDocumentEmpty() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Keep")
        store.renameDocument(doc, to: "  ")
        #expect(doc.title == "Keep")
    }

    @Test("renameDocument trims whitespace")
    func renameDocumentTrims() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Old")
        store.renameDocument(doc, to: "  New  ")
        #expect(doc.title == "New")
    }

    @Test("selectedDocument returns correct document")
    func selectedDocument() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        #expect(store.selectedDocument?.id == doc.id)
    }

    @Test("selectedDocument returns nil when nothing selected")
    func selectedDocumentNil() {
        let store = DocumentStore()
        #expect(store.selectedDocument == nil)
    }

    // MARK: - Item CRUD

    @Test("addItem appends to document")
    func addItem() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        let item = store.addItem(to: doc)
        #expect(doc.items.count == 1)
        #expect(doc.items[0].id == item.id)
    }

    @Test("addItem inserts after index")
    func addItemAfterIndex() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        _ = store.addItem(to: doc)  // index 0
        _ = store.addItem(to: doc)  // index 1
        let inserted = store.addItem(to: doc, after: 0)
        #expect(doc.items[1].id == inserted.id)
        #expect(doc.items.count == 3)
    }

    @Test("addItem uses specified itemType and indentLevel")
    func addItemWithParams() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        let item = store.addItem(to: doc, itemType: .bullet, indentLevel: 2)
        #expect(item.itemType == .bullet)
        #expect(item.indentLevel == 2)
    }

    @Test("deleteItem removes specific item")
    func deleteItem() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        let item1 = store.addItem(to: doc)
        let item2 = store.addItem(to: doc)
        store.deleteItem(item1, from: doc)
        #expect(doc.items.count == 1)
        #expect(doc.items[0].id == item2.id)
    }

    @Test("toggleComplete flips isCompleted")
    func toggleComplete() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        let item = store.addItem(to: doc)
        #expect(doc.items[0].isCompleted == false)
        store.toggleComplete(item, in: doc)
        #expect(doc.items[0].isCompleted == true)
        store.toggleComplete(item, in: doc)
        #expect(doc.items[0].isCompleted == false)
    }

    @Test("moveItems reorders document items")
    func moveItems() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        let item1 = store.addItem(to: doc)
        _ = store.addItem(to: doc)
        store.moveItems(in: doc, from: IndexSet(integer: 0), to: 2)
        #expect(doc.items.last?.id == item1.id)
    }

    // MARK: - Due Dates

    @Test("setDueDate assigns date to item")
    func setDueDate() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        let item = store.addItem(to: doc)
        let date = Date()
        store.setDueDate(date, for: item, in: doc)
        #expect(doc.items[0].dueDate == date)
    }

    @Test("setDueDate clears date with nil")
    func clearDueDate() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        let item = store.addItem(to: doc)
        store.setDueDate(Date(), for: item, in: doc)
        store.setDueDate(nil, for: item, in: doc)
        #expect(doc.items[0].dueDate == nil)
    }

    // MARK: - Bulk Actions

    @Test("removeCompleted removes only completed items")
    func removeCompleted() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        let item1 = store.addItem(to: doc)
        let item2 = store.addItem(to: doc)
        store.toggleComplete(item1, in: doc)
        store.removeCompleted(from: doc)
        #expect(doc.items.count == 1)
        #expect(doc.items[0].id == item2.id)
    }

    @Test("pasteItems adds multiple items from text")
    func pasteItems() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        store.pasteItems(text: "milk\neggs\nbread", into: doc)
        #expect(doc.items.count == 3)
        #expect(doc.items[0].text == "milk")
        #expect(doc.items[1].text == "eggs")
        #expect(doc.items[2].text == "bread")
    }

    @Test("pasteItems inserts at index")
    func pasteItemsAtIndex() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        _ = store.addItem(to: doc)
        doc.items[0].text = "existing"
        store.pasteItems(text: "new1\nnew2", into: doc, at: 0)
        #expect(doc.items.count == 3)
        #expect(doc.items[0].text == "existing")
        #expect(doc.items[1].text == "new1")
        #expect(doc.items[2].text == "new2")
    }

    @Test("pasteItems skips empty lines")
    func pasteItemsSkipsEmpty() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        store.pasteItems(text: "milk\n\neggs\n\n", into: doc)
        #expect(doc.items.count == 2)
    }

    // MARK: - Search

    @Test("searchDocuments finds items matching query")
    func searchByItemText() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Groceries")
        _ = store.addItem(to: doc)
        doc.items[0].text = "buy milk"
        let results = store.searchDocuments(query: "milk")
        #expect(results.count == 1)
        #expect(results[0].matchingItems.count == 1)
    }

    @Test("searchDocuments is case-insensitive")
    func searchCaseInsensitive() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        _ = store.addItem(to: doc)
        doc.items[0].text = "Buy MILK"
        let results = store.searchDocuments(query: "milk")
        #expect(results.count == 1)
    }

    @Test("searchDocuments matches document title")
    func searchByTitle() {
        let store = DocumentStore()
        _ = store.createDocument(title: "Groceries")
        let results = store.searchDocuments(query: "Groceries")
        #expect(results.count == 1)
    }

    @Test("searchDocuments returns empty for no match")
    func searchNoMatch() {
        let store = DocumentStore()
        _ = store.createDocument(title: "Test")
        let results = store.searchDocuments(query: "xyz")
        #expect(results.isEmpty)
    }

    @Test("searchDocuments returns empty for empty query")
    func searchEmptyQuery() {
        let store = DocumentStore()
        _ = store.createDocument(title: "Test")
        let results = store.searchDocuments(query: "")
        #expect(results.isEmpty)
    }

    // MARK: - Tags

    @Test("allTags returns sorted unique tags")
    func allTags() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Test")
        _ = store.addItem(to: doc)
        _ = store.addItem(to: doc)
        doc.items[0].text = "item @work @urgent"
        doc.items[1].text = "item @work @home"
        let tags = store.allTags()
        #expect(tags == ["home", "urgent", "work"])
    }

    @Test("filterByTag returns matching items grouped by document")
    func filterByTag() {
        let store = DocumentStore()
        let doc = store.createDocument(title: "Tasks")
        _ = store.addItem(to: doc)
        _ = store.addItem(to: doc)
        doc.items[0].text = "meeting @work"
        doc.items[1].text = "exercise @health"
        let results = store.filterByTag("work")
        #expect(results.count == 1)
        #expect(results[0].matchingItems.count == 1)
        #expect(results[0].matchingItems[0].text == "meeting @work")
    }

    // MARK: - URL Scheme

    @Test("handleURL creates new document for listacular://new")
    func handleURLNew() {
        let store = DocumentStore()
        let url = URL(string: "listacular://new?title=Shopping")!
        store.handleURL(url)
        #expect(store.documents.count == 1)
        #expect(store.documents[0].title == "Shopping")
    }

    @Test("handleURL creates document with text for listacular://new")
    func handleURLNewWithText() {
        let store = DocumentStore()
        let url = URL(string: "listacular://new?title=List&text=milk")!
        store.handleURL(url)
        #expect(store.documents[0].items.count == 1)
    }

    @Test("handleURL adds item for listacular://add")
    func handleURLAdd() {
        let store = DocumentStore()
        _ = store.createDocument(title: "Groceries")
        let url = URL(string: "listacular://add?list=Groceries&text=eggs")!
        store.handleURL(url)
        #expect(store.documents[0].items.last?.text == "eggs")
    }

    @Test("handleURL ignores unknown schemes")
    func handleURLUnknownScheme() {
        let store = DocumentStore()
        let url = URL(string: "other://new")!
        store.handleURL(url)
        #expect(store.documents.isEmpty)
    }

    // MARK: - Serialization dispatch

    @Test("serializePublic dispatches to correct serializer")
    func serializeDispatch() {
        let items = [ListItem(text: "test", itemType: .bullet)]
        let plain = DocumentStore.serializePublic(items, format: .plainText)
        let md = DocumentStore.serializePublic(items, format: .markdown)
        let tp = DocumentStore.serializePublic(items, format: .taskPaper)
        #expect(plain == "* test")
        #expect(md == "- test")
        #expect(tp == "* test")
    }
}
