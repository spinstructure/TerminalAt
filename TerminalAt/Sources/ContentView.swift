import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    @State private var selectedPath: String?
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            results
            Divider()
            footer
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(minWidth: 600, minHeight: 420)
        .alert(
            "TerminalAt",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onDrop(
            of: [UTType.fileURL.identifier],
            isTargeted: $isDropTargeted,
            perform: handleDrop
        )
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 3, dash: [8, 5])
                    )
                    .padding(10)
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: model.searchText) { _ in
            selectedPath = model.navigationURLs.first?.path
        }
        .onChange(of: model.searchResults) { _ in
            let validPaths = Set(model.navigationURLs.map(\.path))
            if selectedPath == nil || !validPaths.contains(selectedPath!) {
                selectedPath = model.navigationURLs.first?.path
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TerminalAt")
                        .font(.system(size: 25, weight: .semibold))

                    Text("Open Terminal in any folder")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("⌥⌘T")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
            }

            KeyboardSearchField(
                text: $model.searchText,
                placeholder: "Search folders or enter a path…",
                onCommand: handleSearchCommand
            )
            .frame(height: 30)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 16)
    }

    private var results: some View {
        List(selection: $selectedPath) {
            if model.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if !model.favoriteURLs.isEmpty {
                    Section("Favorites") {
                        ForEach(model.favoriteURLs, id: \.path) { url in
                            folderRow(url)
                        }
                    }
                }

                let nonFavoriteRecents = model.recentURLs.filter {
                    !model.isFavorite($0)
                }

                if !nonFavoriteRecents.isEmpty {
                    Section("Recent") {
                        ForEach(nonFavoriteRecents, id: \.path) { url in
                            folderRow(url)
                        }
                    }
                }

                if model.favoriteURLs.isEmpty && model.recentURLs.isEmpty {
                    emptyState
                }
            } else {
                if let directPathURL = model.directPathURL {
                    Section("Path") {
                        folderRow(directPathURL)
                    }
                }

                Section {
                    ForEach(searchResultsWithoutDirectPath, id: \.path) { url in
                        folderRow(url)
                    }

                    if model.isSearching {
                        HStack(spacing: 10) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Searching Spotlight…")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else if searchResultsWithoutDirectPath.isEmpty &&
                                model.directPathURL == nil {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No folders found")
                                .fontWeight(.medium)
                            Text("Try another name, enter a full path, or press ⌘O.")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 10)
                    }
                } header: {
                    Text("Spotlight")
                }
            }
        }
        .listStyle(.inset)
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Button("Choose Folder…") {
                model.chooseFolder()
            }
            .keyboardShortcut("o", modifiers: [.command])

            Spacer()

            Text("↑↓ Select")
            Text("↩ Open")
            Text("Esc Hide")
        }
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("No recent folders yet")
                .fontWeight(.medium)
            Text("Search above, choose a folder, or drop a folder onto this window.")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
    }

    private var searchResultsWithoutDirectPath: [URL] {
        guard let direct = model.directPathURL else {
            return model.searchResults
        }
        return model.searchResults.filter { $0.path != direct.path }
    }

    @ViewBuilder
    private func folderRow(_ url: URL) -> some View {
        FolderRow(
            url: url,
            pathText: model.abbreviatedPath(url),
            isFavorite: model.isFavorite(url),
            open: {
                selectedPath = url.path
                model.openFolder(url)
            },
            toggleFavorite: {
                model.toggleFavorite(url)
            },
            removeFromRecents: {
                model.removeFromRecents(url)
            }
        )
        .tag(url.path)
    }

    private func handleSearchCommand(_ command: SearchKeyCommand) {
        let urls = model.navigationURLs

        switch command {
        case .down:
            moveSelection(by: 1, in: urls)
        case .up:
            moveSelection(by: -1, in: urls)
        case .enter:
            if
                let selectedPath,
                let selected = urls.first(where: { $0.path == selectedPath })
            {
                model.openFolder(selected)
            } else {
                model.openBestMatch()
            }
        case .escape:
            NSApp.keyWindow?.orderOut(nil)
        }
    }

    private func moveSelection(by delta: Int, in urls: [URL]) {
        guard !urls.isEmpty else { return }

        let currentIndex: Int
        if
            let selectedPath,
            let index = urls.firstIndex(where: { $0.path == selectedPath })
        {
            currentIndex = index
        } else {
            currentIndex = delta > 0 ? -1 : 0
        }

        let next = (currentIndex + delta + urls.count) % urls.count
        selectedPath = urls[next].path
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(
            forTypeIdentifier: UTType.fileURL.identifier,
            options: nil
        ) { item, _ in
            let url: URL?

            if let data = item as? Data {
                url = URL(dataRepresentation: data, relativeTo: nil)
            } else if let fileURL = item as? URL {
                url = fileURL
            } else if let nsURL = item as? NSURL {
                url = nsURL as URL
            } else {
                url = nil
            }

            guard let url else { return }

            DispatchQueue.main.async {
                model.openFolder(url)
            }
        }

        return true
    }
}

private struct FolderRow: View {
    let url: URL
    let pathText: String
    let isFavorite: Bool
    let open: () -> Void
    let toggleFavorite: () -> Void
    let removeFromRecents: () -> Void

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: "folder.fill")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)
                    .lineLimit(1)

                Text(pathText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .primary : .secondary)
            }
            .buttonStyle(.borderless)
            .help(isFavorite ? "Remove from Favorites" : "Add to Favorites")
        }
        .contentShape(Rectangle())
        .padding(.vertical, 3)
        .onTapGesture(count: 2, perform: open)
        .contextMenu {
            Button("Open in Terminal", action: open)
            Button(
                isFavorite ? "Remove from Favorites" : "Add to Favorites",
                action: toggleFavorite
            )
            Divider()
            Button("Remove from Recents", action: removeFromRecents)
        }
    }
}
