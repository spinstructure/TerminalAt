import AppKit
import Foundation

final class AppModel: ObservableObject {
    @Published var searchText: String = "" {
        didSet {
            spotlight.search(searchText)
        }
    }

    @Published private(set) var records: [FolderRecord] = []
    @Published private(set) var searchResults: [URL] = []
    @Published private(set) var isSearching = false
    @Published var errorMessage: String?

    var hideWindow: (() -> Void)?
    var showWindow: (() -> Void)?

    private let spotlight = SpotlightSearcher()
    private let defaultsKey = "TerminalAt.FolderRecords.v1"
    private let recentLimit = 30

    init() {
        loadRecords()

        spotlight.onResultsChanged = { [weak self] urls, searching in
            DispatchQueue.main.async {
                self?.searchResults = urls
                self?.isSearching = searching
            }
        }
    }

    var favoriteURLs: [URL] {
        records
            .filter { $0.isFavorite && isDirectory($0.url) }
            .sorted {
                if $0.lastUsed != $1.lastUsed {
                    return $0.lastUsed > $1.lastUsed
                }
                return $0.url.lastPathComponent.localizedStandardCompare(
                    $1.url.lastPathComponent
                ) == .orderedAscending
            }
            .map(\.url)
    }

    var recentURLs: [URL] {
        records
            .filter {
                $0.lastUsed.timeIntervalSince1970 > 1 &&
                isDirectory($0.url)
            }
            .sorted { $0.lastUsed > $1.lastUsed }
            .prefix(recentLimit)
            .map(\.url)
    }

    var directPathURL: URL? {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        // Treat explicit paths as paths; ordinary search terms remain Spotlight queries.
        guard
            text.hasPrefix("/") ||
            text.hasPrefix("~") ||
            text.hasPrefix(".")
        else {
            return nil
        }

        let expanded = (text as NSString).expandingTildeInPath
        let standardized = URL(fileURLWithPath: expanded).standardizedFileURL
        return isDirectory(standardized) ? standardized : nil
    }

    var navigationURLs: [URL] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            var urls: [URL] = []
            var seen = Set<String>()

            for url in favoriteURLs + recentURLs {
                if seen.insert(url.path).inserted {
                    urls.append(url)
                }
            }
            return urls
        }

        var urls: [URL] = []
        var seen = Set<String>()

        if let directPathURL, seen.insert(directPathURL.path).inserted {
            urls.append(directPathURL)
        }

        for url in searchResults where seen.insert(url.path).inserted {
            urls.append(url)
        }

        return urls
    }

    func openFolder(_ url: URL) {
        guard isDirectory(url) else {
            errorMessage = "That folder no longer exists or is not accessible."
            return
        }

        do {
            try TerminalLauncher.open(at: url)
            recordUse(url)
            searchText = ""
            hideWindow?()
        } catch {
            errorMessage = "TerminalAt could not open Terminal:\n\(error.localizedDescription)"
        }
    }

    func openBestMatch() {
        if let first = navigationURLs.first {
            openFolder(first)
        }
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose a folder to open in Terminal"
        panel.prompt = "Open in Terminal"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.resolvesAliases = true
        panel.canCreateDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            openFolder(url)
        }
    }

    func isFavorite(_ url: URL) -> Bool {
        records.first(where: { $0.path == url.path })?.isFavorite ?? false
    }

    func toggleFavorite(_ url: URL) {
        if let index = records.firstIndex(where: { $0.path == url.path }) {
            records[index].isFavorite.toggle()
        } else {
            records.append(
                FolderRecord(
                    path: url.path,
                    lastUsed: Date(timeIntervalSince1970: 0),
                    isFavorite: true
                )
            )
        }
        saveRecords()
    }

    func removeFromRecents(_ url: URL) {
        guard let index = records.firstIndex(where: { $0.path == url.path }) else {
            return
        }

        if records[index].isFavorite {
            records[index].lastUsed = Date(timeIntervalSince1970: 0)
        } else {
            records.remove(at: index)
        }

        saveRecords()
    }

    func abbreviatedPath(_ url: URL) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if url.path == home {
            return "~"
        }

        if url.path.hasPrefix(home + "/") {
            return "~" + String(url.path.dropFirst(home.count))
        }

        return url.path
    }

    func clearSearch() {
        searchText = ""
    }

    private func recordUse(_ url: URL) {
        if let index = records.firstIndex(where: { $0.path == url.path }) {
            records[index].lastUsed = Date()
        } else {
            records.append(
                FolderRecord(
                    path: url.path,
                    lastUsed: Date(),
                    isFavorite: false
                )
            )
        }

        pruneRecords()
        saveRecords()
    }

    private func pruneRecords() {
        let favorites = records.filter(\.isFavorite)
        let nonFavorites = records
            .filter { !$0.isFavorite }
            .sorted { $0.lastUsed > $1.lastUsed }
            .prefix(recentLimit)

        var merged: [FolderRecord] = []
        var seen = Set<String>()

        for record in favorites + Array(nonFavorites) {
            if seen.insert(record.path).inserted {
                merged.append(record)
            }
        }

        records = merged
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        )
        return exists && isDirectory.boolValue
    }

    private func loadRecords() {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let decoded = try? JSONDecoder().decode([FolderRecord].self, from: data)
        else {
            records = []
            return
        }

        records = decoded
    }

    private func saveRecords() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
