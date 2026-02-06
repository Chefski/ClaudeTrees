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

    static func open(path: String, terminal: TerminalApp, claudeCLIPath _: String) {
        let resolvedPath = normalizePath(path)

        switch terminal {
        case .ghostty:
            openGhostty(path: resolvedPath)
        case .terminal:
            openTerminalApp(path: resolvedPath)
        case .iterm:
            openITerm(path: resolvedPath)
        case .warp:
            openWarp(path: resolvedPath)
        case .alacritty:
            openAlacritty(path: resolvedPath)
        case .kitty:
            openKitty(path: resolvedPath)
        case .wezterm:
            openWezTerm(path: resolvedPath)
        case .rio:
            openRio(path: resolvedPath)
        }
    }

    // MARK: - Terminal Implementations

    private static func openGhostty(path: String) {
        guard let appURL = TerminalApp.ghostty.appURL else { return }
        let binary = appURL.appendingPathComponent("Contents/MacOS/ghostty")

        let process = Process()
        process.executableURL = binary
        configureWorkingDirectory(process, path: path)
        process.arguments = ["--working-directory=\(path)"]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            configureWorkingDirectory(fallback, path: path)
            fallback.arguments = ["-na", "Ghostty", "--args", "--working-directory=\(path)"]
            try? fallback.run()
        }
    }

    private static func openTerminalApp(path: String) {
        openDirectory(path: path, terminal: .terminal)
    }

    private static func openITerm(path: String) {
        openDirectory(path: path, terminal: .iterm)
    }

    private static func openWarp(path: String) {
        openDirectory(path: path, terminal: .warp)
    }

    private static func openAlacritty(path: String) {
        guard let appURL = TerminalApp.alacritty.appURL else { return }
        let binary = appURL.appendingPathComponent("Contents/MacOS/alacritty")

        let process = Process()
        process.executableURL = binary
        configureWorkingDirectory(process, path: path)
        process.arguments = ["--working-directory", path]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            configureWorkingDirectory(fallback, path: path)
            fallback.arguments = ["-a", "Alacritty", "--args", "--working-directory", path]
            try? fallback.run()
        }
    }

    private static func openKitty(path: String) {
        guard let appURL = TerminalApp.kitty.appURL else { return }
        let binary = appURL.appendingPathComponent("Contents/MacOS/kitty")

        let process = Process()
        process.executableURL = binary
        configureWorkingDirectory(process, path: path)
        process.arguments = ["--directory", path]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            configureWorkingDirectory(fallback, path: path)
            fallback.arguments = ["-a", "kitty", "--args", "--directory", path]
            try? fallback.run()
        }
    }

    private static func openWezTerm(path: String) {
        guard let appURL = TerminalApp.wezterm.appURL else { return }
        let binary = appURL.appendingPathComponent("Contents/MacOS/wezterm-gui")

        let process = Process()
        process.executableURL = binary
        configureWorkingDirectory(process, path: path)
        process.arguments = ["start", "--cwd", path]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            configureWorkingDirectory(fallback, path: path)
            fallback.arguments = ["-a", "WezTerm", "--args", "start", "--cwd", path]
            try? fallback.run()
        }
    }

    private static func openRio(path: String) {
        guard let appURL = TerminalApp.rio.appURL else { return }
        let binary = appURL.appendingPathComponent("Contents/MacOS/rio")

        let process = Process()
        process.executableURL = binary
        configureWorkingDirectory(process, path: path)
        process.arguments = ["--working-dir", path]

        do {
            try process.run()
        } catch {
            let fallback = Process()
            fallback.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            configureWorkingDirectory(fallback, path: path)
            fallback.arguments = ["-a", "Rio", "--args", "--working-dir", path]
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

    private static func openDirectory(path: String, terminal: TerminalApp) {
        guard let appURL = terminal.appURL else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", appURL.path, path]
        configureWorkingDirectory(process, path: path)
        try? process.run()
    }
}
