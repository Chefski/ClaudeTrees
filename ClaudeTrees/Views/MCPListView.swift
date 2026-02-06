//
//  MCPListView.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import SwiftUI

struct MCPListView: View {
    @Environment(SettingsService.self) private var settings

    var body: some View {
        Group {
            if let error = settings.errorMessage {
                ContentUnavailableView {
                    Label("Cannot Load Servers", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                }
            } else if settings.servers.isEmpty {
                ContentUnavailableView {
                    Label("No MCP Servers", systemImage: "server.rack")
                } description: {
                    Text("Add servers to ~/.claude/settings.json")
                }
            } else {
                List(settings.servers) { server in
                    MCPServerRow(server: server) { enabled in
                        settings.setEnabled(server.id, enabled)
                    }
                }
                .listStyle(.inset)
            }
        }
        .task(id: "load") {
            settings.load()
        }
    }
}
