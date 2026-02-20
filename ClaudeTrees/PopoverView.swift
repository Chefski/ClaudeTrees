//
//  PopoverView.swift
//  ClaudeTrees
//
//  Created by Patryk Radziszewski on 06/02/2026.
//

import SwiftUI

struct PopoverView: View {
    enum Tab: String, CaseIterable {
        case mcps = "MCPs"
        case worktrees = "Worktrees"
    }

    @Environment(SettingsWindowManager.self) private var settingsWindowManager
    @State private var selectedTab: Tab = .mcps
    @State private var showNewWorktreeSheet = false
    @State private var newWorktreeRepo: Repo?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Button {
                    settingsWindowManager.open()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 8)

            switch selectedTab {
            case .mcps:
                MCPListView()
            case .worktrees:
                WorktreeListView(
                    showNewWorktreeSheet: $showNewWorktreeSheet,
                    newWorktreeRepo: $newWorktreeRepo
                )
            }
        }
        .frame(width: 360, height: 440)
        .overlay {
            if showNewWorktreeSheet, let repo = newWorktreeRepo {
                NewWorktreeSheet(repo: repo, isPresented: $showNewWorktreeSheet)
            }
        }
    }
}
