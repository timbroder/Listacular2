import SwiftUI

struct TagFilterView: View {
    @Environment(DocumentStore.self) private var store
    @State private var selectedTag: String?

    private var allTags: [String] { store.allTags() }

    var body: some View {
        List {
            Section("Tags") {
                ForEach(allTags, id: \.self) { tag in
                    Button {
                        selectedTag = tag
                    } label: {
                        Label("@\(tag)", systemImage: "tag")
                    }
                }
            }

            if let tag = selectedTag {
                let results = store.filterByTag(tag)
                Section("Items tagged @\(tag)") {
                    ForEach(results, id: \.document.id) { result in
                        ForEach(result.matchingItems) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.text)
                                Text(result.document.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Tags")
        .overlay {
            if allTags.isEmpty {
                ContentUnavailableView(
                    "No Tags",
                    systemImage: "tag",
                    description: Text("Add @tags to your items to filter by them.")
                )
            }
        }
    }
}
