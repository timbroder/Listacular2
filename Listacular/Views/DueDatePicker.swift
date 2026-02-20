import SwiftUI

struct DueDatePicker: View {
    @Environment(\.dismiss) private var dismiss
    @State var date: Date
    let existingDate: Date?
    let onSave: (Date?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Due Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)

                if existingDate != nil {
                    Button("Remove Due Date", role: .destructive) {
                        onSave(nil)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Set Due Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(date)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
