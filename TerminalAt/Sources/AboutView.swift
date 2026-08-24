import AppKit
import SwiftUI

struct AboutView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 52, weight: .regular))
                .accessibilityHidden(true)

            VStack(spacing: 5) {
                Text("TerminalAt")
                    .font(.system(size: 28, weight: .semibold))

                Text("Version \(version)")
                    .foregroundStyle(.secondary)
            }

            Text("Made by Vivek Saxena using ChatGPT/Codex.")
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)

            Divider()

            VStack(spacing: 7) {
                Text("Open Terminal in any folder")
                    .font(.headline)

                Text("TerminalAt provides Spotlight-backed folder search, Favorites, Recents, direct path entry, drag-and-drop, and a global keyboard shortcut.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Text("TerminalAt is provided as-is. The author assumes no responsibility or liability for damage, data loss, system issues, or other consequences arising from its use. Use TerminalAt at your own risk.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Close") {
                NSApp.keyWindow?.close()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(28)
        .frame(width: 460)
    }
}
