import SnapshotTesting
import SwiftUI
import XCTest
@testable import Listacular

final class ScreenSnapshotTests: XCTestCase {
    override func invokeTest() {
        // isRecording = true
        super.invokeTest()
    }

    private let size = CGSize(width: 375, height: 667)

    // MARK: - HomeOverviewView

    @MainActor
    func testHomeOverviewWithTasks() {
        let store = DocumentStore()
        let doc = ListDocument(
            title: "Tasks",
            items: [
                ListItem(
                    text: "Overdue task",
                    itemType: .checkbox,
                    dueDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())
                ),
                ListItem(
                    text: "Today task",
                    itemType: .checkbox,
                    dueDate: Date()
                ),
                ListItem(
                    text: "Future task",
                    itemType: .checkbox,
                    dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())
                ),
            ]
        )
        store.documents = [doc]

        let view = NavigationStack {
            HomeOverviewView()
        }
        .environment(store)

        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: size))
    }

    @MainActor
    func testHomeOverviewEmpty() {
        let store = DocumentStore()
        let view = NavigationStack {
            HomeOverviewView()
        }
        .environment(store)

        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: size))
    }

    // MARK: - SearchView

    @MainActor
    func testSearchViewEmpty() {
        let store = DocumentStore()
        let view = NavigationStack {
            SearchView()
        }
        .environment(store)

        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: size))
    }

    // MARK: - NewDocumentSheet

    @MainActor
    func testNewDocumentSheet() {
        let store = DocumentStore()
        let view = NewDocumentSheet()
            .environment(store)

        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: size))
    }

    // MARK: - TagFilterView

    @MainActor
    func testTagFilterViewEmpty() {
        let store = DocumentStore()
        let view = NavigationStack {
            TagFilterView()
        }
        .environment(store)

        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: size))
    }

    @MainActor
    func testTagFilterViewWithTags() {
        let store = DocumentStore()
        let doc = ListDocument(
            title: "Work",
            items: [
                ListItem(text: "meeting @work @urgent", itemType: .checkbox),
                ListItem(text: "exercise @health", itemType: .checkbox),
            ]
        )
        store.documents = [doc]

        let view = NavigationStack {
            TagFilterView()
        }
        .environment(store)

        assertSnapshot(of: UIHostingController(rootView: view), as: .image(size: size))
    }
}
