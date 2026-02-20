//
//  SettingsView.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        @Bindable var settings = appSettings
        VStack(spacing: 16) {
            Text("Settings")
                .font(.headline)

            Form {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)

                Picker("Terminal:", selection: $settings.preferredTerminal) {
                    ForEach(TerminalApp.available) { terminal in
                        Text(terminal.rawValue).tag(terminal)
                    }
                }

                TextField("Claude CLI path:", text: $settings.claudeCLIPath)
            }

            HStack {
                Spacer()
                Button("Done") {
                    NSApp.keyWindow?.performClose(nil)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
