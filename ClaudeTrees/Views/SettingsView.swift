//
//  SettingsView.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var appSettings
    @Binding var isPresented: Bool
    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        @Bindable var settings = appSettings
        ZStack {
            Color.black.opacity(0.2)
                .onTapGesture { isPresented = false }

            VStack(spacing: 16) {
                Text("Settings")
                    .font(.headline)

                Form {
                    Toggle("Launch at Login", isOn: $settings.launchAtLogin)

                    Picker("Terminal:", selection: $settings.preferredTerminal) {
                        ForEach(TerminalApp.allCases) { terminal in
                            Text(terminal.rawValue).tag(terminal)
                        }
                    }

                    TextField("Claude CLI path:", text: $settings.claudeCLIPath)
                }

                HStack {
                    Spacer()
                    Button("Done") { isPresented = false }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
            .frame(width: 300)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 8)
        }
        .onAppear {
            autoDismissTask = Task {
                try? await Task.sleep(for: .seconds(15))
                if !Task.isCancelled {
                    isPresented = false
                }
            }
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }
}
