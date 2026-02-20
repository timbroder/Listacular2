import SwiftUI

struct ItemRow: View {
    @Binding var item: ListItem
    var onToggleComplete: () -> Void = {}
    var onSubmit: () -> Void = {}
    var showRichText: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            itemTypeIcon
                .foregroundStyle(item.isCompleted ? .secondary : .primary)

            if item.itemType == .heading {
                TextField("Heading", text: $item.text)
                    .font(.headline)
                    .fontWeight(.bold)
                    .onSubmit { onSubmit() }
            } else if showRichText {
                TextField("Item", text: $item.text)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .onSubmit { onSubmit() }
            } else {
                TextField("Item", text: $item.text)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .onSubmit { onSubmit() }
            }

            if let dueDate = item.dueDate {
                Text(dueDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(dueDate < Date() ? .red : .secondary)
            }
        }
        .padding(.leading, CGFloat(item.indentLevel) * 20)
        .contextMenu {
            Section("Item Type") {
                ForEach(ItemType.allCases, id: \.self) { type in
                    Button {
                        item.itemType = type
                    } label: {
                        Label {
                            Text(type.displayName)
                        } icon: {
                            if item.itemType == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var itemTypeIcon: some View {
        switch item.itemType {
        case .heading:
            Color.clear
                .frame(width: 4, height: 20)
        case .plain:
            Color.clear
                .frame(width: 4, height: 20)
        case .bullet:
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .frame(width: 20)
        case .checkbox:
            Button {
                onToggleComplete()
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .frame(width: 20)
            }
            .buttonStyle(.plain)
        }
    }
}
