import SwiftUI

enum SidebarDestination: Hashable {
    case search
    case overview
    case tags
}

struct ContentView: View {
    @Environment(DocumentStore.self) private var store
    @State private var showSettings = false

    var body: some View {
        NavigationSplitView {
            DocumentListView()
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        HStack {
                            NavigationLink(value: SidebarDestination.overview) {
                                Label("Overview", systemImage: "house")
                            }
                            NavigationLink(value: SidebarDestination.search) {
                                Label("Search", systemImage: "magnifyingglass")
                            }
                            NavigationLink(value: SidebarDestination.tags) {
                                Label("Tags", systemImage: "tag")
                            }
                            Spacer()
                            Button {
                                showSettings = true
                            } label: {
                                Label("Settings", systemImage: "gear")
                            }
                        }
                    }
                }
                .navigationDestination(for: SidebarDestination.self) { destination in
                    switch destination {
                    case .search:
                        SearchView()
                    case .overview:
                        HomeOverviewView()
                    case .tags:
                        TagFilterView()
                    }
                }
        } detail: {
            if let document = store.selectedDocument {
                DocumentEditorView(document: document)
            } else {
                ContentUnavailableView(
                    "No List Selected",
                    systemImage: "checklist",
                    description: Text("Select or create a list to get started.")
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showSettings = false }
                        }
                    }
            }
        }
    }
}
