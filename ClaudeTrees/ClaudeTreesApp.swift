//
//  ClaudeTreesApp.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import SwiftUI

@main
struct ClaudeTreesApp: App {
    var body: some Scene {
        MenuBarExtra("ClaudeTrees", systemImage: "arrow.triangle.branch") {
            PopoverView()
        }
        .menuBarExtraStyle(.window)
    }
}
