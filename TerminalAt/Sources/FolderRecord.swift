import Foundation

struct FolderRecord: Codable, Hashable, Identifiable {
    var path: String
    var lastUsed: Date
    var isFavorite: Bool

    var id: String { path }

    var url: URL {
        URL(fileURLWithPath: path, isDirectory: true)
    }
}
