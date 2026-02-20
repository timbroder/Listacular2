import SnapshotTesting
import SwiftUI
import XCTest
@testable import Listacular

@MainActor
final class ItemRowSnapshotTests: XCTestCase {
    override func invokeTest() {
        // Set to true to re-record reference images
        // isRecording = true
        super.invokeTest()
    }

    private func makeRow(
        text: String = "Test item",
        itemType: ItemType = .plain,
        isCompleted: Bool = false,
        indentLevel: Int = 0,
        dueDate: Date? = nil,
        showRichText: Bool = true
    ) -> some View {
        let item = ListItem(
            text: text,
            itemType: itemType,
            isCompleted: isCompleted,
            indentLevel: indentLevel,
            dueDate: dueDate
        )
        return ItemRow(
            item: .constant(item),
            showRichText: showRichText
        )
        .frame(width: 375)
        .padding()
    }

    // MARK: - Item Types

    func testHeading() {
        let view = makeRow(text: "Packing", itemType: .heading)
        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: CGSize(width: 375, height: 60)))
    }

    func testPlainText() {
        let view = makeRow(text: "Just a note", itemType: .plain)
        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: CGSize(width: 375, height: 60)))
    }

    func testBullet() {
        let view = makeRow(text: "Milk", itemType: .bullet)
        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: CGSize(width: 375, height: 60)))
    }

    func testCheckboxUnchecked() {
        let view = makeRow(text: "Buy eggs", itemType: .checkbox)
        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: CGSize(width: 375, height: 60)))
    }

    func testCheckboxChecked() {
        let view = makeRow(text: "Buy eggs", itemType: .checkbox, isCompleted: true)
        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: CGSize(width: 375, height: 60)))
    }

    // MARK: - Indentation

    func testIndentLevel1() {
        let view = makeRow(text: "Sub-item", itemType: .checkbox, indentLevel: 1)
        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: CGSize(width: 375, height: 60)))
    }

    func testIndentLevel2() {
        let view = makeRow(text: "Deep item", itemType: .checkbox, indentLevel: 2)
        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: CGSize(width: 375, height: 60)))
    }

    // MARK: - Due Dates

    func testWithDueDate() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let view = makeRow(text: "Future task", itemType: .checkbox, dueDate: futureDate)
        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: CGSize(width: 375, height: 60)))
    }

    func testWithOverdueDueDate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let view = makeRow(text: "Overdue task", itemType: .checkbox, dueDate: pastDate)
        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: CGSize(width: 375, height: 60)))
    }

    // MARK: - Raw text mode

    func testRawTextMode() {
        let view = makeRow(text: "Monospaced text", itemType: .checkbox, showRichText: false)
        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: CGSize(width: 375, height: 60)))
    }
}
