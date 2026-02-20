import SwiftUI
import UniformTypeIdentifiers

struct ImportDocumentButton: View {
    @Environment(DocumentStore.self) private var store
    @State private var showFilePicker = false

    var body: some View {
        Button {
            showFilePicker = true
        } label: {
            Label("Import File", systemImage: "square.and.arrow.down")
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.plainText, .text],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    importFile(from: url)
                }
            case .failure:
                break
            }
        }
    }

    private func importFile(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension.lowercased()
        let format = FileFormat.allCases.first { $0.fileExtension == ext } ?? .plainText
        let items = DocumentStore.deserializePublic(content, format: format)
        let doc = ListDocument(title: name, items: items, fileFormat: format)
        store.documents.append(doc)
        store.selectedDocumentID = doc.id
    }
}
