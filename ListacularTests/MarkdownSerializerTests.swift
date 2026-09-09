import Testing
@testable import Listacular

@Suite("MarkdownSerializer")
struct MarkdownSerializerTests {
    // MARK: - Serialize

    @Test("serializes heading with ## prefix")
    func serializeHeading() {
        let items = [ListItem(text: "Packing", itemType: .heading)]
        let result = MarkdownSerializer.serialize(items: items)
        #expect(result == "## Packing")
    }

    @Test("serializes unchecked checkbox as - [ ]")
    func serializeCheckboxUnchecked() {
        let items = [ListItem(text: "buy eggs", itemType: .checkbox)]
        let result = MarkdownSerializer.serialize(items: items)
        #expect(result == "- [ ] buy eggs")
    }

    @Test("serializes checked checkbox as - [x]")
    func serializeCheckboxChecked() {
        let items = [ListItem(text: "buy eggs", itemType: .checkbox, isCompleted: true)]
        let result = MarkdownSerializer.serialize(items: items)
        #expect(result == "- [x] buy eggs")
    }

    @Test("serializes bullet with - prefix")
    func serializeBullet() {
        let items = [ListItem(text: "milk", itemType: .bullet)]
        let result = MarkdownSerializer.serialize(items: items)
        #expect(result == "- milk")
    }

    @Test("serializes plain text with no prefix")
    func serializePlain() {
        let items = [ListItem(text: "just text", itemType: .plain)]
        let result = MarkdownSerializer.serialize(items: items)
        #expect(result == "just text")
    }

    @Test("serializes indented items with 2-space indent")
    func serializeIndented() {
        let items = [
            ListItem(text: "Clothes", itemType: .heading),
            ListItem(text: "shirts", itemType: .checkbox, indentLevel: 1),
            ListItem(text: "dress shirts", itemType: .checkbox, indentLevel: 2),
        ]
        let result = MarkdownSerializer.serialize(items: items)
        #expect(result == "## Clothes\n  - [ ] shirts\n    - [ ] dress shirts")
    }

    // MARK: - Deserialize

    @Test("deserializes ## heading")
    func deserializeH2Heading() {
        let items = MarkdownSerializer.deserialize("## Packing")
        #expect(items.count == 1)
        #expect(items[0].itemType == .heading)
        #expect(items[0].text == "Packing")
    }

    @Test("deserializes # heading")
    func deserializeH1Heading() {
        let items = MarkdownSerializer.deserialize("# Title")
        #expect(items.count == 1)
        #expect(items[0].itemType == .heading)
        #expect(items[0].text == "Title")
    }

    @Test("deserializes ### heading")
    func deserializeH3Heading() {
        let items = MarkdownSerializer.deserialize("### Sub-section")
        #expect(items.count == 1)
        #expect(items[0].itemType == .heading)
        #expect(items[0].text == "Sub-section")
    }

    @Test("deserializes unchecked checkbox")
    func deserializeCheckboxUnchecked() {
        let items = MarkdownSerializer.deserialize("- [ ] buy eggs")
        #expect(items.count == 1)
        #expect(items[0].itemType == .checkbox)
        #expect(items[0].isCompleted == false)
        #expect(items[0].text == "buy eggs")
    }

    @Test("deserializes checked checkbox with lowercase x")
    func deserializeCheckboxCheckedLower() {
        let items = MarkdownSerializer.deserialize("- [x] buy eggs")
        #expect(items.count == 1)
        #expect(items[0].isCompleted == true)
    }

    @Test("deserializes checked checkbox with uppercase X")
    func deserializeCheckboxCheckedUpper() {
        let items = MarkdownSerializer.deserialize("- [X] buy eggs")
        #expect(items.count == 1)
        #expect(items[0].isCompleted == true)
    }

    @Test("deserializes - as bullet")
    func deserializeDashBullet() {
        let items = MarkdownSerializer.deserialize("- milk")
        #expect(items[0].itemType == .bullet)
        #expect(items[0].text == "milk")
    }

    @Test("deserializes * as bullet")
    func deserializeStarBullet() {
        let items = MarkdownSerializer.deserialize("* milk")
        #expect(items[0].itemType == .bullet)
        #expect(items[0].text == "milk")
    }

    @Test("deserializes 2-space indentation")
    func deserializeTwoSpaceIndent() {
        let items = MarkdownSerializer.deserialize("  - [ ] sub-item")
        #expect(items[0].indentLevel == 1)
    }

    @Test("deserializes 4-space indentation as level 2")
    func deserializeFourSpaceIndent() {
        let items = MarkdownSerializer.deserialize("    - [ ] deep item")
        #expect(items[0].indentLevel == 2)
    }

    @Test("deserializes tab indentation")
    func deserializeTabIndent() {
        let items = MarkdownSerializer.deserialize("\t- [ ] tabbed")
        #expect(items[0].indentLevel == 1)
    }

    @Test("deserializes plain text")
    func deserializePlain() {
        let items = MarkdownSerializer.deserialize("just text")
        #expect(items[0].itemType == .plain)
        #expect(items[0].text == "just text")
    }

    @Test("deserializes empty string to empty array")
    func deserializeEmpty() {
        let items = MarkdownSerializer.deserialize("")
        #expect(items.isEmpty)
    }

    @Test("preserves bold/italic in text")
    func preserveFormatting() {
        let items = MarkdownSerializer.deserialize("- **bold** and *italic*")
        #expect(items[0].text == "**bold** and *italic*")
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
        let serialized = MarkdownSerializer.serialize(items: original)
        let deserialized = MarkdownSerializer.deserialize(serialized)

        #expect(deserialized.count == original.count)
        for (orig, deser) in zip(original, deserialized) {
            #expect(deser.text == orig.text)
            #expect(deser.itemType == orig.itemType)
            #expect(deser.isCompleted == orig.isCompleted)
            #expect(deser.indentLevel == orig.indentLevel)
        }
    }
}
