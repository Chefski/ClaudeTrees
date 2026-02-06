//
//  AppSettings.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import Foundation
import ServiceManagement

@Observable
final class AppSettings {
    var preferredTerminal: TerminalApp {
        didSet { save() }
    }
    var claudeCLIPath: String {
        didSet { save() }
    }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let termRaw = defaults.string(forKey: "preferredTerminal") ?? TerminalApp.ghostty.rawValue
        self.preferredTerminal = TerminalApp(rawValue: termRaw) ?? .ghostty
        self.claudeCLIPath = defaults.string(forKey: "claudeCLIPath") ?? "~/.local/bin/claude"
    }

    private func save() {
        defaults.set(preferredTerminal.rawValue, forKey: "preferredTerminal")
        defaults.set(claudeCLIPath, forKey: "claudeCLIPath")
    }
}
