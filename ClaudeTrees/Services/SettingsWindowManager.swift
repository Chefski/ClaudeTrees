//
//  SettingsWindowManager.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 20/02/2026.
//

import AppKit
import SwiftUI

@Observable
final class SettingsWindowManager {
    private let appSettings: AppSettings
    private weak var settingsWindow: NSWindow?

    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }

    func open() {
        if let existing = settingsWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        // Dismiss the popover
        NSApp.keyWindow?.close()

        let settingsView = SettingsView()
            .environment(appSettings)

        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)

        NSApp.activate()

        self.settingsWindow = window
    }
}
