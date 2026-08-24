import Foundation

final class SpotlightSearcher {
    var onResultsChanged: (([URL], Bool) -> Void)?

    private var query: NSMetadataQuery?
    private var observers: [NSObjectProtocol] = []
    private var pendingSearch: DispatchWorkItem?

    deinit {
        stop()
    }

    func search(_ rawText: String) {
        pendingSearch?.cancel()

        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard text.count >= 2 else {
            stop()
            DispatchQueue.main.async { [weak self] in
                self?.onResultsChanged?([], false)
            }
            return
        }

        let work = DispatchWorkItem { [weak self] in
            self?.beginSearch(text)
        }

        pendingSearch = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: work)
    }

    private func beginSearch(_ text: String) {
        stop()

        let metadataQuery = NSMetadataQuery()
        metadataQuery.searchScopes = [NSMetadataQueryUserHomeScope]

        // Restrict to folders and match either the folder name or full path.
        metadataQuery.predicate = NSPredicate(
            format: "%K == %@ AND (%K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@)",
            NSMetadataItemContentTypeKey,
            "public.folder",
            NSMetadataItemFSNameKey,
            text,
            NSMetadataItemPathKey,
            text
        )

        query = metadataQuery

        DispatchQueue.main.async { [weak self] in
            self?.onResultsChanged?([], true)
        }

        let center = NotificationCenter.default

        observers.append(
            center.addObserver(
                forName: .NSMetadataQueryDidFinishGathering,
                object: metadataQuery,
                queue: .main
            ) { [weak self] _ in
                self?.publishResults(isSearching: false)
            }
        )

        observers.append(
            center.addObserver(
                forName: .NSMetadataQueryDidUpdate,
                object: metadataQuery,
                queue: .main
            ) { [weak self] _ in
                self?.publishResults(isSearching: false)
            }
        )

        metadataQuery.start()
    }

    private func publishResults(isSearching: Bool) {
        guard let query else { return }

        query.disableUpdates()

        var urls: [URL] = []
        var seen = Set<String>()

        for index in 0..<query.resultCount {
            guard
                let item = query.result(at: index) as? NSMetadataItem,
                let path = item.value(forAttribute: NSMetadataItemPathKey) as? String
            else {
                continue
            }

            // Keep the default results useful by avoiding hidden/internal locations.
            let components = path.split(separator: "/")
            if components.contains(where: { $0.hasPrefix(".") }) {
                continue
            }

            if path.contains("/Library/") {
                continue
            }

            guard seen.insert(path).inserted else { continue }
            urls.append(URL(fileURLWithPath: path, isDirectory: true))
        }

        query.enableUpdates()

        // Prefer shorter, cleaner matches; then use Finder-like localized sorting.
        urls.sort {
            let lhsName = $0.lastPathComponent
            let rhsName = $1.lastPathComponent

            if lhsName.count != rhsName.count {
                return lhsName.count < rhsName.count
            }

            return lhsName.localizedStandardCompare(rhsName) == .orderedAscending
        }

        onResultsChanged?(Array(urls.prefix(60)), isSearching)
    }

    private func stop() {
        pendingSearch?.cancel()
        pendingSearch = nil

        if let query {
            query.stop()
        }
        query = nil

        let center = NotificationCenter.default
        observers.forEach(center.removeObserver)
        observers.removeAll()
    }
}
