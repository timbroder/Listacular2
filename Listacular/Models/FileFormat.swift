import Foundation

/// Supported file formats for list documents.
enum FileFormat: String, Codable, Sendable, CaseIterable {
    case plainText = "txt"
    case taskPaper = "taskpaper"
    case markdown = "md"

    var fileExtension: String { rawValue }

    var displayName: String {
        switch self {
        case .plainText: "Plain Text"
        case .taskPaper: "TaskPaper"
        case .markdown: "Markdown"
        }
    }
}
