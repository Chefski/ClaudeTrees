//
//  ClaudeTreesApp.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import SwiftUI

@main
struct ClaudeTreesApp: App {
    @State private var settingsService = SettingsService()
    @State private var repoStore = RepoStore()
    @State private var gitService = GitService()
    @State private var appSettings = AppSettings()

    var body: some Scene {
        MenuBarExtra("ClaudeTrees", systemImage: "arrow.triangle.branch") {
            PopoverView()
                .environment(settingsService)
                .environment(repoStore)
                .environment(gitService)
                .environment(appSettings)
        }
        .menuBarExtraStyle(.window)
    }
}
