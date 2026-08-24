import Foundation

enum TerminalLauncher {
    static func open(at folderURL: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Terminal", folderURL.path]
        try process.run()
    }
}
