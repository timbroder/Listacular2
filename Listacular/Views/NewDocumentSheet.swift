import SwiftUI

struct NewDocumentSheet: View {
    @Environment(DocumentStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var fileFormat: FileFormat = .plainText
    @State private var selectedTemplate: ListTemplate?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("List Name", text: $title)
                    Picker("Format", selection: $fileFormat) {
                        ForEach(FileFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                }

                Section("Templates") {
                    Button("Blank List") {
                        selectedTemplate = nil
                    }
                    .foregroundStyle(selectedTemplate == nil ? .primary : .secondary)

                    ForEach(ListTemplate.builtIn) { template in
                        Button {
                            selectedTemplate = template
                            if title.isEmpty {
                                title = template.name
                            }
                        } label: {
                            Label(template.name, systemImage: template.icon)
                                .foregroundStyle(selectedTemplate?.name == template.name ? .primary : .secondary)
                        }
                    }
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createDocument()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func createDocument() {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let doc = store.createDocument(
            title: name.isEmpty ? "Untitled" : name,
            fileFormat: fileFormat
        )
        if let template = selectedTemplate {
            for itemText in template.items {
                let item = store.addItem(to: doc)
                if let idx = doc.items.firstIndex(where: { $0.id == item.id }) {
                    doc.items[idx].text = itemText
                }
            }
        }
    }
}
