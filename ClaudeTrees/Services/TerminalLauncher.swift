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
    case warp = "Warp"
    case alacritty = "Alacritty"
    case kitty = "Kitty"
    case wezterm = "WezTerm"
    case rio = "Rio"

    var id: String { rawValue }

    var bundleIdentifier: String {
        switch self {
        case .ghostty:   return "com.mitchellh.ghostty"
        case .terminal:  return "com.apple.Terminal"
        case .iterm:     return "com.googlecode.iterm2"
        case .warp:      return "dev.warp.Warp-Stable"
        case .alacritty: return "org.alacritty"
        case .kitty:     return "net.kovidgoyal.kitty"
        case .wezterm:   return "org.wezfurlong.wezterm"
        case .rio:       return "com.raphaelamorim.rio"
        }
    }

    var appURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }

    var isInstalled: Bool {
        appURL != nil
    }

    static var available: [TerminalApp] {
        allCases.filter { $0.isInstalled }
    }
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
        case .warp:
            openWarp(path: path, command: expandedCLI)
        case .alacritty:
            openAlacritty(path: path, command: expandedCLI)
        case .kitty:
            openKitty(path: path, command: expandedCLI)
        case .wezterm:
            openWezTerm(path: path, command: expandedCLI)
        case .rio:
            openRio(path: path, command: expandedCLI)
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

    private static func openWarp(path: String, command: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Warp", path]
        try? process.run()

        let alert = NSAlert()
        alert.messageText = "Claude CLI Copied"
        alert.informativeText = "Warp doesn't support launching commands automatically. The Claude command has been copied to your clipboard — paste (⌘V) in the Warp window to start."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private static func openAlacritty(path: String, command: String) {
        guard let appURL = TerminalApp.alacritty.appURL else { return }
        let binary = appURL.appendingPathComponent("Contents/MacOS/alacritty")

        let process = Process()
        process.executableURL = binary
        process.arguments = ["--working-directory", path, "-e", "/bin/sh", "-c", command]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            fallback.arguments = ["-a", "Alacritty", "--args", "--working-directory", path, "-e", "/bin/sh", "-c", command]
            try? fallback.run()
        }
    }

    private static func openKitty(path: String, command: String) {
        guard let appURL = TerminalApp.kitty.appURL else { return }
        let binary = appURL.appendingPathComponent("Contents/MacOS/kitty")

        let process = Process()
        process.executableURL = binary
        process.arguments = ["--directory", path, "/bin/sh", "-c", command]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            fallback.arguments = ["-a", "kitty", "--args", "--directory", path, "/bin/sh", "-c", command]
            try? fallback.run()
        }
    }

    private static func openWezTerm(path: String, command: String) {
        guard let appURL = TerminalApp.wezterm.appURL else { return }
        let binary = appURL.appendingPathComponent("Contents/MacOS/wezterm-gui")

        let process = Process()
        process.executableURL = binary
        process.arguments = ["start", "--cwd", path, "--", "/bin/sh", "-c", command]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            fallback.arguments = ["-a", "WezTerm", "--args", "start", "--cwd", path, "--", "/bin/sh", "-c", command]
            try? fallback.run()
        }
    }

    private static func openRio(path: String, command: String) {
        guard let appURL = TerminalApp.rio.appURL else { return }
        let binary = appURL.appendingPathComponent("Contents/MacOS/rio")

        let process = Process()
        process.executableURL = binary
        process.arguments = ["--working-dir", path, "-e", "/bin/sh", "-c", command]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            fallback.arguments = ["-a", "Rio", "--args", "--working-dir", path, "-e", "/bin/sh", "-c", command]
            try? fallback.run()
        }
    }

    private static func shellEscape(_ str: String) -> String {
        "'" + str.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
