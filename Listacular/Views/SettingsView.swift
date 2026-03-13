import SwiftUI
@preconcurrency import SwiftyDropbox

struct SettingsView: View {
    @Environment(DocumentStore.self) private var store
    @State private var syncFolderName = ""
    @State private var isLinked = false
    @State private var isSyncing = false
    @State private var lastSyncMessage: String?
    @State private var showFolderPicker = false

    var body: some View {
        Form {
            Section("Dropbox Sync") {
                if isLinked {
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Button {
                        showFolderPicker = true
                    } label: {
                        HStack {
                            Text("Sync Folder")
                            Spacer()
                            Text(syncFolderName.isEmpty ? "Root" : (syncFolderName as NSString).lastPathComponent)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)

                    Button {
                        Task { await performSync() }
                    } label: {
                        if isSyncing {
                            ProgressView()
                        } else {
                            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(isSyncing)

                    if let message = lastSyncMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button("Disconnect Dropbox", role: .destructive) {
                        DropboxSyncService.unlinkClient()
                        isLinked = false
                    }
                } else {
                    Button {
                        linkDropbox()
                    } label: {
                        Label("Connect Dropbox", systemImage: "link")
                    }
                }
            }

            Section("Import") {
                ImportDocumentButton()
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            isLinked = DropboxClientsManager.authorizedClient != nil
        }
        .sheet(isPresented: $showFolderPicker) {
            DropboxFolderPicker(selectedPath: $syncFolderName)
        }
    }

    private func linkDropbox() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              var controller = scene.windows.first?.rootViewController else { return }
        while let presented = controller.presentedViewController {
            controller = presented
        }
        DropboxSyncService.authorize(from: controller)
    }

    private func performSync() async {
        isSyncing = true
        defer { isSyncing = false }

        let syncService = DropboxSyncService()
        syncService.syncFolderName = syncFolderName

        let localFiles = store.documents.map { doc in
            let name = "\(doc.title).\(doc.fileFormat.fileExtension)"
            let content = DocumentStore.serializePublic(doc.items, format: doc.fileFormat)
            return LocalFileInfo(name: name, content: content, contentHash: "")
        }

        do {
            let result = try await syncService.sync(localFiles: localFiles)

            for download in result.downloaded {
                let name = (download.name as NSString).deletingPathExtension
                let ext = (download.name as NSString).pathExtension.lowercased()
                let format = FileFormat.allCases.first { $0.fileExtension == ext } ?? .plainText

                if let existing = store.documents.first(where: { $0.title == name }) {
                    existing.items = DocumentStore.deserializePublic(download.content, format: format)
                    existing.modifiedAt = .now
                } else {
                    let items = DocumentStore.deserializePublic(download.content, format: format)
                    let doc = ListDocument(title: name, items: items, fileFormat: format)
                    store.documents.append(doc)
                }
            }

            lastSyncMessage = "Synced: \(result.downloaded.count) downloaded, \(result.uploaded.count) uploaded"
        } catch {
            lastSyncMessage = "Sync failed: \(error.localizedDescription)"
        }
    }
}

