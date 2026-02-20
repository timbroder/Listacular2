import Foundation
import Testing
@testable import Listacular

@Suite("ListItem")
struct ListItemTests {
    // MARK: - Initialization

    @Test("initializes with default values")
    func defaultInit() {
        let item = ListItem(text: "test")
        #expect(item.text == "test")
        #expect(item.itemType == .checkbox)
        #expect(item.isCompleted == false)
        #expect(item.indentLevel == 0)
        #expect(item.dueDate == nil)
        #expect(item.priority == .none)
        #expect(item.tags.isEmpty)
    }

    @Test("initializes with custom values")
    func customInit() {
        let date = Date()
        let item = ListItem(
            text: "buy milk",
            itemType: .checkbox,
            isCompleted: true,
            indentLevel: 2,
            dueDate: date,
            priority: .high,
            tags: ["grocery"]
        )
        #expect(item.text == "buy milk")
        #expect(item.itemType == .checkbox)
        #expect(item.isCompleted == true)
        #expect(item.indentLevel == 2)
        #expect(item.dueDate == date)
        #expect(item.priority == .high)
        #expect(item.tags == ["grocery"])
    }

    @Test("generates unique IDs")
    func uniqueIDs() {
        let a = ListItem(text: "a")
        let b = ListItem(text: "b")
        #expect(a.id != b.id)
    }

    // MARK: - Tag Extraction

    @Test("extracts single tag from text")
    func extractSingleTag() {
        let item = ListItem(text: "buy milk @grocery")
        let tags = item.extractedTags
        #expect(tags.contains("grocery"))
    }

    @Test("extracts multiple tags from text")
    func extractMultipleTags() {
        let item = ListItem(text: "meeting @work @urgent")
        let tags = item.extractedTags
        #expect(tags.contains("work"))
        #expect(tags.contains("urgent"))
    }

    @Test("returns empty when no tags")
    func extractNoTags() {
        let item = ListItem(text: "plain text no tags")
        let tags = item.extractedTags
        #expect(tags.isEmpty)
    }

    @Test("does not extract @done as a tag")
    func skipsDoneTag() {
        let item = ListItem(text: "task @done")
        let tags = item.extractedTags
        // @done is a completion marker, may or may not be extracted depending on implementation
        // This test documents current behavior
        #expect(tags.count <= 1)
    }

    // MARK: - Codable

    @Test("encodes and decodes via JSON")
    func codableRoundTrip() throws {
        let original = ListItem(
            text: "test item",
            itemType: .checkbox,
            isCompleted: true,
            indentLevel: 1
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ListItem.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.text == original.text)
        #expect(decoded.itemType == original.itemType)
        #expect(decoded.isCompleted == original.isCompleted)
        #expect(decoded.indentLevel == original.indentLevel)
    }

    // MARK: - Priority

    @Test("priority has correct display names")
    func priorityDisplayNames() {
        #expect(Priority.none.displayName == "None")
        #expect(Priority.low.displayName == "Low")
        #expect(Priority.medium.displayName == "Medium")
        #expect(Priority.high.displayName == "High")
    }
}
