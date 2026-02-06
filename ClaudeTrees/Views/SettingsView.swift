//
//  SettingsView.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = appSettings
        VStack(spacing: 16) {
            Text("Settings")
                .font(.headline)

            Form {
                Picker("Terminal:", selection: $settings.preferredTerminal) {
                    ForEach(TerminalApp.allCases) { terminal in
                        Text(terminal.rawValue).tag(terminal)
                    }
                }

                TextField("Claude CLI path:", text: $settings.claudeCLIPath)
            }

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
