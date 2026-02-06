//
//  AppSettings.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import Foundation

@Observable
final class AppSettings {
    var preferredTerminal: TerminalApp {
        didSet { save() }
    }
    var claudeCLIPath: String {
        didSet { save() }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let available = TerminalApp.available
        let termRaw = defaults.string(forKey: "preferredTerminal") ?? ""
        if let saved = TerminalApp(rawValue: termRaw), available.contains(saved) {
            self.preferredTerminal = saved
        } else {
            self.preferredTerminal = available.first ?? .terminal
        }
        self.claudeCLIPath = defaults.string(forKey: "claudeCLIPath") ?? "~/.local/bin/claude"
    }

    private func save() {
        defaults.set(preferredTerminal.rawValue, forKey: "preferredTerminal")
        defaults.set(claudeCLIPath, forKey: "claudeCLIPath")
    }
}
