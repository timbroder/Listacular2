import Testing
@testable import Listacular

@Suite("ItemType")
struct ItemTypeTests {
    @Test("allCases includes heading")
    func allCasesIncludesHeading() {
        #expect(ItemType.allCases.contains(.heading))
    }

    @Test("allCases has 4 cases")
    func allCasesCount() {
        #expect(ItemType.allCases.count == 4)
    }

    @Test("allCases order is heading, plain, bullet, checkbox")
    func allCasesOrder() {
        let cases = ItemType.allCases
        #expect(cases[0] == .heading)
        #expect(cases[1] == .plain)
        #expect(cases[2] == .bullet)
        #expect(cases[3] == .checkbox)
    }

    @Test("displayName returns correct values")
    func displayNames() {
        #expect(ItemType.heading.displayName == "Heading")
        #expect(ItemType.plain.displayName == "Plain Text")
        #expect(ItemType.bullet.displayName == "Bullet")
        #expect(ItemType.checkbox.displayName == "Checkbox")
    }

    @Test("raw values are stable strings")
    func rawValues() {
        #expect(ItemType.heading.rawValue == "heading")
        #expect(ItemType.plain.rawValue == "plain")
        #expect(ItemType.bullet.rawValue == "bullet")
        #expect(ItemType.checkbox.rawValue == "checkbox")
    }
}

@Suite("FileFormat")
struct FileFormatTests {
    @Test("allCases has 3 formats")
    func allCasesCount() {
        #expect(FileFormat.allCases.count == 3)
    }

    @Test("fileExtension returns correct values")
    func fileExtensions() {
        #expect(FileFormat.plainText.fileExtension == "txt")
        #expect(FileFormat.taskPaper.fileExtension == "taskpaper")
        #expect(FileFormat.markdown.fileExtension == "md")
    }

    @Test("displayName returns correct values")
    func displayNames() {
        #expect(FileFormat.plainText.displayName == "Plain Text")
        #expect(FileFormat.taskPaper.displayName == "TaskPaper")
        #expect(FileFormat.markdown.displayName == "Markdown")
    }

    @Test("raw values match file extensions")
    func rawValues() {
        #expect(FileFormat.plainText.rawValue == "txt")
        #expect(FileFormat.taskPaper.rawValue == "taskpaper")
        #expect(FileFormat.markdown.rawValue == "md")
    }
}
