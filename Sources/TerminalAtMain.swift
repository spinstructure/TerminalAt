import AppKit
import SwiftUI

@main
struct TerminalAtMain {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.regular)
        application.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow!
    private let model = AppModel()
    private var hotKeyManager: HotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()
        buildWindow()

        model.hideWindow = { [weak self] in
            self?.window.orderOut(nil)
        }

        model.showWindow = { [weak self] in
            self?.showMainWindow()
        }

        hotKeyManager = HotKeyManager { [weak self] in
            self?.showMainWindow()
        }

        if let status = hotKeyManager?.registerOptionCommandT(), status != 0 {
            model.errorMessage = "The global ⌥⌘T shortcut could not be registered. Another app may already be using it. TerminalAt itself will still work normally from the Dock."
        }

        showMainWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        showMainWindow()
        return true
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide rather than destroy the window so the global hotkey remains useful.
        sender.orderOut(nil)
        return false
    }

    private func buildWindow() {
        let content = ContentView()
            .environmentObject(model)

        let hostingController = NSHostingController(rootView: content)

        window = NSWindow(contentViewController: hostingController)
        window.title = "TerminalAt"
        window.styleMask = [
            .titled,
            .closable,
            .miniaturizable,
            .resizable,
            .fullSizeContentView
        ]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 600, height: 420)
        window.setContentSize(NSSize(width: 720, height: 540))
        window.center()
        window.delegate = self
    }

    private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        NotificationCenter.default.post(name: .terminalAtFocusSearch, object: nil)
    }

    @objc private func chooseFolderFromMenu() {
        model.chooseFolder()
    }

    @objc private func hideWindowFromMenu() {
        window.orderOut(nil)
    }

    private func buildMainMenu() {
        let mainMenu = NSMenu()

        // TerminalAt menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu(title: "TerminalAt")
        appMenuItem.submenu = appMenu

        let about = NSMenuItem(
            title: "About TerminalAt",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        about.target = NSApp
        appMenu.addItem(about)
        appMenu.addItem(.separator())

        let hide = NSMenuItem(
            title: "Hide TerminalAt",
            action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h"
        )
        hide.target = NSApp
        appMenu.addItem(hide)

        appMenu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit TerminalAt",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quit.target = NSApp
        appMenu.addItem(quit)

        // File menu
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu

        let choose = NSMenuItem(
            title: "Choose Folder…",
            action: #selector(chooseFolderFromMenu),
            keyEquivalent: "o"
        )
        choose.target = self
        fileMenu.addItem(choose)

        fileMenu.addItem(.separator())

        let close = NSMenuItem(
            title: "Close",
            action: #selector(hideWindowFromMenu),
            keyEquivalent: "w"
        )
        close.target = self
        fileMenu.addItem(close)

        NSApp.mainMenu = mainMenu
    }
}
