import Testing
@testable import Listacular

@Suite("TaskPaperSerializer")
struct TaskPaperSerializerTests {
    // MARK: - Serialize

    @Test("serializes heading with colon suffix")
    func serializeHeading() {
        let items = [ListItem(text: "Packing", itemType: .heading)]
        let result = TaskPaperSerializer.serialize(items: items)
        #expect(result == "Packing:")
    }

    @Test("serializes checkbox with - prefix")
    func serializeCheckbox() {
        let items = [ListItem(text: "buy eggs", itemType: .checkbox)]
        let result = TaskPaperSerializer.serialize(items: items)
        #expect(result == "- buy eggs")
    }

    @Test("serializes completed checkbox with @done")
    func serializeCheckboxDone() {
        let items = [ListItem(text: "buy eggs", itemType: .checkbox, isCompleted: true)]
        let result = TaskPaperSerializer.serialize(items: items)
        #expect(result == "- buy eggs @done")
    }

    @Test("serializes bullet with * prefix")
    func serializeBullet() {
        let items = [ListItem(text: "note", itemType: .bullet)]
        let result = TaskPaperSerializer.serialize(items: items)
        #expect(result == "* note")
    }

    @Test("serializes plain text with no prefix")
    func serializePlain() {
        let items = [ListItem(text: "just text", itemType: .plain)]
        let result = TaskPaperSerializer.serialize(items: items)
        #expect(result == "just text")
    }

    @Test("serializes indented items with tabs")
    func serializeIndented() {
        let items = [
            ListItem(text: "Errands", itemType: .heading),
            ListItem(text: "groceries", itemType: .checkbox, indentLevel: 1),
        ]
        let result = TaskPaperSerializer.serialize(items: items)
        #expect(result == "Errands:\n\t- groceries")
    }

    // MARK: - Deserialize

    @Test("deserializes project header (colon suffix) as heading")
    func deserializeHeading() {
        let items = TaskPaperSerializer.deserialize("Packing:")
        #expect(items.count == 1)
        #expect(items[0].itemType == .heading)
        #expect(items[0].text == "Packing")
    }

    @Test("deserializes task with - prefix as checkbox")
    func deserializeCheckbox() {
        let items = TaskPaperSerializer.deserialize("- buy eggs")
        #expect(items.count == 1)
        #expect(items[0].itemType == .checkbox)
        #expect(items[0].text == "buy eggs")
        #expect(items[0].isCompleted == false)
    }

    @Test("deserializes @done task as completed")
    func deserializeCheckboxDone() {
        let items = TaskPaperSerializer.deserialize("- buy eggs @done")
        #expect(items.count == 1)
        #expect(items[0].isCompleted == true)
        #expect(items[0].text == "buy eggs")
    }

    @Test("deserializes bullet with * prefix")
    func deserializeBullet() {
        let items = TaskPaperSerializer.deserialize("* note")
        #expect(items.count == 1)
        #expect(items[0].itemType == .bullet)
        #expect(items[0].text == "note")
    }

    @Test("does not treat colon suffix with @ as heading")
    func deserializeColonWithAtSign() {
        let items = TaskPaperSerializer.deserialize("email @done:")
        #expect(items[0].itemType == .plain)
    }

    @Test("deserializes indentation from tabs")
    func deserializeIndented() {
        let items = TaskPaperSerializer.deserialize("Errands:\n\t- groceries")
        #expect(items.count == 2)
        #expect(items[0].indentLevel == 0)
        #expect(items[1].indentLevel == 1)
    }

    @Test("deserializes empty string to empty array")
    func deserializeEmpty() {
        let items = TaskPaperSerializer.deserialize("")
        #expect(items.isEmpty)
    }

    // MARK: - Round-trip

    @Test("round-trips all item types")
    func roundTrip() {
        let original = [
            ListItem(text: "Shopping", itemType: .heading),
            ListItem(text: "milk", itemType: .bullet),
            ListItem(text: "eggs", itemType: .checkbox),
            ListItem(text: "bread", itemType: .checkbox, isCompleted: true),
            ListItem(text: "note", itemType: .plain),
            ListItem(text: "sub-item", itemType: .checkbox, indentLevel: 1),
        ]
        let serialized = TaskPaperSerializer.serialize(items: original)
        let deserialized = TaskPaperSerializer.deserialize(serialized)

        #expect(deserialized.count == original.count)
        for (orig, deser) in zip(original, deserialized) {
            #expect(deser.text == orig.text)
            #expect(deser.itemType == orig.itemType)
            #expect(deser.isCompleted == orig.isCompleted)
            #expect(deser.indentLevel == orig.indentLevel)
        }
    }

    @Test("round-trips heading with special characters")
    func roundTripHeadingSpecialChars() {
        let original = [ListItem(text: "Sleep & Medicine", itemType: .heading)]
        let serialized = TaskPaperSerializer.serialize(items: original)
        let deserialized = TaskPaperSerializer.deserialize(serialized)
        #expect(deserialized[0].text == "Sleep & Medicine")
        #expect(deserialized[0].itemType == .heading)
    }
}
