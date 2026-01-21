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
    
    var hasChanges: Bool {
        isDirty || aheadCount > 0 || behindCount > 0
    }
}
