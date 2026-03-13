import SwiftUI

struct DropboxFolderPicker: View {
    @Binding var selectedPath: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            FolderListView(path: "", selectedPath: $selectedPath, dismiss: dismiss)
                .navigationTitle("Choose Folder")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

private struct FolderListView: View {
    let path: String
    @Binding var selectedPath: String
    let dismiss: DismissAction

    @State private var folders: [DropboxFolder] = []
    @State private var isLoading = true
    @State private var error: String?

    private var displayTitle: String {
        if path.isEmpty { return "Dropbox" }
        return (path as NSString).lastPathComponent
    }

    var body: some View {
        List {
            Section {
                Button {
                    selectedPath = path
                    dismiss()
                } label: {
                    Label("Select \"\(displayTitle)\"", systemImage: "checkmark.circle")
                }
            }

            Section {
                if isLoading {
                    ProgressView("Loading folders...")
                } else if let error {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error)
                            .foregroundStyle(.secondary)
                        Button("Retry") { Task { await loadFolders() } }
                    }
                } else if folders.isEmpty {
                    Text("No subfolders")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(folders) { folder in
                        NavigationLink(value: folder) {
                            Label(folder.name, systemImage: "folder")
                        }
                    }
                }
            }
        }
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: DropboxFolder.self) { folder in
            FolderListView(path: folder.pathDisplay, selectedPath: $selectedPath, dismiss: dismiss)
        }
        .task { await loadFolders() }
    }

    private func loadFolders() async {
        isLoading = true
        error = nil
        let service = DropboxSyncService()
        do {
            folders = try await service.listFolders(at: path)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
