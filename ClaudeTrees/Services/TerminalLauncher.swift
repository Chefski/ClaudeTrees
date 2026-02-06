//
//  TerminalLauncher.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import AppKit

enum TerminalApp: String, CaseIterable, Codable, Identifiable {
    case ghostty = "Ghostty"
    case terminal = "Terminal"
    case iterm = "iTerm2"

    var id: String { rawValue }
}

struct TerminalLauncher {

    static func open(path: String, terminal: TerminalApp, claudeCLIPath: String) {
        let expandedCLI = NSString(string: claudeCLIPath).expandingTildeInPath
        let command = "cd \(shellEscape(path)) && \(shellEscape(expandedCLI))"

        switch terminal {
        case .ghostty:
            openGhostty(command: command)
        case .terminal:
            openTerminalApp(command: command)
        case .iterm:
            openITerm(command: command)
        }
    }

    // MARK: - Terminal Implementations

    private static func openGhostty(command: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Ghostty", "--args", "-e", command]
        try? process.run()
    }

    private static func openTerminalApp(command: String) {
        let src = """
        tell application "Terminal"
            activate
            do script "\(command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))"
        end tell
        """
        if let script = NSAppleScript(source: src) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
        }
    }

    private static func openITerm(command: String) {
        let src = """
        tell application "iTerm2"
            activate
            create window with default profile command "\(command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))"
        end tell
        """
        if let script = NSAppleScript(source: src) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
        }
    }

    private static func shellEscape(_ str: String) -> String {
        "'" + str.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
