import Foundation
import UIKit
@preconcurrency import SwiftyDropbox

/// Manages bidirectional sync between local files and a Dropbox folder.
/// Configurable sync folder name (default: "Listacular").
@MainActor
final class DropboxSyncService {
    var syncFolderName: String = "Listacular"
    private var remotePath: String { "/\(syncFolderName)" }

    private var client: DropboxClient? {
        DropboxClientsManager.authorizedClient
    }

    var isLinked: Bool { client != nil }

    // MARK: - Auth

    static func authorize(from controller: UIViewController) {
        let scopeRequest = ScopeRequest(
            scopeType: .user,
            scopes: ["files.metadata.read", "files.metadata.write", "files.content.read", "files.content.write"],
            includeGrantedScopes: false
        )
        DropboxClientsManager.authorizeFromControllerV2(
            UIApplication.shared,
            controller: controller,
            loadingStatusDelegate: nil,
            openURL: { UIApplication.shared.open($0) },
            scopeRequest: scopeRequest
        )
    }

    static func handleRedirectURL(_ url: URL, completion: @escaping (Bool) -> Void) {
        _ = DropboxClientsManager.handleRedirectURL(url, includeBackgroundClient: false) { result in
            completion(result != nil)
        }
    }

    static func unlinkClient() {
        DropboxClientsManager.unlinkClients()
    }

    // MARK: - List Remote Files

    func listRemoteFiles() async throws -> [DropboxRemoteFile] {
        guard let client else { throw SyncError.notLinked }

        let response = try await client.files.listFolder(path: remotePath).response()
        let supportedExtensions = Set(FileFormat.allCases.map(\.fileExtension))

        return response.entries.compactMap { entry -> DropboxRemoteFile? in
            guard let file = entry as? Files.FileMetadata else { return nil }
            let ext = (file.name as NSString).pathExtension.lowercased()
            guard supportedExtensions.contains(ext) else { return nil }
            return DropboxRemoteFile(
                name: file.name,
                serverModified: file.serverModified,
                contentHash: file.contentHash ?? "",
                rev: file.rev
            )
        }
    }

    // MARK: - Download

    func downloadFile(name: String) async throws -> String {
        guard let client else { throw SyncError.notLinked }

        let path = "\(remotePath)/\(name)"
        let response = try await client.files.download(path: path).response()
        guard let text = String(data: response.1, encoding: .utf8) else {
            throw SyncError.decodingFailed
        }
        return text
    }

    // MARK: - Upload

    func uploadFile(name: String, content: String) async throws {
        guard let client else { throw SyncError.notLinked }

        let path = "\(remotePath)/\(name)"
        guard let data = content.data(using: .utf8) else {
            throw SyncError.encodingFailed
        }
        _ = try await client.files.upload(path: path, mode: .overwrite, input: data).response()
    }

    // MARK: - Delete

    func deleteFile(name: String) async throws {
        guard let client else { throw SyncError.notLinked }

        let path = "\(remotePath)/\(name)"
        _ = try await client.files.deleteV2(path: path).response()
    }

    // MARK: - Sync

    func sync(localFiles: [LocalFileInfo]) async throws -> SyncResult {
        let remoteFiles = try await listRemoteFiles()
        let remoteByName = Dictionary(uniqueKeysWithValues: remoteFiles.map { ($0.name, $0) })
        let localByName = Dictionary(uniqueKeysWithValues: localFiles.map { ($0.name, $0) })

        var downloads: [(name: String, content: String)] = []
        var uploaded: [String] = []

        for remote in remoteFiles {
            if let local = localByName[remote.name] {
                if remote.contentHash != local.contentHash {
                    let content = try await downloadFile(name: remote.name)
                    downloads.append((remote.name, content))
                }
            } else {
                let content = try await downloadFile(name: remote.name)
                downloads.append((remote.name, content))
            }
        }

        for local in localFiles {
            if remoteByName[local.name] == nil {
                try await uploadFile(name: local.name, content: local.content)
                uploaded.append(local.name)
            }
        }

        return SyncResult(downloaded: downloads, uploaded: uploaded)
    }
}

// MARK: - Supporting Types

struct DropboxRemoteFile: Sendable {
    let name: String
    let serverModified: Date
    let contentHash: String
    let rev: String
}

struct LocalFileInfo: Sendable {
    let name: String
    let content: String
    let contentHash: String
}

struct SyncResult: Sendable {
    let downloaded: [(name: String, content: String)]
    let uploaded: [String]
}

enum SyncError: Error, LocalizedError {
    case notLinked
    case decodingFailed
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .notLinked: "Dropbox account not linked"
        case .decodingFailed: "Failed to decode file content"
        case .encodingFailed: "Failed to encode file content"
        }
    }
}
