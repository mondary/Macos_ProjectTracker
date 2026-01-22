import Foundation

struct Project: Identifiable, Codable {
    var id: String { path }
    let name: String
    let path: String
    var lastUpdated: Date
    var isDirty: Bool
    var aheadCount: Int
    var behindCount: Int
    var branch: String
    var summary: String?
    var remoteURL: String?
    var description: String?
    var hasIcon: Bool
    var hasReadme: Bool
    
    var hasChanges: Bool {
        isDirty || aheadCount > 0 || behindCount > 0
    }

    var isLinkedToGitHub: Bool {
        guard let remoteURL, !remoteURL.isEmpty else { return false }
        return remoteURL.localizedCaseInsensitiveContains("github.com")
    }

    var isUpToDate: Bool {
        !hasChanges
    }
}
