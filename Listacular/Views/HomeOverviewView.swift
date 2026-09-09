import SwiftUI

struct HomeOverviewView: View {
    @Environment(DocumentStore.self) private var store

    private var overdueTasks: [(document: ListDocument, item: ListItem)] {
        let now = Date()
        return store.documents.flatMap { doc in
            doc.items.compactMap { item -> (ListDocument, ListItem)? in
                guard let due = item.dueDate, due < now, !item.isCompleted else { return nil }
                return (doc, item)
            }
        }
    }

    private var todayTasks: [(document: ListDocument, item: ListItem)] {
        let calendar = Calendar.current
        return store.documents.flatMap { doc in
            doc.items.compactMap { item -> (ListDocument, ListItem)? in
                guard let due = item.dueDate, calendar.isDateInToday(due), !item.isCompleted else { return nil }
                return (doc, item)
            }
        }
    }

    var body: some View {
        List {
            if !overdueTasks.isEmpty {
                Section {
                    ForEach(overdueTasks, id: \.item.id) { doc, item in
                        taskRow(item: item, documentTitle: doc.title)
                    }
                } header: {
                    Label("Overdue", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }

            if !todayTasks.isEmpty {
                Section {
                    ForEach(todayTasks, id: \.item.id) { doc, item in
                        taskRow(item: item, documentTitle: doc.title)
                    }
                } header: {
                    Label("Today", systemImage: "calendar")
                }
            }

            if overdueTasks.isEmpty && todayTasks.isEmpty {
                ContentUnavailableView(
                    "All Clear",
                    systemImage: "checkmark.circle",
                    description: Text("No overdue or upcoming tasks.")
                )
            }
        }
        .navigationTitle("Overview")
    }

    private func taskRow(item: ListItem, documentTitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.text)
                .font(.body)
            HStack {
                Text(documentTitle)
                if let due = item.dueDate {
                    Text("·")
                    Text(due, style: .relative)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
