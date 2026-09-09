import SnapshotTesting
import SwiftUI
import XCTest
@testable import Listacular

final class DocumentEditorSnapshotTests: XCTestCase {
    override func invokeTest() {
        // isRecording = true
        super.invokeTest()
    }

    @MainActor
    private func makeEditor() -> some View {
        let store = DocumentStore()
        let doc = ListDocument(
            title: "Packing List",
            items: [
                ListItem(text: "Clothes", itemType: .heading),
                ListItem(text: "Shirts", itemType: .checkbox, indentLevel: 1),
                ListItem(text: "Pants", itemType: .checkbox, isCompleted: true, indentLevel: 1),
                ListItem(text: "Toiletries", itemType: .heading),
                ListItem(text: "Toothbrush", itemType: .checkbox),
                ListItem(text: "Deodorant", itemType: .checkbox),
                ListItem(text: "Misc", itemType: .heading),
                ListItem(text: "Remember to lock door", itemType: .plain),
                ListItem(text: "Charger", itemType: .bullet),
            ]
        )
        store.documents = [doc]

        return NavigationStack {
            DocumentEditorView(document: doc)
        }
        .environment(store)
    }

    @MainActor
    func testMixedContentList() {
        let view = makeEditor()
        assertSnapshot(
            of: UIHostingController(rootView: view),
            as: .image(size: CGSize(width: 375, height: 600))
        )
    }
}
