import SwiftUI

struct DocumentEditorView: View {
    @Environment(DocumentStore.self) private var store
    @Bindable var document: ListDocument
    @FocusState private var focusedItemID: UUID?
    @State private var dueDateItem: ListItem?
    @State private var selectedDueDate = Date()
    @State private var showRichText = true

    var body: some View {
        List {
            ForEach(Array(document.items.enumerated()), id: \.element.id) { index, item in
                ItemRow(
                    item: Binding(
                        get: { document.items[safe: index] ?? item },
                        set: { document.items[safe: index] = $0 }
                    ),
                    onToggleComplete: {
                        store.toggleComplete(item, in: document)
                    },
                    onSubmit: {
                        insertItemBelow(at: index)
                    },
                    showRichText: showRichText
                )
                .focused($focusedItemID, equals: item.id)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        store.deleteItem(item, from: document)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        selectedDueDate = item.dueDate ?? Date()
                        dueDateItem = item
                    } label: {
                        Label("Due Date", systemImage: "calendar")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        store.toggleComplete(item, in: document)
                    } label: {
                        Label(
                            item.isCompleted ? "Undo" : "Done",
                            systemImage: item.isCompleted ? "arrow.uturn.backward" : "checkmark"
                        )
                    }
                    .tint(item.isCompleted ? .orange : .green)
                }
            }
            .onMove { source, destination in
                store.moveItems(in: document, from: source, to: destination)
            }
            .onDelete { offsets in
                for index in offsets.sorted().reversed() {
                    store.deleteItem(document.items[index], from: document)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(document.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        let newItem = store.addItem(to: document)
                        focusedItemID = newItem.id
                    } label: {
                        Label("New Item", systemImage: "plus")
                    }
                    Button {
                        pasteFromClipboard()
                    } label: {
                        Label("Paste as Items", systemImage: "doc.on.clipboard")
                    }
                    Divider()
                    Button(role: .destructive) {
                        store.removeCompleted(from: document)
                    } label: {
                        Label("Remove Completed", systemImage: "trash")
                    }
                    .disabled(!document.items.contains(where: \.isCompleted))
                } label: {
                    Label("Add", systemImage: "plus")
                } primaryAction: {
                    let newItem = store.addItem(to: document)
                    focusedItemID = newItem.id
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showRichText.toggle()
                } label: {
                    Label(
                        showRichText ? "Raw Text" : "Rich Text",
                        systemImage: showRichText ? "doc.plaintext" : "doc.richtext"
                    )
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            ToolbarItemGroup(placement: .keyboard) {
                keyboardAccessoryRow
            }
        }
        .sheet(item: $dueDateItem) { item in
            DueDatePicker(
                date: selectedDueDate,
                existingDate: item.dueDate
            ) { date in
                store.setDueDate(date, for: item, in: document)
            }
        }
    }

    // MARK: - Keyboard Accessory Row

    @ViewBuilder
    private var keyboardAccessoryRow: some View {
        Button { indentFocusedItem() } label: { Image(systemName: "increase.indent") }
        Button { outdentFocusedItem() } label: { Image(systemName: "decrease.indent") }
        Divider()
        Button { setFocusedItemType(.heading) } label: { Image(systemName: "textformat.size.larger") }
        Button { setFocusedItemType(.plain) } label: { Image(systemName: "text.alignleft") }
        Button { setFocusedItemType(.bullet) } label: { Image(systemName: "list.bullet") }
        Button { setFocusedItemType(.checkbox) } label: { Image(systemName: "checklist") }
        Spacer()
        Button { focusedItemID = nil } label: { Image(systemName: "keyboard.chevron.compact.down") }
    }

    // MARK: - Actions

    private func insertItemBelow(at index: Int) {
        let current = document.items[index]
        let newItem = store.addItem(
            to: document,
            after: index,
            itemType: current.itemType,
            indentLevel: current.indentLevel
        )
        focusedItemID = newItem.id
    }

    private func indentFocusedItem() {
        guard let id = focusedItemID,
              let idx = document.items.firstIndex(where: { $0.id == id }) else { return }
        document.items[idx].indentLevel += 1
        document.modifiedAt = .now
    }

    private func outdentFocusedItem() {
        guard let id = focusedItemID,
              let idx = document.items.firstIndex(where: { $0.id == id }),
              document.items[idx].indentLevel > 0 else { return }
        document.items[idx].indentLevel -= 1
        document.modifiedAt = .now
    }

    private func setFocusedItemType(_ type: ItemType) {
        guard let id = focusedItemID,
              let idx = document.items.firstIndex(where: { $0.id == id }) else { return }
        document.items[idx].itemType = type
        document.modifiedAt = .now
    }

    private func pasteFromClipboard() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else { return }
        let focusedIndex: Int?
        if let id = focusedItemID {
            focusedIndex = document.items.firstIndex(where: { $0.id == id })
        } else {
            focusedIndex = nil
        }
        store.pasteItems(text: text, into: document, at: focusedIndex)
    }
}

// MARK: - Safe array subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        get { indices.contains(index) ? self[index] : nil }
        set {
            if let newValue, indices.contains(index) {
                self[index] = newValue
            }
        }
    }
}
