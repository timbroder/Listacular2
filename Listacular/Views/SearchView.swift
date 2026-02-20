import SwiftUI

struct SearchView: View {
    @Environment(DocumentStore.self) private var store
    @State private var query = ""

    private var results: [(document: ListDocument, matchingItems: [ListItem])] {
        store.searchDocuments(query: query)
    }

    var body: some View {
        List {
            ForEach(results, id: \.document.id) { result in
                Section(result.document.title) {
                    ForEach(result.matchingItems) { item in
                        HStack(spacing: 8) {
                            if item.itemType == .checkbox {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                            } else if item.itemType == .bullet {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                            }
                            Text(item.text)
                                .strikethrough(item.isCompleted)
                                .foregroundStyle(item.isCompleted ? .secondary : .primary)
                        }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Search all lists")
        .navigationTitle("Search")
        .overlay {
            if query.isEmpty {
                ContentUnavailableView(
                    "Search Lists",
                    systemImage: "magnifyingglass",
                    description: Text("Search across all your lists and items.")
                )
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
    }
}
