import Testing
@testable import Listacular

@Suite("PlainTextSerializer")
struct PlainTextSerializerTests {
    // MARK: - Serialize

    @Test("serializes heading with # prefix")
    func serializeHeading() {
        let items = [ListItem(text: "Packing", itemType: .heading)]
        let result = PlainTextSerializer.serialize(items: items)
        #expect(result == "# Packing")
    }

    @Test("serializes plain text with no prefix")
    func serializePlain() {
        let items = [ListItem(text: "just text", itemType: .plain)]
        let result = PlainTextSerializer.serialize(items: items)
        #expect(result == "just text")
    }

    @Test("serializes bullet with * prefix")
    func serializeBullet() {
        let items = [ListItem(text: "milk", itemType: .bullet)]
        let result = PlainTextSerializer.serialize(items: items)
        #expect(result == "* milk")
    }

    @Test("serializes unchecked checkbox with - prefix")
    func serializeCheckboxUnchecked() {
        let items = [ListItem(text: "buy eggs", itemType: .checkbox)]
        let result = PlainTextSerializer.serialize(items: items)
        #expect(result == "- buy eggs")
    }

    @Test("serializes checked checkbox with @done suffix")
    func serializeCheckboxChecked() {
        let items = [ListItem(text: "buy eggs", itemType: .checkbox, isCompleted: true)]
        let result = PlainTextSerializer.serialize(items: items)
        #expect(result == "- buy eggs @done")
    }

    @Test("serializes indented items with tabs")
    func serializeIndented() {
        let items = [
            ListItem(text: "Clothes", itemType: .heading),
            ListItem(text: "shirts", itemType: .checkbox, indentLevel: 1),
            ListItem(text: "dress shirts", itemType: .checkbox, indentLevel: 2),
        ]
        let result = PlainTextSerializer.serialize(items: items)
        #expect(result == "# Clothes\n\t- shirts\n\t\t- dress shirts")
    }

    @Test("serializes multiple item types together")
    func serializeMixed() {
        let items = [
            ListItem(text: "Shopping", itemType: .heading),
            ListItem(text: "milk", itemType: .bullet),
            ListItem(text: "eggs", itemType: .checkbox),
            ListItem(text: "note to self", itemType: .plain),
        ]
        let result = PlainTextSerializer.serialize(items: items)
        let expected = "# Shopping\n* milk\n- eggs\nnote to self"
        #expect(result == expected)
    }

    // MARK: - Deserialize

    @Test("deserializes heading from # prefix")
    func deserializeHeading() {
        let items = PlainTextSerializer.deserialize("# Packing")
        #expect(items.count == 1)
        #expect(items[0].itemType == .heading)
        #expect(items[0].text == "Packing")
    }

    @Test("deserializes plain text")
    func deserializePlain() {
        let items = PlainTextSerializer.deserialize("just text")
        #expect(items.count == 1)
        #expect(items[0].itemType == .plain)
        #expect(items[0].text == "just text")
    }

    @Test("deserializes bullet from * prefix")
    func deserializeBullet() {
        let items = PlainTextSerializer.deserialize("* milk")
        #expect(items.count == 1)
        #expect(items[0].itemType == .bullet)
        #expect(items[0].text == "milk")
    }

    @Test("deserializes unchecked checkbox from - prefix")
    func deserializeCheckboxUnchecked() {
        let items = PlainTextSerializer.deserialize("- buy eggs")
        #expect(items.count == 1)
        #expect(items[0].itemType == .checkbox)
        #expect(items[0].text == "buy eggs")
        #expect(items[0].isCompleted == false)
    }

    @Test("deserializes checked checkbox from @done suffix")
    func deserializeCheckboxChecked() {
        let items = PlainTextSerializer.deserialize("- buy eggs @done")
        #expect(items.count == 1)
        #expect(items[0].itemType == .checkbox)
        #expect(items[0].text == "buy eggs")
        #expect(items[0].isCompleted == true)
    }

    @Test("deserializes indentation from tabs")
    func deserializeIndented() {
        let items = PlainTextSerializer.deserialize("# Clothes\n\t- shirts\n\t\t- dress shirts")
        #expect(items.count == 3)
        #expect(items[0].indentLevel == 0)
        #expect(items[1].indentLevel == 1)
        #expect(items[2].indentLevel == 2)
    }

    @Test("deserializes empty string to empty array")
    func deserializeEmpty() {
        let items = PlainTextSerializer.deserialize("")
        #expect(items.isEmpty)
    }

    // MARK: - Round-trip

    @Test("round-trips all item types")
    func roundTrip() {
        let original = [
            ListItem(text: "Shopping", itemType: .heading),
            ListItem(text: "milk", itemType: .bullet),
            ListItem(text: "eggs", itemType: .checkbox),
            ListItem(text: "got bread", itemType: .checkbox, isCompleted: true),
            ListItem(text: "note", itemType: .plain),
            ListItem(text: "sub-item", itemType: .checkbox, indentLevel: 1),
        ]
        let serialized = PlainTextSerializer.serialize(items: original)
        let deserialized = PlainTextSerializer.deserialize(serialized)

        #expect(deserialized.count == original.count)
        for (orig, deser) in zip(original, deserialized) {
            #expect(deser.text == orig.text)
            #expect(deser.itemType == orig.itemType)
            #expect(deser.isCompleted == orig.isCompleted)
            #expect(deser.indentLevel == orig.indentLevel)
        }
    }

    @Test("round-trips heading text with special characters")
    func roundTripHeadingSpecialChars() {
        let original = [ListItem(text: "Sleep & Medicine", itemType: .heading)]
        let serialized = PlainTextSerializer.serialize(items: original)
        let deserialized = PlainTextSerializer.deserialize(serialized)
        #expect(deserialized[0].text == "Sleep & Medicine")
        #expect(deserialized[0].itemType == .heading)
    }
}
