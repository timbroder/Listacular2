import Foundation

/// Predefined templates for common list types.
struct ListTemplate: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let icon: String
    let items: [String]

    static let builtIn: [ListTemplate] = [
        ListTemplate(
            name: "Grocery List",
            icon: "cart",
            items: ["Fruits & Vegetables", "Dairy", "Meat", "Bread", "Snacks", "Beverages"]
        ),
        ListTemplate(
            name: "Packing List",
            icon: "suitcase",
            items: ["Clothes", "Toiletries", "Electronics", "Documents", "Medications", "Chargers"]
        ),
        ListTemplate(
            name: "Meeting Agenda",
            icon: "person.3",
            items: ["Welcome & Introductions", "Review action items", "Discussion topics", "Next steps", "Schedule follow-up"]
        ),
        ListTemplate(
            name: "Weekly Plan",
            icon: "calendar",
            items: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        ),
        ListTemplate(
            name: "Project Checklist",
            icon: "hammer",
            items: ["Define scope", "Research", "Design", "Implement", "Test", "Deploy", "Review"]
        ),
    ]
}
