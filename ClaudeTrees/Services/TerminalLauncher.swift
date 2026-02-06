//
//  TerminalLauncher.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import AppKit
import os

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

    private static let logger = Logger(subsystem: "com.chefski.ClaudeTrees", category: "TerminalLauncher")

    static func open(path: String, terminal: TerminalApp, claudeCLIPath: String) {
        let resolvedPath = normalizePath(path)
        let expandedCLI = NSString(string: claudeCLIPath).expandingTildeInPath

        switch terminal {
        case .ghostty:
            openGhostty(path: resolvedPath, command: expandedCLI)
        case .terminal:
            openTerminalApp(path: resolvedPath, command: expandedCLI)
        case .iterm:
            openITerm(path: resolvedPath, command: expandedCLI)
        case .warp:
            openWarp(path: resolvedPath, command: expandedCLI)
        case .alacritty:
            openAlacritty(path: resolvedPath, command: expandedCLI)
        case .kitty:
            openKitty(path: resolvedPath, command: expandedCLI)
        case .wezterm:
            openWezTerm(path: resolvedPath, command: expandedCLI)
        case .rio:
            openRio(path: resolvedPath, command: expandedCLI)
        }
    }

    // MARK: - Terminal Implementations

    private static func openGhostty(path: String, command: String) {
        guard let appURL = TerminalApp.ghostty.appURL else { return }
        let binary = appURL.appendingPathComponent("Contents/MacOS/ghostty")

        let process = Process()
        process.executableURL = binary
        configureWorkingDirectory(process, path: path)
        process.arguments = ["--working-directory=\(path)", "-e", "/bin/sh", "-c", command]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            configureWorkingDirectory(fallback, path: path)
            fallback.arguments = ["-na", "Ghostty", "--args", "--working-directory=\(path)", "-e", "/bin/sh", "-c", command]
            try? fallback.run()
        }
    }

    private static func openTerminalApp(path: String, command: String) {
        let shellCmd = "cd \(shellEscape(path)) && \(shellCommand(command))"
        let escaped = shellCmd
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let src = """
        tell application "Terminal"
            activate
            do script "\(escaped)"
        end tell
        """
        if let script = NSAppleScript(source: src) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let error {
                logger.error("Terminal.app AppleScript error: \(error)")
                openDirectoryInApp(path: path, appName: "Terminal")
            }
        }
    }

    private static func openITerm(path: String, command: String) {
        let shellCmd = "cd \(shellEscape(path)) && \(shellCommand(command))"
        let escaped = shellCmd
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let src = """
        tell application "iTerm2"
            activate
            create window with default profile
            tell current session of current window
                write text "\(escaped)"
            end tell
        end tell
        """
        if let script = NSAppleScript(source: src) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let error {
                logger.error("iTerm2 AppleScript error: \(error)")
                openDirectoryInApp(path: path, appName: "iTerm")
            }
        }
    }

    private static func openWarp(path: String, command: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        configureWorkingDirectory(process, path: path)
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
        configureWorkingDirectory(process, path: path)
        process.arguments = ["--working-directory", path, "-e", "/bin/sh", "-c", command]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            configureWorkingDirectory(fallback, path: path)
            fallback.arguments = ["-a", "Alacritty", "--args", "--working-directory", path, "-e", "/bin/sh", "-c", command]
            try? fallback.run()
        }
    }

    private static func openKitty(path: String, command: String) {
        guard let appURL = TerminalApp.kitty.appURL else { return }
        let binary = appURL.appendingPathComponent("Contents/MacOS/kitty")

        let process = Process()
        process.executableURL = binary
        configureWorkingDirectory(process, path: path)
        process.arguments = ["--directory", path, "/bin/sh", "-c", command]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            configureWorkingDirectory(fallback, path: path)
            fallback.arguments = ["-a", "kitty", "--args", "--directory", path, "/bin/sh", "-c", command]
            try? fallback.run()
        }
    }

    private static func openWezTerm(path: String, command: String) {
        guard let appURL = TerminalApp.wezterm.appURL else { return }
        let binary = appURL.appendingPathComponent("Contents/MacOS/wezterm-gui")

        let process = Process()
        process.executableURL = binary
        configureWorkingDirectory(process, path: path)
        process.arguments = ["start", "--cwd", path, "--", "/bin/sh", "-c", command]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            configureWorkingDirectory(fallback, path: path)
            fallback.arguments = ["-a", "WezTerm", "--args", "start", "--cwd", path, "--", "/bin/sh", "-c", command]
            try? fallback.run()
        }
    }

    private static func openRio(path: String, command: String) {
        guard let appURL = TerminalApp.rio.appURL else { return }
        let binary = appURL.appendingPathComponent("Contents/MacOS/rio")

        let process = Process()
        process.executableURL = binary
        configureWorkingDirectory(process, path: path)
        process.arguments = ["--working-dir", path, "-e", "/bin/sh", "-c", command]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            configureWorkingDirectory(fallback, path: path)
            fallback.arguments = ["-a", "Rio", "--args", "--working-dir", path, "-e", "/bin/sh", "-c", command]
            try? fallback.run()
        }
    }

    private static func normalizePath(_ path: String) -> String {
        let expanded = NSString(string: path).expandingTildeInPath
        return URL(fileURLWithPath: expanded).standardizedFileURL.path(percentEncoded: false)
    }

    private static func configureWorkingDirectory(_ process: Process, path: String) {
        process.currentDirectoryURL = URL(fileURLWithPath: path)
    }

    private static func openDirectoryInApp(path: String, appName: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", appName, path]
        try? process.run()
    }

    private static func shellCommand(_ command: String) -> String {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        if FileManager.default.isExecutableFile(atPath: trimmed) {
            return shellEscape(trimmed)
        }
        return trimmed
    }

    private static func shellEscape(_ str: String) -> String {
        "'" + str.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
