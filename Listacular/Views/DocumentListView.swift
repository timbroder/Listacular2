import SwiftUI

struct DocumentListView: View {
    @Environment(DocumentStore.self) private var store
    @State private var showNewDocSheet = false
    @State private var renamingDocument: ListDocument?
    @State private var renameText = ""

    var body: some View {
        @Bindable var store = store

        List(store.documents, selection: $store.selectedDocumentID) { document in
            NavigationLink(value: document.id) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title)
                        .font(.body)
                    HStack(spacing: 4) {
                        Text("\(document.items.count) items")
                        Text("·")
                        Text(document.fileFormat.displayName)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .contextMenu {
                Button {
                    renameText = document.title
                    renamingDocument = document
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    store.deleteDocument(document)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    store.deleteDocument(document)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Lists")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewDocSheet = true
                } label: {
                    Label("New List", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewDocSheet) {
            NewDocumentSheet()
        }
        .alert("Rename List", isPresented: Binding(
            get: { renamingDocument != nil },
            set: { if !$0 { renamingDocument = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { renamingDocument = nil }
            Button("Rename") {
                if let doc = renamingDocument {
                    store.renameDocument(doc, to: renameText)
                }
                renamingDocument = nil
            }
        }
        .overlay {
            if store.documents.isEmpty {
                ContentUnavailableView {
                    Label("No Lists", systemImage: "checklist")
                } description: {
                    Text("Tap + to create your first list.")
                }
            }
        }
    }
}
